// Script de fond de l'extension NFSU2 (Foclabroc Toolbox)
//  - pont manette : se connecte au WebSocket local de ds4emu.py et relaie l'état
//    des manettes aux pages (port "nfsu2pad"). Passer par ici évite les règles
//    d'accès au réseau local qui s'appliquent aux pages web.
//  - sortie : ferme toutes les fenêtres (donc Chromium) sur demande.
const BRIDGE_URL = 'ws://127.0.0.1:47820';
const ports = new Set();
let ws = null;
let connected = false;
let last = null;
let retry = null;
let attempts = 0;
let info = 'démarrage';

const send = (msg) => {
  for (const p of ports) {
    try { p.postMessage(msg); } catch (err) { ports.delete(p); }
  }
};

const connectBridge = () => {
  if (ws && ws.readyState <= 1) return;
  clearTimeout(retry);
  attempts += 1;
  try {
    ws = new WebSocket(BRIDGE_URL);
  } catch (err) {
    info = 'WebSocket refusé : ' + err.message;
    send({ status: false, info });
    retry = setTimeout(connectBridge, 2000);
    return;
  }
  info = 'tentative ' + attempts;
  ws.onopen = () => { connected = true; info = 'ouvert (tentative ' + attempts + ')'; send({ status: true, info }); };
  ws.onmessage = (m) => { last = m.data; send({ state: m.data }); };
  ws.onclose = (ev) => {
    connected = false;
    ws = null;
    info = 'fermé, code ' + ev.code + ' (tentative ' + attempts + ')';
    send({ status: false, info });
    retry = setTimeout(connectBridge, 2000);
  };
  ws.onerror = () => { try { ws.close(); } catch (err) {} };
};

chrome.runtime.onConnect.addListener((port) => {
  if (port.name !== 'nfsu2pad') return;
  ports.add(port);
  port.onDisconnect.addListener(() => ports.delete(port));
  port.postMessage({ status: connected, info });
  if (last) port.postMessage({ state: last });
  connectBridge();
});

chrome.runtime.onMessage.addListener((msg) => {
  if (msg && msg.nfsu2Quit) {
    chrome.windows.getAll({}, (wins) => wins.forEach((w) => chrome.windows.remove(w.id)));
  }
});

connectBridge();
