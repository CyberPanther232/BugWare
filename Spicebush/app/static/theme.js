(function () {
  const storageKey = 'theme';
  const getPreferred = () => {
    const saved = localStorage.getItem(storageKey);
    if (saved === 'light' || saved === 'dark') return saved;
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  };
  const setLogos = (theme) => {
    const body = document.body;
    const light = body?.dataset?.logoLight;
    const dark = body?.dataset?.logoDark;
    const src = theme === 'dark' ? (light || dark) : (dark || light);
    if (!src) return;
    const headerLogo = document.getElementById('site-logo');
    if (headerLogo && headerLogo.getAttribute('src') !== src) headerLogo.setAttribute('src', src);
    const homeLogo = document.getElementById('home-logo');
    if (homeLogo && homeLogo.getAttribute('src') !== src) homeLogo.setAttribute('src', src);
  };
  const apply = (theme) => {
    document.documentElement.setAttribute('data-theme', theme);
    setLogos(theme);
  };
  const toggle = () => {
    const current = document.documentElement.getAttribute('data-theme') || getPreferred();
    const next = current === 'dark' ? 'light' : 'dark';
    localStorage.setItem(storageKey, next);
    apply(next);
  };

  // Initialize
  const initial = getPreferred();
  // Set early to avoid flash
  document.documentElement.setAttribute('data-theme', initial);

  window.addEventListener('DOMContentLoaded', () => {
    // Ensure logos are correct once DOM is ready
    setLogos(document.documentElement.getAttribute('data-theme') || initial);
    const btn = document.getElementById('theme-toggle');
    if (btn) btn.addEventListener('click', toggle);
  });
})();