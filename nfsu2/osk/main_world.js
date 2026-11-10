// Monde de la page : quand le clavier virtuel est ouvert, le jeu voit des manettes
// au repos, pour que les boutons servant à taper ne pilotent pas aussi le site.
(() => {
  if (!navigator.getGamepads) return;
  const original = navigator.getGamepads.bind(navigator);
  const neutral = (gp) => gp && {
    id: gp.id, index: gp.index, mapping: gp.mapping, connected: gp.connected,
    timestamp: gp.timestamp,
    axes: gp.axes.map(() => 0),
    buttons: gp.buttons.map(() => ({ pressed: false, touched: false, value: 0 })),
    vibrationActuator: gp.vibrationActuator,
  };
  navigator.getGamepads = function () {
    const pads = original();
    if (document.documentElement && document.documentElement.dataset.nfsu2Osk === '1') {
      return Array.from(pads, neutral);
    }
    return pads;
  };
})();
