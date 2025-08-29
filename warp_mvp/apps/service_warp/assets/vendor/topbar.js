// Minimal topbar implementation to satisfy Phoenix LiveView loading UI
// This is a lightweight stub; replace with the full topbar lib if desired.

const Topbar = (() => {
  let visible = false;
  let progress = 0;
  let rafId = null;
  const bar = document.createElement("div");
  bar.style.position = "fixed";
  bar.style.top = "0";
  bar.style.left = "0";
  bar.style.height = "3px";
  bar.style.width = "0%";
  bar.style.zIndex = "9999";
  bar.style.transition = "width 200ms ease-out, opacity 200ms ease-out";
  bar.style.background = "#29d";
  bar.style.boxShadow = "0 0 10px rgba(0,0,0,.3)";

  function ensureInDom() {
    if (!bar.parentNode) document.body.appendChild(bar);
  }

  function tick() {
    if (!visible) return;
    progress = Math.min(98, progress + Math.random() * 2);
    bar.style.width = progress + "%";
    rafId = requestAnimationFrame(tick);
  }

  function show() {
    if (visible) return;
    visible = true;
    progress = 10;
    ensureInDom();
    bar.style.opacity = "1";
    bar.style.width = progress + "%";
    tick();
  }

  function hide() {
    visible = false;
    if (rafId) cancelAnimationFrame(rafId);
    progress = 100;
    bar.style.width = progress + "%";
    setTimeout(() => {
      bar.style.opacity = "0";
      bar.style.width = "0%";
    }, 200);
  }

  function config(opts) {
    if (!opts) return;
    if (opts.barColors && opts.barColors[0]) bar.style.background = opts.barColors[0];
    if (opts.shadowColor) bar.style.boxShadow = `0 0 10px ${opts.shadowColor}`;
  }

  return { show, hide, config };
})();

export default Topbar;


