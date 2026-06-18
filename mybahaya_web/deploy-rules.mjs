/**
 * deploy-rules.mjs — Deploy Firestore security rules for mybahaya-fyp
 * Run: node mybahaya_web/deploy-rules.mjs
 */
import { initializeApp, cert, getApp } from 'firebase-admin/app';
import { getSecurityRules }            from 'firebase-admin/security-rules';
import { readFileSync }                from 'fs';
import { fileURLToPath }               from 'url';
import { dirname, join }               from 'path';

const __dir = dirname(fileURLToPath(import.meta.url));
const serviceAccount = JSON.parse(
  readFileSync(join(__dir, '../mybahaya-fyp-firebase-adminsdk-fbsvc-fdac908045.json'), 'utf8')
);

let app;
try { app = getApp(); } catch { app = initializeApp({ credential: cert(serviceAccount) }); }

const rules = `
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── Helper ────────────────────────────────────────────────
    function isAuth() {
      return request.auth != null;
    }

    // Only UIDs that exist in /admins can write sensitive collections
    function isAdmin() {
      return isAuth() &&
             exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    // ── users (mobile app) ────────────────────────────────────
    match /users/{userId} {
      allow read:   if request.auth.uid == userId;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if false;
    }

    // ── reports (mobile app) ──────────────────────────────────
    match /reports/{reportId} {
      allow read:  if isAuth();
      allow write: if isAuth();
    }

    // ── organizations (web admin) ─────────────────────────────
    match /organizations/{orgId} {
      allow read:   if isAdmin();
      allow create: if isAdmin();
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ── admins (web admin) ────────────────────────────────────
    match /admins/{adminId} {
      // Any authenticated user can read their own admin doc (for isAdmin() check)
      allow read:   if isAuth();
      allow create: if isAdmin();
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ── deny everything else ──────────────────────────────────
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
`;

const securityRules = getSecurityRules();

try {
  await securityRules.releaseFirestoreRulesetFromSource(rules);
  console.log('✓ Firestore rules deployed successfully for mybahaya-fyp');
} catch (err) {
  console.error('✗ Failed to deploy rules:', err.message);
  process.exit(1);
}
