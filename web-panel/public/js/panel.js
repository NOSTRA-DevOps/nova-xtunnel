// NOVA XTUNNEL - shared panel behaviors (loaded on every page via partials/head.ejs)

(function () {
  const EYE_OPEN = '<svg width="16" height="16" viewBox="0 0 16 16" fill="none"><path d="M1 8s2.5-5 7-5 7 5 7 5-2.5 5-7 5-7-5-7-5Z" stroke="currentColor" stroke-width="1.4"/><circle cx="8" cy="8" r="2.1" stroke="currentColor" stroke-width="1.4"/></svg>';
  const EYE_OFF = '<svg width="16" height="16" viewBox="0 0 16 16" fill="none"><path d="M1 8s2.5-5 7-5c1.4 0 2.6.4 3.6 1M15 8s-2.5 5-7 5c-1.4 0-2.6-.4-3.6-1" stroke="currentColor" stroke-width="1.4"/><path d="M1.5 1.5l13 13" stroke="currentColor" stroke-width="1.4"/></svg>';

  function attachPasswordToggles() {
    document.querySelectorAll('input[type="password"]').forEach((input) => {
      if (input.dataset.toggleAttached) return;
      input.dataset.toggleAttached = '1';

      const wrapper = document.createElement('div');
      wrapper.className = 'password-field';
      input.parentNode.insertBefore(wrapper, input);
      wrapper.appendChild(input);

      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'password-toggle';
      btn.setAttribute('aria-label', 'Afficher le mot de passe');
      btn.tabIndex = -1;
      btn.innerHTML = EYE_OPEN;
      wrapper.appendChild(btn);

      btn.addEventListener('click', () => {
        const willShow = input.type === 'password';
        input.type = willShow ? 'text' : 'password';
        btn.innerHTML = willShow ? EYE_OFF : EYE_OPEN;
        btn.setAttribute('aria-label', willShow ? 'Masquer le mot de passe' : 'Afficher le mot de passe');
      });
    });
  }

  function attachActionMenus() {
    document.querySelectorAll('[data-menu-toggle]').forEach((btn) => {
      if (btn.dataset.menuAttached) return;
      btn.dataset.menuAttached = '1';
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const menu = btn.closest('.action-menu');
        const wasOpen = menu.classList.contains('open');
        document.querySelectorAll('.action-menu.open').forEach((m) => m.classList.remove('open'));
        if (!wasOpen) menu.classList.add('open');
      });
    });
    document.addEventListener('click', () => {
      document.querySelectorAll('.action-menu.open').forEach((m) => m.classList.remove('open'));
    });
  }

  function showCopyToast(message) {
    let toast = document.querySelector('.copy-toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.className = 'copy-toast';
      document.body.appendChild(toast);
    }
    toast.textContent = message;
    toast.classList.add('show');
    clearTimeout(toast._hideTimer);
    toast._hideTimer = setTimeout(() => toast.classList.remove('show'), 1800);
  }

  function attachCopyButtons() {
    document.querySelectorAll('[data-copy-target]').forEach((btn) => {
      if (btn.dataset.copyAttached) return;
      btn.dataset.copyAttached = '1';
      btn.addEventListener('click', () => {
        const source = document.getElementById(btn.dataset.copyTarget);
        if (!source) return;
        const text = source.textContent.trim();
        const done = () => {
          showCopyToast(btn.dataset.copiedLabel || 'Copié !');
          document.querySelectorAll('.action-menu.open').forEach((m) => m.classList.remove('open'));
        };
        if (navigator.clipboard && window.isSecureContext) {
          navigator.clipboard.writeText(text).then(done).catch(done);
        } else {
          const ta = document.createElement('textarea');
          ta.value = text;
          ta.style.position = 'fixed';
          ta.style.opacity = '0';
          document.body.appendChild(ta);
          ta.select();
          try { document.execCommand('copy'); } catch { /* best effort */ }
          document.body.removeChild(ta);
          done();
        }
      });
    });
  }

  function initAll() {
    attachPasswordToggles();
    attachActionMenus();
    attachCopyButtons();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAll);
  } else {
    initAll();
  }
})();
