#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Manette DualShock 4 virtuelle pour NFSU2 Revived (Foclabroc Toolbox).

Chaque manette configurée dans Batocera (mapping SDL de SDL_GAMECONTROLLERCONFIG)
est capturée en exclusif et rejouée sous forme de DS4 (054c:09cc), reconnue par
Chromium avec son mapping standard. Le script gère aussi :
  - Hotkey + Start : quitter (commande passée avec --quit)
  - stick droit : souris, R3 : clic gauche
Les manettes réelles sont masquées à Chromium (udev) pendant le jeu.
"""
import argparse
import os
import select
import signal
import struct
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

import evdev
from evdev import AbsInfo, InputDevice, UInput
from evdev import ecodes as e

ES_INPUT = "/userdata/system/configs/emulationstation/es_input.cfg"
UDEV_RULE = "/run/udev/rules.d/99-nfsu2-hide.rules"
DS4_NAME = "Sony Interactive Entertainment Wireless Controller"


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


# --------------------------------------------------------------- DS4 virtuelle
DS4_BUTTONS = {
    "a": e.BTN_SOUTH, "b": e.BTN_EAST, "x": e.BTN_WEST, "y": e.BTN_NORTH,
    "leftshoulder": e.BTN_TL, "rightshoulder": e.BTN_TR,
    "back": e.BTN_SELECT, "start": e.BTN_START, "guide": e.BTN_MODE,
    "leftstick": e.BTN_THUMBL, "rightstick": e.BTN_THUMBR,
}
DS4_STICKS = {"leftx": e.ABS_X, "lefty": e.ABS_Y, "rightx": e.ABS_RX, "righty": e.ABS_RY}
DS4_TRIGGERS = {"lefttrigger": (e.ABS_Z, e.BTN_TL2), "righttrigger": (e.ABS_RZ, e.BTN_TR2)}
DPAD = ("dpup", "dpdown", "dpleft", "dpright")


def make_ds4():
    stick = AbsInfo(value=128, min=0, max=255, fuzz=0, flat=0, resolution=0)
    trig = AbsInfo(value=0, min=0, max=255, fuzz=0, flat=0, resolution=0)
    hat = AbsInfo(value=0, min=-1, max=1, fuzz=0, flat=0, resolution=0)
    caps = {
        e.EV_KEY: [e.BTN_SOUTH, e.BTN_EAST, e.BTN_NORTH, e.BTN_WEST, e.BTN_TL, e.BTN_TR,
                   e.BTN_TL2, e.BTN_TR2, e.BTN_SELECT, e.BTN_START, e.BTN_MODE,
                   e.BTN_THUMBL, e.BTN_THUMBR],
        e.EV_ABS: [(e.ABS_X, stick), (e.ABS_Y, stick), (e.ABS_Z, trig),
                   (e.ABS_RX, stick), (e.ABS_RY, stick), (e.ABS_RZ, trig),
                   (e.ABS_HAT0X, hat), (e.ABS_HAT0Y, hat)],
    }
    return UInput(caps, name=DS4_NAME, vendor=0x054C, product=0x09CC, version=0x8111, bustype=e.BUS_USB)


def make_mouse():
    caps = {e.EV_KEY: [e.BTN_LEFT, e.BTN_RIGHT], e.EV_REL: [e.REL_X, e.REL_Y]}
    return UInput(caps, name="NFSU2 virtual mouse", vendor=0x1234, product=0x5678, version=1)


# --------------------------------------------------------------- une manette
class Pad:
    def __init__(self, dev, mapping, hotkey_idx, start_idx, mouse):
        self.dev = dev
        self.map = mapping
        self.buttons, self.axes, self.hats, self.absinfo = sdl_layout(dev)
        self.state_keys = set()
        self.state_abs = {c: ai.value for c, ai in self.absinfo.items()}
        self.ds4 = make_ds4()
        self.mouse = mouse
        self.hotkey_code = self._button_code(hotkey_idx)
        self.start_code = self._button_code(start_idx)
        self.last = {}
        self.quit_armed = True

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

    # --- émission
    def _emit(self, etype, code, value):
        if self.last.get((etype, code)) != value:
            self.last[(etype, code)] = value
            self.ds4.write(etype, code, value)
            return True
        return False

    def sync(self):
        changed = False
        for name, code in DS4_BUTTONS.items():
            changed |= self._emit(e.EV_KEY, code, 1 if self.target(name) > 0.5 else 0)
        for name, code in DS4_STICKS.items():
            v = max(-1.0, min(1.0, self.target(name)))
            changed |= self._emit(e.EV_ABS, code, int(round((v + 1.0) * 127.5)))
        for name, (acode, bcode) in DS4_TRIGGERS.items():
            v = self.trigger(name)
            changed |= self._emit(e.EV_ABS, acode, int(round(v * 255)))
            changed |= self._emit(e.EV_KEY, bcode, 1 if v > 0.1 else 0)
        up, down, left, right = (self.target(d) > 0.5 for d in DPAD)
        changed |= self._emit(e.EV_ABS, e.ABS_HAT0X, int(right) - int(left))
        changed |= self._emit(e.EV_ABS, e.ABS_HAT0Y, int(down) - int(up))
        if changed:
            self.ds4.syn()

    def handle(self, ev):
        if ev.type == e.EV_KEY:
            if ev.value:
                self.state_keys.add(ev.code)
            else:
                self.state_keys.discard(ev.code)
            if ev.code == self.rightstick_code() and self.mouse:
                self.mouse.write(e.EV_KEY, e.BTN_LEFT, 1 if ev.value else 0)
                self.mouse.syn()
        elif ev.type == e.EV_ABS:
            self.state_abs[ev.code] = ev.value
        elif ev.type == e.EV_SYN:
            self.sync()

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
        try:
            self.ds4.close()
        except Exception:
            pass


# --------------------------------------------------------------- ES / udev
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


def input_parent(dev_path):
    ev = os.path.basename(dev_path)
    return os.path.basename(os.path.realpath(f"/sys/class/input/{ev}/device"))


def udev_retrigger(parents):
    for p in parents:
        base = f"/sys/class/input/{p}"
        for child in os.listdir(base) if os.path.isdir(base) else []:
            uevent = os.path.join(base, child, "uevent")
            if child.startswith(("event", "js")) and os.path.exists(uevent):
                try:
                    with open(uevent, "w") as f:
                        f.write("change")
                except OSError:
                    pass


def udev_hide(parents):
    """Retire ID_INPUT_JOYSTICK des vraies manettes pour que Chromium ne les liste pas."""
    if not parents:
        return
    os.makedirs(os.path.dirname(UDEV_RULE), exist_ok=True)
    with open(UDEV_RULE, "w") as f:
        for p in parents:
            f.write(f'SUBSYSTEM=="input", KERNELS=="{p}", ENV{{ID_INPUT_JOYSTICK}}=""\n')
    subprocess.run(["udevadm", "control", "--reload"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
    udev_retrigger(parents)
    subprocess.run(["udevadm", "settle", "--timeout=3"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)


def udev_restore(parents):
    if os.path.exists(UDEV_RULE):
        os.remove(UDEV_RULE)
        subprocess.run(["udevadm", "control", "--reload"], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        udev_retrigger(parents)


# --------------------------------------------------------------- boucle
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--quit", default="", help="commande lancée sur Hotkey + Start")
    ap.add_argument("--no-mouse", action="store_true")
    ap.add_argument("--mouse-speed", type=float, default=14.0)
    args = ap.parse_args()

    configs = parse_sdl_configs(os.environ.get("SDL_GAMECONTROLLERCONFIG", ""))
    if not configs:
        log("Pas de SDL_GAMECONTROLLERCONFIG : rien à émuler.")
        return 1

    mouse = None if args.no_mouse else make_mouse()
    pads = {}
    parents = []
    for path in evdev.list_devices():
        try:
            dev = InputDevice(path)
        except OSError:
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
        pad = Pad(dev, mapping, hk, st, mouse)
        pads[dev.fd] = pad
        parents.append(input_parent(path))
        log(f"{dev.name} ({path}, GUID {guid}) -> DS4 virtuelle {pad.ds4.device.path}"
            f" | hotkey={hk} start={st} | {len(pad.buttons)} boutons, {len(pad.axes)} axes, {len(pad.hats)} hats")

    if not pads:
        log("Aucune manette correspondant au mapping Batocera trouvée.")
        if mouse:
            mouse.close()
        return 1

    udev_hide(parents)

    running = [True]

    def stop(*_):
        running[0] = False
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    for pad in pads.values():
        pad.sync()

    rx_acc = ry_acc = 0.0
    last_t = time.monotonic()
    parent = os.getppid()
    try:
        while running[0]:
            r, _, _ = select.select(list(pads.keys()), [], [], 0.01)
            for fd in r:
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

            # Souris : stick droit de toutes les manettes (vitesse en px par 10 ms)
            now = time.monotonic()
            dt = min(0.05, now - last_t) / 0.01
            last_t = now
            if mouse:
                dx = dy = 0.0
                for pad in pads.values():
                    x, y = pad.target("rightx"), pad.target("righty")
                    for v, axis in ((x, "x"), (y, "y")):
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
        if mouse:
            mouse.close()
        udev_restore(parents)
        log("Arrêt de l'émulation DS4.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
