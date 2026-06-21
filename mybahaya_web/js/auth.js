/* ============================================================
   auth.js — Auth guard for all protected pages.
   Loaded in <head> AFTER Firebase SDK scripts.
   ============================================================ */

// Hide page immediately to prevent flash of unauthenticated content
document.documentElement.classList.add('auth-pending');

const ADMIN_ONLY_PAGES = ['organizations.html'];
const currentPage = location.pathname.split('/').pop() || 'home.html';

firebase.auth().onAuthStateChanged(function (user) {
  if (!user) {
    window.location.replace('login.html');
    return;
  }

  // Store globally so page scripts can read it
  window.currentUser = user;

  // Check admin role from Firestore /admins collection
  db.collection('admins').doc(user.uid).get().then(function (snap) {
    const isAdmin = snap.exists;
    window.currentUserIsAdmin = isAdmin;

    // Block non-admins from admin-only pages
    if (ADMIN_ONLY_PAGES.includes(currentPage) && !isAdmin) {
      window.location.replace('home.html');
      return;
    }

    // Hide Organizations nav link for non-admins
    if (!isAdmin) {
      document.querySelectorAll('a.admin-only').forEach(function (el) {
        el.parentElement.style.display = 'none';
      });
    }

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
  }).catch(function (err) {
    console.error('Role check failed:', err);
    // On error, block admin pages to be safe
    if (ADMIN_ONLY_PAGES.includes(currentPage)) {
      window.location.replace('home.html');
      return;
    }
    document.documentElement.classList.remove('auth-pending');
  });
});
