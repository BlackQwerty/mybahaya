/* ============================================================
   shared.js — MyBahaya Shared Interactions
   ============================================================ */

'use strict';

/* ── FAB Hamburger Menu ── */
function initFAB() {
  const fabBtn  = document.getElementById('fab-btn');
  const fabMenu = document.getElementById('fab-menu');
  if (!fabBtn || !fabMenu) return;

  fabBtn.addEventListener('click', () => {
    const isOpen = fabMenu.classList.toggle('open');
    fabBtn.classList.toggle('active', isOpen);
    fabBtn.setAttribute('aria-expanded', isOpen);
  });

  // Close when clicking outside
  document.addEventListener('click', (e) => {
    if (!fabBtn.contains(e.target) && !fabMenu.contains(e.target)) {
      fabMenu.classList.remove('open');
      fabBtn.classList.remove('active');
    }
  });

  // Logout action
  const logoutBtn = document.getElementById('fab-logout');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', () => {
      if (confirm('Are you sure you want to log out?')) {
        // Placeholder — replace with real auth logout
        alert('Logged out successfully.');
        window.location.href = 'home.html';
      }
    });
  }

  // Settings action
  const settingsBtn = document.getElementById('fab-settings');
  if (settingsBtn) {
    settingsBtn.addEventListener('click', () => {
      alert('Settings panel coming soon!');
    });
  }
}

/* ── Mark Active Nav Link ── */
function initNav() {
  const currentFile = location.pathname.split('/').pop() || 'home.html';
  document.querySelectorAll('.nav-links a').forEach(link => {
    const href = link.getAttribute('href');
    if (href === currentFile) {
      link.classList.add('active');
    }
  });
}

/* ── Fade-in observer ── */
function initFadeIn() {
  const els = document.querySelectorAll('.fade-in');
  if (!els.length) return;
  const obs = new IntersectionObserver((entries) => {
    entries.forEach(e => { if (e.isIntersecting) { e.target.style.visibility = 'visible'; obs.unobserve(e.target); } });
  }, { threshold: 0.1 });
  els.forEach(el => { el.style.visibility = 'hidden'; obs.observe(el); });
}

/* ── Init on DOM ready ── */
document.addEventListener('DOMContentLoaded', () => {
  initFAB();
  initNav();
  initFadeIn();
});
