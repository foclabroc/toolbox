// Ferme toutes les fenêtres (donc Chromium) quand la page demande à quitter.
chrome.runtime.onMessage.addListener((msg) => {
  if (msg && msg.nfsu2Quit) {
    chrome.windows.getAll({}, (wins) => wins.forEach((w) => chrome.windows.remove(w.id)));
  }
});
