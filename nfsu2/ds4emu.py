#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Pont manette pour NFSU2 Revived (Foclabroc Toolbox).

Chromium ignore les manettes virtuelles (uinput) créées pendant le jeu. Ce script
lit donc lui-même chaque manette configurée dans Batocera (mapping SDL de
SDL_GAMECONTROLLERCONFIG), la traduit en manette "standard" (17 boutons dont
gâchettes analogiques, 4 axes) et envoie son état à l'extension du navigateur par
WebSocket local (127.0.0.1). L'extension présente ces manettes au site.

Il gère aussi :
  - Hotkey + Start : quitter (commande passée avec --quit)
  - stick droit : souris, R3 : clic gauche
  - Select seul (appui court) : touche F9
  - Steam Deck : pad droit = souris (clic du pad = clic gauche), pad gauche = molette
  - DS4 / DualSense : pavé tactile = souris (2 doigts = molette, clic = clic gauche)
Les vraies manettes sont capturées en exclusif pendant le jeu (Chromium et evmapy
ne les voient plus), puis relâchées à la sortie.
"""
import argparse
import base64
import hashlib
import json
import os
import select
import signal
import socket
import struct
import subprocess
import sys
import threading
import time
import xml.etree.ElementTree as ET

import evdev
from evdev import InputDevice, UInput
from evdev import ecodes as e

ES_INPUT = "/userdata/system/configs/emulationstation/es_input.cfg"
UDEV_RULE = "/run/udev/rules.d/99-nfsu2-hide.rules"   # anciennes versions : nettoyage
WS_PORT = 47820
WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


def log(*a):
    print(time.strftime("%H:%M:%S"), *a, flush=True)


# --------------------------------------------------------------- mapping SDL
def parse_sdl_configs(text):
    """GUID -> {cible: source} depuis SDL_GAMECONTROLLERCONFIG (une ligne par manette)."""
    out = {}
    for line in (text or "").splitlines():
        parts = [p for p in line.strip().split(",") if p]
        if len(parts) < 3:
            continue
        guid, mapping = parts[0].lower(), {}
        for tok in parts[2:]:
            if ":" in tok:
                k, v = tok.split(":", 1)
                if k != "platform":
                    mapping[k] = v
        out[guid] = mapping
    return out


def sdl_guid(info):
    return struct.pack("<8H", info.bustype, 0, info.vendor, 0, info.product, 0, info.version, 0).hex()


def find_mapping(dev, configs):
    """Correspondance exacte, puis sans CRC (octets 2-3), puis sans version."""
    g = sdl_guid(dev.info)
    cands = [
        lambda c: c == g,
        lambda c: c[:4] + c[8:] == g[:4] + g[8:],
        lambda c: c[:4] + c[8:24] == g[:4] + g[8:24],
    ]
    for test in cands:
        for guid, m in configs.items():
            if len(guid) == 32 and test(guid):
                return guid, m
    return None, None


def is_digital_hat(ai):
    return ai is not None and ai.min >= -1 and ai.max <= 1


def sdl_layout(dev):
    """Reproduit la numérotation SDL (Linux) : boutons, axes, hats."""
    caps = dev.capabilities(absinfo=True)
    keys = set(caps.get(e.EV_KEY, []))
    absinfo = {code: ai for code, ai in caps.get(e.EV_ABS, [])}

    buttons = [c for c in range(e.BTN_JOYSTICK, e.KEY_MAX) if c in keys]
    buttons += [c for c in range(0, e.BTN_JOYSTICK) if c in keys]

    hats, axes = [], []
    hat_codes = set()
    for code in range(e.ABS_HAT0X, e.ABS_HAT3Y + 1, 2):
        x, y = absinfo.get(code), absinfo.get(code + 1)
        if (x or y) and (x is None or is_digital_hat(x)) and (y is None or is_digital_hat(y)):
            hats.append(code)
            hat_codes.update((code, code + 1))
    for code in range(0, e.ABS_MAX):
        if code in absinfo and code not in hat_codes:
            axes.append(code)
    return buttons, axes, hats, absinfo


def is_gamepad(dev):
    """Vrai gamepad : sticks (ABS_X/ABS_Y) + boutons de manette.
    Écarte le clavier et la souris virtuels des trackpads (hid-steam) et les capteurs."""
    caps = dev.capabilities(absinfo=False)
    absc = set(caps.get(e.EV_ABS, []))
    keys = set(caps.get(e.EV_KEY, []))
    if e.ABS_X not in absc or e.ABS_Y not in absc:
        return False
    if e.INPUT_PROP_ACCELEROMETER in dev.input_props():
        return False
    pad_buttons = set(range(e.BTN_JOYSTICK, e.BTN_THUMBR + 1)) | set(range(e.BTN_DPAD_UP, e.BTN_DPAD_RIGHT + 1))
    return bool(keys & pad_buttons)


# Ordre de la "Standard Gamepad" du W3C (navigator.getGamepads, mapping="standard")
STANDARD_BUTTONS = [
    "a", "b", "x", "y", "leftshoulder", "rightshoulder", "lefttrigger", "righttrigger",
    "back", "start", "leftstick", "rightstick", "dpup", "dpdown", "dpleft", "dpright", "guide",
]
STANDARD_AXES = ["leftx", "lefty", "rightx", "righty"]


def make_keyboard():
    return UInput({e.EV_KEY: [e.KEY_F9]}, name="NFSU2 virtual keyboard", vendor=0x1234, product=0x5679, version=1)


def make_mouse():
    caps = {e.EV_KEY: [e.BTN_LEFT, e.BTN_RIGHT], e.EV_REL: [e.REL_X, e.REL_Y, e.REL_WHEEL]}
    return UInput(caps, name="NFSU2 virtual mouse", vendor=0x1234, product=0x5678, version=1)


# --------------------------------------------------------------- trackpads
class TrackpadMotion:
    """Position absolue d'un pavé tactile -> déplacement relatif (comme un touchpad)."""

    def __init__(self, scale):
        self.scale = scale
        self.last = None
        self.acc = [0.0, 0.0]

    def update(self, x, y, touching):
        if not touching:
            self.last = None
            return 0, 0
        if self.last is None:
            self.last = (x, y)
            return 0, 0
        self.acc[0] += (x - self.last[0]) * self.scale
        self.acc[1] += (y - self.last[1]) * self.scale
        self.last = (x, y)
        ix, iy = int(self.acc[0]), int(self.acc[1])
        self.acc[0] -= ix
        self.acc[1] -= iy
        return ix, iy


def mouse_move(mouse, dx, dy, wheel=0):
    if not mouse or not (dx or dy or wheel):
        return
    if dx:
        mouse.write(e.EV_REL, e.REL_X, dx)
    if dy:
        mouse.write(e.EV_REL, e.REL_Y, dy)
    if wheel:
        mouse.write(e.EV_REL, e.REL_WHEEL, wheel)
    mouse.syn()


def mouse_button(mouse, code, pressed):
    if mouse:
        mouse.write(e.EV_KEY, code, 1 if pressed else 0)
        mouse.syn()


# Steam Deck (hid-steam) : pads sur ABS_HAT0 (gauche) / ABS_HAT1 (droit), 0 quand
# le pad n'est pas touché ; clic pad gauche = BTN_THUMB, clic pad droit = BTN_THUMB2.
DECK_PAD_SCALE = 0.02      # unités pad (-32767..32767) -> pixels
DECK_SCROLL_STEP = 2500    # unités pad par cran de molette
DECK_INVERT_Y = False      # mettre True si le haut/bas du pad est inversé


class SonyTouchpad:
    """Pavé tactile DS4 / DualSense (périphérique "... Touchpad" de hid-playstation).
    1 doigt = souris, 2 doigts = molette, clic du pavé = clic gauche."""

    def __init__(self, dev, mouse):
        self.dev = dev
        self.mouse = mouse
        self.x = self.y = 0
        self.touch = False
        self.fingers = 1
        self.motion = TrackpadMotion(1.0)
        self.scroll_acc = 0.0
        self.last_y = None

    def handle(self, ev):
        if ev.type == e.EV_ABS:
            if ev.code == e.ABS_X:
                self.x = ev.value
            elif ev.code == e.ABS_Y:
                self.y = ev.value
        elif ev.type == e.EV_KEY:
            if ev.code == e.BTN_TOUCH:
                self.touch = bool(ev.value)
            elif ev.code == e.BTN_TOOL_DOUBLETAP:
                self.fingers = 2 if ev.value else 1
            elif ev.code == e.BTN_LEFT:
                mouse_button(self.mouse, e.BTN_LEFT, ev.value)
        elif ev.type == e.EV_SYN:
            if self.touch and self.fingers == 2:
                self.motion.update(0, 0, False)
                if self.last_y is not None:
                    self.scroll_acc += (self.last_y - self.y) / 40.0
                    notch = int(self.scroll_acc)
                    self.scroll_acc -= notch
                    mouse_move(self.mouse, 0, 0, notch)
                self.last_y = self.y
            else:
                self.last_y = None
                dx, dy = self.motion.update(self.x, self.y, self.touch)
                mouse_move(self.mouse, dx, dy)

    def close(self):
        try:
            self.dev.ungrab()
        except Exception:
            pass


def is_sony_touchpad(dev):
    caps = dev.capabilities(absinfo=False)
    return (dev.info.vendor == 0x054C and "Touchpad" in dev.name
            and e.ABS_X in caps.get(e.EV_ABS, []) and e.BTN_TOUCH in caps.get(e.EV_KEY, []))


# --------------------------------------------------------------- une manette
class Pad:
    def __init__(self, dev, mapping, hotkey_idx, start_idx, mouse, keyboard=None):
        self.dev = dev
        self.map = mapping
        self.buttons, self.axes, self.hats, self.absinfo = sdl_layout(dev)
        self.state_keys = set()
        self.state_abs = {c: ai.value for c, ai in self.absinfo.items()}
        self.mouse = mouse
        self.hotkey_code = self._button_code(hotkey_idx)
        self.start_code = self._button_code(start_idx)
        self.quit_armed = True
        self.keyboard = keyboard
        self.select_code = self._map_button("back")
        self.select_tap = False
        # Trackpads du Steam Deck
        self.deck = dev.info.vendor == 0x28DE and e.ABS_HAT1X in self.absinfo
        self.rpad = TrackpadMotion(DECK_PAD_SCALE)
        self.lpad_last = None
        self.lpad_acc = 0.0

    def _map_button(self, name):
        src = self.map.get(name, "")
        if src.startswith("b") and src[1:].isdigit() and int(src[1:]) < len(self.buttons):
            return self.buttons[int(src[1:])]
        return None

    def _button_code(self, idx):
        if idx is None or not (0 <= idx < len(self.buttons)):
            return None
        return self.buttons[idx]

    # --- lecture d'une source SDL ("b3", "h0.4", "a2", "+a2", "-a2", "a2~")
    def _norm(self, code):
        ai = self.absinfo.get(code)
        if not ai or ai.max == ai.min:
            return 0.0
        v = (self.state_abs.get(code, ai.value) - ai.min) / (ai.max - ai.min)
        return v * 2.0 - 1.0

    def source(self, src):
        if not src:
            return 0.0
        if src[0] == "b":
            i = int(src[1:])
            return 1.0 if i < len(self.buttons) and self.buttons[i] in self.state_keys else 0.0
        if src[0] == "h":
            h, bit = src[1:].split(".")
            h, bit = int(h), int(bit)
            if h >= len(self.hats):
                return 0.0
            x = self.state_abs.get(self.hats[h], 0)
            y = self.state_abs.get(self.hats[h] + 1, 0)
            mask = (1 if y < 0 else 0) | (2 if x > 0 else 0) | (4 if y > 0 else 0) | (8 if x < 0 else 0)
            return 1.0 if mask & bit else 0.0
        half = None
        if src[0] in "+-":
            half, src = src[0], src[1:]
        invert = src.endswith("~")
        src = src.rstrip("~")
        if src[0] != "a":
            return 0.0
        i = int(src[1:])
        if i >= len(self.axes):
            return 0.0
        v = self._norm(self.axes[i])
        if invert:
            v = -v
        if half == "+":
            return max(0.0, v)
        if half == "-":
            return max(0.0, -v)
        return v

    def target(self, name):
        src = self.map.get(name)
        if src is None:
            src = self.map.get("+" + name) or self.map.get("-" + name)
        return self.source(src)

    def trigger(self, name):
        src = self.map.get(name, "")
        v = self.source(src)
        # Gâchette analogique en axe complet (-1..1) : on la ramène à 0..1
        if src.startswith("a") or src.endswith("~"):
            v = (v + 1.0) / 2.0
        return max(0.0, min(1.0, v))

    def standard_state(self):
        """Boutons (0..1) et axes (-1..1) dans l'ordre de la Standard Gamepad."""
        buttons = []
        for name in STANDARD_BUTTONS:
            if name in ("lefttrigger", "righttrigger"):
                v = self.trigger(name)
            else:
                v = 1.0 if self.target(name) > 0.5 else 0.0
            buttons.append(round(v, 3))
        axes = [round(max(-1.0, min(1.0, self.target(n))), 3) for n in STANDARD_AXES]
        return buttons, axes

    def handle(self, ev):
        if ev.type == e.EV_KEY:
            if ev.value:
                self.state_keys.add(ev.code)
            else:
                self.state_keys.discard(ev.code)
            # Select seul (appui court) = F9. Si un autre bouton est pressé pendant
            # que Select est maintenu (ex. Hotkey + Start), pas de F9.
            if self.keyboard and self.select_code:
                if ev.code == self.select_code and ev.value == 1:
                    self.select_tap = True
                elif ev.code != self.select_code and ev.value == 1:
                    self.select_tap = False
                elif ev.code == self.select_code and ev.value == 0 and self.select_tap:
                    self.select_tap = False
                    self.keyboard.write(e.EV_KEY, e.KEY_F9, 1)
                    self.keyboard.syn()
                    self.keyboard.write(e.EV_KEY, e.KEY_F9, 0)
                    self.keyboard.syn()
            if ev.code == self.rightstick_code() and self.mouse:
                mouse_button(self.mouse, e.BTN_LEFT, ev.value)
            if self.deck and ev.code == e.BTN_THUMB2 and ev.value != 2:
                mouse_button(self.mouse, e.BTN_LEFT, ev.value)
        elif ev.type == e.EV_ABS:
            self.state_abs[ev.code] = ev.value
        elif ev.type == e.EV_SYN and self.deck and self.mouse:
            self._deck_trackpads()

    def _deck_trackpads(self):
        sign = -1 if DECK_INVERT_Y else 1
        # Pad droit : souris
        x, y = self.state_abs.get(e.ABS_HAT1X, 0), self.state_abs.get(e.ABS_HAT1Y, 0)
        dx, dy = self.rpad.update(x, sign * y, (x, y) != (0, 0))
        mouse_move(self.mouse, dx, dy)
        # Pad gauche : molette (glisser vers le haut = défiler vers le haut)
        lx, ly = self.state_abs.get(e.ABS_HAT0X, 0), sign * self.state_abs.get(e.ABS_HAT0Y, 0)
        if (lx, ly) == (0, 0):
            self.lpad_last = None
            self.lpad_acc = 0.0
            return
        if self.lpad_last is not None:
            self.lpad_acc += (self.lpad_last - ly) / DECK_SCROLL_STEP
            notch = int(self.lpad_acc)
            self.lpad_acc -= notch
            mouse_move(self.mouse, 0, 0, notch)
        self.lpad_last = ly

    def rightstick_code(self):
        src = self.map.get("rightstick", "")
        if src.startswith("b") and int(src[1:]) < len(self.buttons):
            return self.buttons[int(src[1:])]
        return None

    def hotkey_start(self):
        hk = self.hotkey_code in self.state_keys if self.hotkey_code else (
            self.target("back") > 0.5 or self.target("guide") > 0.5)
        st = self.start_code in self.state_keys if self.start_code else self.target("start") > 0.5
        pressed = hk and st
        fire = pressed and self.quit_armed
        self.quit_armed = not pressed
        return fire

    def close(self):
        try:
            self.dev.ungrab()
        except Exception:
            pass


# --------------------------------------------------------------- WebSocket local
class Bridge:
    """Mini serveur WebSocket (envoi seul) sur 127.0.0.1 pour l'extension."""

    def __init__(self, port):
        self.clients = []
        self.lock = threading.Lock()
        self.srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.srv.bind(("127.0.0.1", port))
        self.srv.listen(4)
        self.last_msg = None
        threading.Thread(target=self._accept, daemon=True).start()

    def _accept(self):
        while True:
            try:
                conn, _ = self.srv.accept()
            except OSError:
                return
            threading.Thread(target=self._handshake, args=(conn,), daemon=True).start()

    def _handshake(self, conn):
        try:
            conn.settimeout(3)
            data = b""
            while b"\r\n\r\n" not in data and len(data) < 8192:
                chunk = conn.recv(1024)
                if not chunk:
                    raise OSError("fermé")
                data += chunk
            key = None
            for line in data.decode("latin-1").split("\r\n"):
                if line.lower().startswith("sec-websocket-key:"):
                    key = line.split(":", 1)[1].strip()
            if not key:
                raise OSError("pas de clé WebSocket")
            accept = base64.b64encode(hashlib.sha1((key + WS_GUID).encode()).digest()).decode()
            conn.sendall(("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\n"
                          "Connection: Upgrade\r\nSec-WebSocket-Accept: " + accept + "\r\n\r\n").encode())
            conn.settimeout(None)
            conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            with self.lock:
                self.clients.append(conn)
                last = self.last_msg
            log("Extension connectée au pont manette.")
            if last:
                self._send(conn, last)
        except OSError:
            conn.close()

    @staticmethod
    def _frame(payload):
        n = len(payload)
        if n < 126:
            head = struct.pack("!BB", 0x81, n)
        elif n < 65536:
            head = struct.pack("!BBH", 0x81, 126, n)
        else:
            head = struct.pack("!BBQ", 0x81, 127, n)
        return head + payload

    def _send(self, conn, payload):
        try:
            conn.sendall(self._frame(payload))
            return True
        except OSError:
            return False

    def broadcast(self, obj):
        payload = json.dumps(obj, separators=(",", ":")).encode()
        with self.lock:
            self.last_msg = payload
            alive = []
            for c in self.clients:
                if self._send(c, payload):
                    alive.append(c)
                else:
                    c.close()
            self.clients = alive

    def close(self):
        try:
            self.srv.close()
        except OSError:
            pass
        with self.lock:
            for c in self.clients:
                c.close()
            self.clients = []


# --------------------------------------------------------------- ES / udev
def es_buttons(guid, name):
    """Index SDL des boutons hotkey et start déclarés dans es_input.cfg."""
    try:
        root = ET.parse(ES_INPUT).getroot()
    except Exception:
        return None, None
    best = None
    for cfg in root.iter("inputConfig"):
        if cfg.get("type") != "joystick":
            continue
        if (cfg.get("deviceGUID") or "").lower() == guid:
            best = cfg
            break
        if best is None and cfg.get("deviceName") == name:
            best = cfg
    if best is None:
        return None, None
    found = {}
    for inp in best.iter("input"):
        if inp.get("type") == "button" and inp.get("name") in ("hotkey", "start"):
            found[inp.get("name")] = int(inp.get("id"))
    return found.get("hotkey"), found.get("start")


def cleanup_stale_rule():
    """Règle de masquage laissée par une ancienne version : on la retire."""
    if not os.path.exists(UDEV_RULE):
        return
    log("Ancienne règle udev trouvée : nettoyage.")
    os.remove(UDEV_RULE)
    subprocess.run(["udevadm", "control", "--reload"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
    for d in os.listdir("/sys/class/input"):
        uevent = os.path.join("/sys/class/input", d, "uevent")
        if d.startswith(("event", "js")) and os.path.exists(uevent):
            try:
                with open(uevent, "w") as f:
                    f.write("change")
            except OSError:
                pass


# --------------------------------------------------------------- boucle
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--quit", default="", help="commande lancée sur Hotkey + Start")
    ap.add_argument("--no-mouse", action="store_true")
    ap.add_argument("--mouse-speed", type=float, default=14.0)
    ap.add_argument("--identity", choices=["ds4", "xbox"], default="ds4",
                    help="manette annoncée au site")
    ap.add_argument("--port", type=int, default=WS_PORT)
    args = ap.parse_args()

    cleanup_stale_rule()
    configs = parse_sdl_configs(os.environ.get("SDL_GAMECONTROLLERCONFIG", ""))
    if not configs:
        log("Pas de SDL_GAMECONTROLLERCONFIG : rien à faire.")
        return 1

    mouse = None if args.no_mouse else make_mouse()
    keyboard = make_keyboard()
    pads = {}
    touchpads = {}
    for path in evdev.list_devices():
        try:
            dev = InputDevice(path)
        except OSError:
            continue
        if mouse and is_sony_touchpad(dev):
            try:
                dev.grab()
                touchpads[dev.fd] = SonyTouchpad(dev, mouse)
                log(f"Pavé tactile {dev.name} ({path}) -> souris")
            except OSError as err:
                log(f"Capture impossible pour {dev.name} ({path}) : {err}")
                dev.close()
            continue
        guid, mapping = find_mapping(dev, configs)
        if not mapping or not is_gamepad(dev):
            dev.close()
            continue
        hk, st = es_buttons(guid, dev.name)
        try:
            dev.grab()
        except OSError as err:
            log(f"Capture impossible pour {dev.name} ({path}) : {err}")
            dev.close()
            continue
        pad = Pad(dev, mapping, hk, st, mouse, keyboard)
        pads[dev.fd] = pad
        log(f"{dev.name} ({path}, GUID {guid}) | hotkey={hk} start={st}"
            f" | {len(pad.buttons)} boutons, {len(pad.axes)} axes, {len(pad.hats)} hats")

    if not pads:
        log("Aucune manette correspondant au mapping Batocera trouvée.")
        if mouse:
            mouse.close()
        return 1

    try:
        bridge = Bridge(args.port)
    except OSError as err:
        log(f"Port {args.port} indisponible : {err}")
        for pad in pads.values():
            pad.close()
        return 1
    log(f"Pont manette sur ws://127.0.0.1:{args.port} (identité {args.identity})")

    running = [True]

    def stop(*_):
        running[0] = False
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    rx_acc = ry_acc = 0.0
    last_t = time.monotonic()
    last_sent = 0.0
    last_payload = None
    parent = os.getppid()
    try:
        while running[0]:
            r, _, _ = select.select(list(pads.keys()) + list(touchpads.keys()), [], [], 0.008)
            for fd in r:
                if fd in touchpads:
                    tp = touchpads[fd]
                    try:
                        for ev in tp.dev.read():
                            tp.handle(ev)
                    except OSError:
                        tp.close()
                        del touchpads[fd]
                    continue
                pad = pads[fd]
                try:
                    for ev in pad.dev.read():
                        pad.handle(ev)
                except OSError:
                    log(f"Manette déconnectée : {pad.dev.name}")
                    pad.close()
                    del pads[fd]
                    continue
                if args.quit and pad.hotkey_start():
                    log("Hotkey + Start : sortie")
                    subprocess.Popen(args.quit, shell=True)
            if not pads:
                break
            # Sécurité : si le lanceur meurt, on relâche les manettes
            if os.getppid() != parent:
                log("Lanceur arrêté : relâche des manettes.")
                break

            # État des manettes vers l'extension (à chaque changement, sinon 5 fois/s)
            now = time.monotonic()
            state = [pad.standard_state() for pad in pads.values()]
            if state != last_payload or now - last_sent > 0.2:
                bridge.broadcast({
                    "identity": args.identity,
                    "pads": [{"buttons": b, "axes": a} for b, a in state],
                })
                last_payload = state
                last_sent = now

            # Souris : stick droit de toutes les manettes (vitesse en px par 10 ms)
            dt = min(0.05, now - last_t) / 0.01
            last_t = now
            if mouse:
                dx = dy = 0.0
                for pad in pads.values():
                    for v, axis in ((pad.target("rightx"), "x"), (pad.target("righty"), "y")):
                        if abs(v) > 0.2:
                            s = (abs(v) - 0.2) / 0.8
                            step = (s ** 2) * args.mouse_speed * dt * (1 if v > 0 else -1)
                            if axis == "x":
                                dx += step
                            else:
                                dy += step
                rx_acc += dx
                ry_acc += dy
                mx, my = int(rx_acc), int(ry_acc)
                if mx or my:
                    rx_acc -= mx
                    ry_acc -= my
                    if mx:
                        mouse.write(e.EV_REL, e.REL_X, mx)
                    if my:
                        mouse.write(e.EV_REL, e.REL_Y, my)
                    mouse.syn()
    finally:
        for pad in list(pads.values()):
            pad.close()
        for tp in list(touchpads.values()):
            tp.close()
        if mouse:
            mouse.close()
        keyboard.close()
        bridge.close()
        log("Arrêt du pont manette.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
