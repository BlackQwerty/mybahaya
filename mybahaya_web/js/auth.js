/* ============================================================
   auth.js — Auth guard + role resolution for all protected pages.
   Loaded in <head> AFTER Firebase SDK scripts.

   Resolves one of three roles for the signed-in user:
     • admin   — in /admins collection → sees everything
     • org     — matched in /organizations by authUid → sees only assigned reports
     • citizen — neither → no dashboard access (redirected to login)

   Page scripts await `window.authReady` before querying Firestore, then read:
     • window.currentUser        — the Firebase user
     • window.currentUserIsAdmin — boolean
     • window.currentUserOrg     — { id, ...orgData } or null
     • window.currentUserRole    — 'admin' | 'org' | 'citizen'
   ============================================================ */

// Hide page immediately to prevent flash of unauthenticated content
document.documentElement.classList.add('auth-pending');

const ADMIN_ONLY_PAGES = ['organizations.html', 'users.html'];
const currentPage = location.pathname.split('/').pop() || 'home.html';

// Page scripts await this; it resolves once the role is known.
let _resolveAuthReady;
window.authReady = new Promise(res => { _resolveAuthReady = res; });

firebase.auth().onAuthStateChanged(async function (user) {
  if (!user) {
    window.location.replace('login.html');
    return;
  }

  window.currentUser = user;

  // Force a token refresh so any custom claims set server-side
  // (role: admin/org, orgId) are present on this session's token.
  try { await user.getIdToken(true); } catch (e) { /* non-fatal */ }

  let isAdmin = false;
  let org     = null;

  try {
    // 1. Admin? — presence in /admins collection
    const adminSnap = await db.collection('admins').doc(user.uid).get();
    isAdmin = adminSnap.exists;

    // 2. Org? — only check if not admin. Match /organizations by authUid.
    if (!isAdmin) {
      const orgQuery = await db.collection('organizations')
        .where('authUid', '==', user.uid)
        .limit(1)
        .get();
      if (!orgQuery.empty) {
        const doc = orgQuery.docs[0];
        org = { id: doc.id, ...doc.data() };
      }
    }
  } catch (err) {
    console.error('Role check failed:', err);
    // Fall through with safe defaults (no admin, no org).
  }

  // 3. Neither admin nor org → plain citizen, no dashboard access.
  if (!isAdmin && !org) {
    await firebase.auth().signOut();
    window.location.replace('login.html?error=no-access');
    return;
  }

  // Publish role globally
  window.currentUserIsAdmin = isAdmin;
  window.currentUserOrg     = org;
  window.currentUserRole    = isAdmin ? 'admin' : 'org';

  // Block org users from admin-only pages
  if (ADMIN_ONLY_PAGES.includes(currentPage) && !isAdmin) {
    window.location.replace('home.html');
    return;
  }

  // Hide admin-only nav links for org users
  if (!isAdmin) {
    document.querySelectorAll('a.admin-only').forEach(function (el) {
      el.parentElement.style.display = 'none';
    });
  }

  // Phase 3 — register browser push for org users so they get notified
  // when a new incident is assigned to them (even with the tab closed).
  if (org) {
    _registerOrgPush(org.id).catch(e => console.warn('[Push]', e));
  }

  // Let page scripts proceed
  _resolveAuthReady({ isAdmin, org, role: window.currentUserRole });

  // Reveal page
  document.documentElement.classList.remove('auth-pending');

  // Populate navbar avatar tooltip
  document.addEventListener('DOMContentLoaded', function () {
    const avatarBtn = document.querySelector('.avatar-btn');
    if (avatarBtn) {
      const label = org ? org.name : user.email;
      avatarBtn.title = label;
      avatarBtn.setAttribute('aria-label', label);
    }
  });
});

/* ── Phase 3: register browser push for org and save token to Firestore ── */
async function _registerOrgPush(orgId) {
  if (!('Notification' in window) || !('serviceWorker' in navigator)) return;

  // Register the service worker that handles background notifications
  const reg = await navigator.serviceWorker.register('/firebase-messaging-sw.js');

  const messaging = firebase.messaging();

  // Request permission — browser shows a one-time dialog
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') return;

  // VAPID key from Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
  // Go to: https://console.firebase.google.com → mybahaya-fyp → Project Settings → Cloud Messaging
  // Scroll to "Web configuration" and copy the Key pair value, paste it below.
  const VAPID_KEY = 'YOUR_VAPID_KEY_FROM_FIREBASE_CONSOLE';

  const token = await messaging.getToken({ vapidKey: VAPID_KEY, serviceWorkerRegistration: reg });
  if (!token) return;

  // Save to Firestore so the backend can push to this browser
  await db.collection('organizations').doc(orgId).update({ browserFcmToken: token });
  console.log('[Push] Browser push token saved for org', orgId);
}
