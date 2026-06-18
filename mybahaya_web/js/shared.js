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
  initFAB();
  initNav();
  initFadeIn();
});
