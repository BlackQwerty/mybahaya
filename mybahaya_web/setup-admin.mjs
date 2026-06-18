/**
 * setup-admin.mjs — One-time script to create the initial admin user.
 *
 * Run once from the project root:
 *   node mybahaya_web/setup-admin.mjs
 *
 * Requires:  npm install firebase-admin  (in project root)
 */

import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth }             from 'firebase-admin/auth';
import { getFirestore }        from 'firebase-admin/firestore';
import { readFileSync }        from 'fs';
import { fileURLToPath }       from 'url';
import { dirname, join }       from 'path';

const __dir = dirname(fileURLToPath(import.meta.url));
const serviceAccount = JSON.parse(
  readFileSync(join(__dir, '../mybahaya-fyp-firebase-adminsdk-fbsvc-fdac908045.json'), 'utf8')
);

initializeApp({ credential: cert(serviceAccount) });

const authAdmin = getAuth();
const db        = getFirestore();

async function setup() {
  const EMAIL    = 'admin_shukri@gmail.com';
  const PASSWORD = 'abc123';
  const NAME     = 'Ahmad Shukri';

  let uid;

  // Create or fetch Firebase Auth user
  try {
    const existing = await authAdmin.getUserByEmail(EMAIL);
    uid = existing.uid;
    console.log('Auth user already exists:', uid);
  } catch (_) {
    const user = await authAdmin.createUser({
      email:       EMAIL,
      password:    PASSWORD,
      displayName: NAME,
    });
    uid = user.uid;
    console.log('Auth user created:', uid);
  }

  // Write admin document to Firestore
  await db.collection('admins').doc(uid).set({
    name:          NAME,
    email:         EMAIL,
    coverState:    'Melaka',
    coverDistrict: 'Alor Gajah',
    role:          'superadmin',
    uid,
    createdAt:     new Date(),
  }, { merge: true });

  console.log('Firestore admin document written.');
  console.log('\nDone! Login with:');
  console.log('  Email:   ', EMAIL);
  console.log('  Password:', PASSWORD);
  process.exit(0);
}

setup().catch(err => { console.error(err); process.exit(1); });
