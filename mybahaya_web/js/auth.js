/* ============================================================
   auth.js — Auth guard for all protected pages.
   Loaded in <head> AFTER Firebase SDK scripts.
   ============================================================ */

// Hide page immediately to prevent flash of unauthenticated content
document.documentElement.classList.add('auth-pending');

firebase.auth().onAuthStateChanged(function (user) {
  if (!user) {
    window.location.replace('login.html');
    return;
  }

  // Store globally so page scripts can read it
  window.currentUser = user;

  // Reveal page
  document.documentElement.classList.remove('auth-pending');

  // Populate navbar avatar tooltip with email
  document.addEventListener('DOMContentLoaded', function () {
    const avatarBtn = document.querySelector('.avatar-btn');
    if (avatarBtn) {
      avatarBtn.title    = user.email;
      avatarBtn.setAttribute('aria-label', user.email);
    }
  });
});
