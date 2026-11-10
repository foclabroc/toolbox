// Clavier virtuel NFSU2 (Foclabroc Toolbox)
// S'ouvre quand un champ texte du site prend le focus (si une manette est branchée
// ou au tactile), ou avec L3 (clic stick gauche). R3 = clic souris (evmapy).
// Manette : croix/stick = se déplacer, A = taper, B = effacer, X = espace,
//           Y = majuscules, Start = valider, L3 = ouvrir/fermer.
// Select + Start (ou Guide + Start) = quitter le jeu, même si evmapy ne voit plus la manette.
(() => {
  'use strict';
  if (window.__nfsu2OskLoaded) return;
  window.__nfsu2OskLoaded = true;

  // ---------------------------------------------------------------- champs
  const TEXT_TYPES = new Set(['', 'text', 'search', 'email', 'url', 'tel', 'password']);
  const isTextField = (el) => !!el && !el.disabled && !el.readOnly && (
    (el.tagName === 'INPUT' && TEXT_TYPES.has((el.getAttribute('type') || '').toLowerCase())) ||
    el.tagName === 'TEXTAREA' || el.isContentEditable);

  const isVisible = (el) => {
    const r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < innerHeight &&
      getComputedStyle(el).visibility !== 'hidden';
  };

  const findField = () => {
    if (isTextField(document.activeElement)) return document.activeElement;
    return [...document.querySelectorAll('input, textarea, [contenteditable="true"]')]
      .find((el) => isTextField(el) && isVisible(el)) || null;
  };

  const getValue = (el) => el.isContentEditable ? el.textContent : el.value;

  const setValue = (el, v) => {
    if (el.isContentEditable) {
      el.textContent = v;
    } else {
      const proto = el.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
      Object.getOwnPropertyDescriptor(proto, 'value').set.call(el, v);
    }
    el.dispatchEvent(new Event('input', { bubbles: true }));
  };

  const caret = (el) => {
    try { if (typeof el.selectionStart === 'number') return [el.selectionStart, el.selectionEnd]; } catch (e) {}
    const n = getValue(el).length;
    return [n, n];
  };

  const setCaret = (el, pos) => { try { el.setSelectionRange(pos, pos); } catch (e) {} };

  const insert = (text) => {
    const el = state.target;
    if (!el) return;
    const v = getValue(el);
    const [a, b] = caret(el);
    const max = el.maxLength > 0 ? el.maxLength : Infinity;
    if (v.length - (b - a) + text.length > max) return;
    setValue(el, v.slice(0, a) + text + v.slice(b));
    setCaret(el, a + text.length);
  };

  const backspace = () => {
    const el = state.target;
    if (!el) return;
    const v = getValue(el);
    const [a, b] = caret(el);
    if (a !== b) { setValue(el, v.slice(0, a) + v.slice(b)); setCaret(el, a); }
    else if (a > 0) { setValue(el, v.slice(0, a - 1) + v.slice(a)); setCaret(el, a - 1); }
  };

  const submit = () => {
    const el = state.target;
    if (el) {
      for (const type of ['keydown', 'keypress', 'keyup']) {
        el.dispatchEvent(new KeyboardEvent(type, {
          key: 'Enter', code: 'Enter', keyCode: 13, which: 13, bubbles: true, cancelable: true,
        }));
      }
      el.dispatchEvent(new Event('change', { bubbles: true }));
    }
    close();
  };

  // ---------------------------------------------------------------- dispositions
  const ROWS = {
    lower: ['1234567890', 'azertyuiop', 'qsdfghjklm', 'wxcvbn-_.@'],
    upper: ['1234567890', 'AZERTYUIOP', 'QSDFGHJKLM', 'WXCVBN-_.@'],
    sym:   ['!?#$%&*()\'', 'éèêàâùûôîç', '+=/\\:;,"<>', '[]{}~^|€£°'],
  };
  // Dernière ligne : touches spéciales, largeurs en "colonnes" (total 10)
  const BOTTOM = [
    { k: 'shift', w: 1.5 }, { k: 'sym', w: 1.5 }, { k: 'space', w: 4 },
    { k: 'bksp', w: 1.5 }, { k: 'ok', w: 1.5 },
  ];
  const LABELS = { shift: '⇧', sym: '?123', space: 'Espace', bksp: '⌫', ok: 'OK' };

  const state = {
    open: false, target: null, layer: 'lower', shiftOnce: false,
    row: 1, col: 0, lastInputWasTouch: false,
  };

  // ---------------------------------------------------------------- interface
  const host = document.createElement('div');
  host.style.cssText = 'all:initial;position:fixed;left:0;right:0;bottom:0;z-index:2147483647;display:none;';
  const shadow = host.attachShadow({ mode: 'closed' });
  shadow.innerHTML = `
<style>
  .kb { margin: 0 auto 8px; width: min(920px, 98vw); box-sizing: border-box; padding: 10px;
        background: rgba(12,14,18,.94); border: 1px solid #2c8fd6; border-radius: 14px;
        box-shadow: 0 0 24px rgba(44,143,214,.45); font: 600 20px/1 system-ui, sans-serif;
        color: #e8eef5; user-select: none; -webkit-user-select: none; touch-action: manipulation; }
  .preview { min-height: 30px; margin: 0 4px 8px; padding: 8px 10px; background: #05070a;
             border-radius: 8px; font-weight: 500; overflow: hidden; white-space: nowrap;
             text-overflow: ellipsis; }
  .preview::after { content: '▏'; color: #2c8fd6; }
  .row { display: flex; gap: 6px; margin-top: 6px; }
  .key { flex: 1 1 0; height: 46px; display: flex; align-items: center; justify-content: center;
         background: #1d232c; border-radius: 8px; border: 2px solid transparent; cursor: pointer; }
  .key.special { background: #26303c; font-size: 16px; }
  .key.on { background: #2c5f8a; }
  .key.sel { border-color: #49b3ff; background: #2c8fd6; color: #fff; }
  .help { margin-top: 8px; font-size: 13px; font-weight: 500; color: #8fa3b8; text-align: center; }
</style>
<div class="kb">
  <div class="preview"></div>
  <div class="keys"></div>
  <div class="help">A taper · B effacer · X espace · Y majuscules · Start valider · L3 fermer</div>
</div>`;
  const preview = shadow.querySelector('.preview');
  const keysBox = shadow.querySelector('.keys');

  const layerRows = () => {
    const base = state.layer === 'sym' ? ROWS.sym : (state.layer === 'upper' || state.shiftOnce ? ROWS.upper : ROWS.lower);
    return base.map((r) => [...r]);
  };

  const render = () => {
    keysBox.textContent = '';
    layerRows().forEach((chars, r) => {
      const row = document.createElement('div');
      row.className = 'row';
      chars.forEach((ch, c) => row.appendChild(makeKey(ch, r, c, false)));
      keysBox.appendChild(row);
    });
    const row = document.createElement('div');
    row.className = 'row';
    BOTTOM.forEach((b, c) => {
      const key = makeKey(LABELS[b.k], 4, c, true, b.k);
      key.style.flexGrow = b.w;
      if ((b.k === 'shift' && (state.layer === 'upper' || state.shiftOnce)) || (b.k === 'sym' && state.layer === 'sym')) key.classList.add('on');
      row.appendChild(key);
    });
    keysBox.appendChild(row);
    if (state.target) preview.textContent = state.target.type === 'password'
      ? '•'.repeat(getValue(state.target).length) : getValue(state.target);
  };

  function makeKey(label, r, c, special, action) {
    const key = document.createElement('div');
    key.className = 'key' + (special ? ' special' : '') + (r === state.row && c === state.col ? ' sel' : '');
    key.textContent = label;
    key.addEventListener('pointerdown', (e) => {
      e.preventDefault(); // garde le focus sur le champ
      state.row = r; state.col = c;
      press(special ? action : label);
    });
    return key;
  }

  const press = (k) => {
    switch (k) {
      case 'shift':
        if (state.layer === 'sym') state.layer = 'lower';
        else if (state.layer === 'upper') state.layer = 'lower';
        else if (state.shiftOnce) { state.shiftOnce = false; state.layer = 'upper'; }
        else state.shiftOnce = true;
        break;
      case 'sym': state.layer = state.layer === 'sym' ? 'lower' : 'sym'; state.shiftOnce = false; break;
      case 'space': insert(' '); break;
      case 'bksp': backspace(); break;
      case 'ok': submit(); return;
      default:
        insert(k);
        if (state.shiftOnce) state.shiftOnce = false;
    }
    if (state.open) render();
  };

  const pressSelected = () => {
    if (state.row === 4) press(BOTTOM[state.col].k);
    else press(layerRows()[state.row][state.col]);
  };

  // Colonnes de la dernière ligne <-> colonnes des lignes de lettres
  const bottomIndexFromCol = (col) => {
    let x = 0;
    const center = col + 0.5;
    for (let i = 0; i < BOTTOM.length; i++) { x += BOTTOM[i].w; if (center < x) return i; }
    return BOTTOM.length - 1;
  };
  const colFromBottomIndex = (i) => {
    let x = 0;
    for (let j = 0; j < i; j++) x += BOTTOM[j].w;
    return Math.min(9, Math.floor(x + BOTTOM[i].w / 2));
  };

  const move = (dr, dc) => {
    if (dr) {
      const next = state.row + dr;
      if (next < 0 || next > 4) return;
      if (next === 4) state.col = bottomIndexFromCol(state.col);
      else if (state.row === 4) state.col = colFromBottomIndex(state.col);
      state.row = next;
    } else {
      const max = state.row === 4 ? BOTTOM.length - 1 : 9;
      state.col = (state.col + dc + max + 1) % (max + 1);
    }
    render();
  };

  // ---------------------------------------------------------------- ouverture
  const open = (el) => {
    if (!el) return;
    state.target = el;
    state.open = true;
    if (document.activeElement !== el) el.focus({ preventScroll: true });
    if (!host.isConnected) (document.body || document.documentElement).appendChild(host);
    host.style.display = 'block';
    document.documentElement.dataset.nfsu2Osk = '1';
    render();
    // Garde le champ visible au-dessus du clavier
    requestAnimationFrame(() => {
      const kbTop = host.getBoundingClientRect().top;
      const r = el.getBoundingClientRect();
      if (r.bottom > kbTop - 10) el.scrollIntoView({ block: 'center' });
    });
  };

  const close = () => {
    state.open = false;
    state.shiftOnce = false;
    host.style.display = 'none';
    delete document.documentElement.dataset.nfsu2Osk;
  };

  const padConnected = () => navigator.getGamepads && [...navigator.getGamepads()].some((g) => g && g.connected);

  document.addEventListener('pointerdown', (e) => { state.lastInputWasTouch = e.pointerType === 'touch'; }, true);

  document.addEventListener('focusin', (e) => {
    const el = e.target;
    if (!isTextField(el)) return;
    if (state.open) { state.target = el; render(); return; }
    if (padConnected() || state.lastInputWasTouch) open(el);
  }, true);

  document.addEventListener('focusout', () => {
    // Laisse le temps au focus d'aller sur un autre champ
    setTimeout(() => { if (state.open && !isTextField(document.activeElement)) close(); }, 150);
  }, true);

  // Un vrai clavier : on s'efface
  document.addEventListener('keydown', (e) => { if (e.isTrusted && state.open && !e.repeat) close(); }, true);
  document.addEventListener('input', (e) => { if (state.open && e.target === state.target) render(); }, true);

  // ---------------------------------------------------------------- manette
  // Mapping standard du navigateur, sinon mapping SDL fourni par Batocera (padmap.js)
  const sdl = {};
  String(window.__NFSU2_SDLMAP || '').split(',').forEach((tok) => {
    const m = tok.match(/^(\w+):b(\d+)$/);
    if (m) sdl[m[1]] = +m[2];
  });
  const STD = { a: 0, b: 1, x: 2, y: 3, back: 8, start: 9, leftstick: 10, guide: 16, dpup: 12, dpdown: 13, dpleft: 14, dpright: 15 };

  const read = (gp) => {
    const map = gp.mapping === 'standard' ? STD : sdl;
    const btn = (name) => {
      const i = map[name];
      return i !== undefined && gp.buttons[i] ? gp.buttons[i].pressed : false;
    };
    const ax = (i) => gp.axes[i] || 0;
    return {
      up: btn('dpup') || ax(1) < -0.6,
      down: btn('dpdown') || ax(1) > 0.6,
      left: btn('dpleft') || ax(0) < -0.6,
      right: btn('dpright') || ax(0) > 0.6,
      a: btn('a'), b: btn('b'), x: btn('x'), y: btn('y'),
      start: btn('start'), l3: btn('leftstick'), back: btn('back'), guide: btn('guide'),
    };
  };

  const prev = {};
  const held = {};
  const REPEAT_DELAY = 380;
  const REPEAT_RATE = 90;

  const edge = (name, now, pressed, repeat) => {
    const was = prev[name];
    prev[name] = pressed;
    if (!pressed) { held[name] = 0; return false; }
    if (!was) { held[name] = now + REPEAT_DELAY; return true; }
    if (repeat && now >= held[name]) { held[name] = now + REPEAT_RATE; return true; }
    return false;
  };

  const loop = (now) => {
    const pads = navigator.getGamepads ? [...navigator.getGamepads()].filter(Boolean) : [];
    // Fusionne toutes les manettes : n'importe laquelle peut taper
    const s = { up: false, down: false, left: false, right: false, a: false, b: false, x: false, y: false, start: false, l3: false, back: false, guide: false };
    for (const gp of pads) {
      const r = read(gp);
      for (const k in s) s[k] = s[k] || r[k];
    }

    // Quitter : Select + Start ou Guide + Start
    if (edge('quit', now, (s.back || s.guide) && s.start, false)) {
      try { chrome.runtime.sendMessage({ nfsu2Quit: true }); } catch (e) {}
    }

    if (edge('l3', now, s.l3, false)) {
      if (state.open) close(); else open(findField());
    }

    if (state.open) {
      if (edge('up', now, s.up, true)) move(-1, 0);
      if (edge('down', now, s.down, true)) move(1, 0);
      if (edge('left', now, s.left, true)) move(0, -1);
      if (edge('right', now, s.right, true)) move(0, 1);
      if (edge('a', now, s.a, true)) pressSelected();
      if (edge('b', now, s.b, true)) { backspace(); render(); }
      if (edge('x', now, s.x, true)) { insert(' '); render(); }
      if (edge('y', now, s.y, false)) press('shift');
      if (edge('start', now, s.start, false)) submit();
    } else {
      // Mémorise l'état sans agir, pour ne pas déclencher à l'ouverture
      ['up', 'down', 'left', 'right', 'a', 'b', 'x', 'y', 'start'].forEach((k) => { prev[k] = s[k]; });
    }
    requestAnimationFrame(loop);
  };
  requestAnimationFrame(loop);
})();
