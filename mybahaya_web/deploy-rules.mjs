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

    // ── Helpers ───────────────────────────────────────────────
    function isAuth() {
      return request.auth != null;
    }

    // Admin = has the 'admin' custom claim on their token, OR (fallback during
    // migration) a doc in /admins. The claim is set by migrate-lockdown.js.
    function isAdmin() {
      return isAuth() && (
        request.auth.token.role == 'admin' ||
        exists(/databases/$(database)/documents/admins/$(request.auth.uid))
      );
    }

    // Org = has the 'org' custom claim; token.orgId is their organization doc id.
    function isOrg() {
      return isAuth() && request.auth.token.role == 'org';
    }

    // ── users (mobile app) ────────────────────────────────────
    match /users/{userId} {
      allow read:   if request.auth.uid == userId;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if false;
    }

    // ── reports (LOCKED case records) ─────────────────────────
    // Full report with reporter identity, assignment, status, AI analysis.
    //  • admin   → every report
    //  • org     → only reports assigned to that org (assignedOrgId == token.orgId)
    //  • citizen → only reports they filed themselves (userId == their uid)
    // Writes are backend-only: the Spring Boot server uses the Admin SDK, which
    // bypasses these rules. No client (mobile or web) writes reports directly.
    match /reports/{reportId} {
      allow read: if isAdmin()
                  || (isOrg() && resource.data.assignedOrgId == request.auth.token.orgId)
                  || (isAuth() && resource.data.userId == request.auth.uid);
      allow write: if false;
    }

    // ── public_incidents (community feed) ─────────────────────
    // Sanitized incident facts only (category, details, image, location, time).
    // No reporter identity, no assignment, no status. Safe for everyone to see
    // on the mobile community map / feed / alerts. Backend-only writes.
    match /public_incidents/{id} {
      allow read:  if isAuth();
      allow write: if false;
    }

    // ── organizations ─────────────────────────────────────────
    match /organizations/{orgId} {
      // Any authenticated user can read org info (an org account looks itself
      // up by authUid at login). Org directory data is not sensitive.
      allow read:   if isAuth();
      allow create: if isAdmin();
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ── admins ────────────────────────────────────────────────
    match /admins/{adminId} {
      allow read:   if isAuth();   // needed for the isAdmin() exists() fallback
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
