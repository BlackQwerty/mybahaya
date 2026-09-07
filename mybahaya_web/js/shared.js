/* ============================================================
   shared.js — MyBahaya Shared Interactions
   ============================================================ */

'use strict';

/* ── Top Settings Menu ── */
function initSettingsMenu() {
  const settingsBtn = document.getElementById('settings-btn');
  const settingsMenu = document.getElementById('settings-menu');
  if (!settingsBtn || !settingsMenu) return;

  settingsBtn.addEventListener('click', (event) => {
    event.stopPropagation();
    const isOpen = settingsMenu.classList.toggle('open');
    settingsBtn.classList.toggle('active', isOpen);
    settingsBtn.setAttribute('aria-expanded', isOpen);
  });

  document.addEventListener('click', (e) => {
    if (!settingsBtn.contains(e.target) && !settingsMenu.contains(e.target)) {
      settingsMenu.classList.remove('open');
      settingsBtn.classList.remove('active');
      settingsBtn.setAttribute('aria-expanded', 'false');
    }
  });

  const logoutBtn = settingsMenu.querySelector('.settings-logout');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', () => {
      if (confirm('Are you sure you want to log out?')) {
        if (typeof firebase !== 'undefined') {
          firebase.auth().signOut().then(() => {
            window.location.replace('login.html');
          });
        } else {
          window.location.replace('login.html');
        }
      }
    });
  }

  const accountBtn = settingsMenu.querySelector('.settings-account');
  if (accountBtn) {
    accountBtn.addEventListener('click', (event) => {
      event.preventDefault();
      settingsMenu.classList.remove('open');
      settingsBtn.classList.remove('active');
      settingsBtn.setAttribute('aria-expanded', 'false');

      const user = window.currentUser;
      const organization = window.currentUserOrg;
      const modal = document.createElement('div');
      modal.className = 'account-modal-backdrop';
      modal.innerHTML = `
        <section class="account-modal" role="dialog" aria-modal="true" aria-labelledby="account-modal-title">
          <button class="account-modal-close" type="button" aria-label="Close account dialog">&times;</button>
          <h2 id="account-modal-title">Account</h2>
          <div class="account-detail"><span>Email</span><strong>${user?.email || 'Unavailable'}</strong></div>
          <div class="account-detail"><span>Role</span><strong>${window.currentUserRole || 'User'}</strong></div>
          ${organization?.name ? `<div class="account-detail"><span>Organization</span><strong>${organization.name}</strong></div>` : ''}
        </section>`;
      document.body.appendChild(modal);

      const closeModal = () => modal.remove();
      modal.querySelector('.account-modal-close').addEventListener('click', closeModal);
      modal.addEventListener('click', event => { if (event.target === modal) closeModal(); });
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

/* ── Toast Notifications ── */
function showToast(message, type = 'success', duration = 3500) {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    document.body.appendChild(container);
  }

  const icons = { success: 'checkmark-circle-outline', error: 'alert-circle-outline', info: 'information-circle-outline' };
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `<ion-icon name="${icons[type] || icons.info}"></ion-icon><span>${message}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(8px)';
    toast.style.transition = 'opacity 0.2s, transform 0.2s';
    setTimeout(() => toast.remove(), 220);
  }, duration);
}

// Expose globally so page scripts can call it
window.showToast = showToast;

/* ── Init on DOM ready ── */
document.addEventListener('DOMContentLoaded', () => {
  initSettingsMenu();
  initNav();
  initFadeIn();
});
