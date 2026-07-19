// skip first line (autoconfig requirement)
// tab switching by wheel over the tab bar, one tab per detent. The builtin
// switchByScrolling handler fires per event with no delta accumulation, so
// hi-res wheels (MX Master) skip 2-3 tabs per detent. This replaces it with
// an accumulating listener; hi-res page scrolling is untouched.
try {
  Services.prefs.setBoolPref("toolkit.tabbox.switchByScrolling", false);
  Services.obs.addObserver(win => {
    const tabs = win.gBrowser && win.gBrowser.tabContainer;
    if (!tabs || tabs._accumWheelPatched) return;
    tabs._accumWheelPatched = true;
    let acc = 0;
    tabs.addEventListener("wheel", e => {
      if (e.deltaX) return; // thumb wheel: leave to default strip scrolling
      // one detent = 3 lines (LINE mode) or ~48px (PIXEL mode)
      const detent = e.deltaMode === e.DOM_DELTA_LINE ? 3 : 48;
      if ((acc > 0) !== (e.deltaY > 0)) acc = 0; // direction change resets
      acc += e.deltaY;
      while (Math.abs(acc) >= detent) {
        win.gBrowser.tabContainer.advanceSelectedTab(acc > 0 ? 1 : -1, false);
        acc -= detent * Math.sign(acc);
      }
      e.preventDefault();
      e.stopPropagation();
    }, { capture: true });
  }, "browser-delayed-startup-finished");
} catch (e) {
  Components.utils.reportError(e);
}
