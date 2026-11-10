// Monde de la page (Foclabroc Toolbox, NFSU2 Revived)
//  1. Pont manette : quand ds4emu.py envoie l'état des manettes (via osk.js), le site
//     voit des manettes "standard" complètes (gâchettes analogiques comprises), quelle
//     que soit la vraie manette. Sinon, ce sont les manettes de Chromium.
//  2. Clavier virtuel ouvert : le site voit les manettes au repos.
(() => {
  if (!navigator.getGamepads) return;
  const original = navigator.getGamepads.bind(navigator);
  const MAX_PADS = 4;
  const FRESH_MS = 1500;
  const IDS = {
    ds4: 'Wireless Controller (STANDARD GAMEPAD Vendor: 054c Product: 09cc)',
    xbox: 'Xbox 360 Controller (XInput STANDARD GAMEPAD Vendor: 045e Product: 028e)',
  };
  const PRESSED = 0.12;
  const proto = window.Gamepad ? window.Gamepad.prototype : Object.prototype;
  const actuator = Object.freeze({
    type: 'dual-rumble',
    effects: ['dual-rumble'],
    playEffect: () => Promise.resolve('complete'),
    reset: () => Promise.resolve('complete'),
  });

  const ro = (value) => ({ value, enumerable: true });
  const makePad = (p, index, identity, ts) => {
    const gp = Object.create(proto);
    Object.defineProperties(gp, {
      id: ro(IDS[identity] || IDS.ds4),
      index: ro(index),
      connected: ro(true),
      mapping: ro('standard'),
      timestamp: ro(ts),
      axes: ro(Object.freeze(p.axes.slice(0, 4))),
      buttons: ro(Object.freeze(p.buttons.map((v) => Object.freeze({
        pressed: v > PRESSED, touched: v > 0, value: v,
      })))),
      vibrationActuator: ro(actuator),
      hapticActuators: ro(Object.freeze([])),
    });
    return gp;
  };

  let bridgePads = null;      // tableau de 4 (Gamepad ou null)
  let bridgeTime = -Infinity;
  const present = new Set();

  const fire = (type, gp) => {
    const ev = new Event(type);
    Object.defineProperty(ev, 'gamepad', { value: gp });
    window.dispatchEvent(ev);
  };

  // Messages du script de l'extension (même fenêtre, autre monde JS)
  window.addEventListener('message', (ev) => {
    const d = ev.source === window && ev.data && ev.data.__nfsu2pad;
    if (!d) return;
    ev.stopImmediatePropagation();   // le site ne voit pas ces messages
    const ts = performance.now();
    const pads = new Array(MAX_PADS).fill(null);
    (d.pads || []).slice(0, MAX_PADS).forEach((p, i) => { pads[i] = makePad(p, i, d.identity, ts); });
    bridgePads = pads;
    bridgeTime = ts;
    pads.forEach((gp, i) => {
      if (gp && !present.has(i)) { present.add(i); fire('gamepadconnected', gp); }
      if (!gp && present.has(i)) { present.delete(i); fire('gamepaddisconnected', makePad({ buttons: [], axes: [] }, i, d.identity, ts)); }
    });
  }, true);

  // Pont coupé (jeu en train de quitter, script arrêté) : on prévient le site
  setInterval(() => {
    if (present.size && performance.now() - bridgeTime > FRESH_MS) {
      present.forEach((i) => fire('gamepaddisconnected', makePad({ buttons: [], axes: [] }, i, 'ds4', performance.now())));
      present.clear();
    }
  }, 500);

  // Sans pont : on garde les manettes de Chromium
  const isVirtual = (gp) => gp && ((/054c/i.test(gp.id) && /09cc/i.test(gp.id)) ||
                                   (/045e/i.test(gp.id) && /028e/i.test(gp.id)));
  const filterReal = (pads) => {
    const arr = Array.from(pads);
    return arr.some(isVirtual) ? arr.map((gp) => (gp && !isVirtual(gp) ? null : gp)) : arr;
  };

  const neutral = (gp) => gp && makePad({
    buttons: gp.buttons.map(() => 0), axes: gp.axes.map(() => 0),
  }, gp.index, /054c/i.test(gp.id) ? 'ds4' : 'xbox', gp.timestamp);

  navigator.getGamepads = function () {
    const pads = (bridgePads && performance.now() - bridgeTime < FRESH_MS)
      ? bridgePads.slice()
      : filterReal(original());
    if (document.documentElement && document.documentElement.dataset.nfsu2Osk === '1') {
      return pads.map(neutral);
    }
    return pads;
  };
})();
