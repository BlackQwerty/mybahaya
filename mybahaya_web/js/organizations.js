/* ============================================================
   organizations.js — Organizations & Admins page logic
   Firestore collections: /organizations  /admins
   ============================================================ */

'use strict';

// Firebase Web API key (same project as firebase-config.js)
const FIREBASE_API_KEY = 'AIzaSyCw63F4hFRDHGAXhhAlZJ-cT8M643MSisw';

/* ── Helpers ─────────────────────────────────────────────── */

const TYPE_META = {
  police:     { label: 'Police',           icon: 'shield-outline',   css: 'org-type-police'     },
  fire:       { label: 'Fire Department',  icon: 'flame-outline',    css: 'org-type-fire'       },
  medical:    { label: 'Medical',          icon: 'medkit-outline',   css: 'org-type-medical'    },
  government: { label: 'Government',       icon: 'business-outline', css: 'org-type-government' },
  civilian:   { label: 'Civilian Defense', icon: 'people-outline',   css: 'org-type-civilian'   },
};

const ORG_PALETTE = ['#5b8dee','#f05f7e','#30d158','#aca494','#f5a623','#32d4b4'];
function avatarColor(str) {
  let h = 0;
  for (let i = 0; i < str.length; i++) h = str.charCodeAt(i) + ((h << 5) - h);
  return ORG_PALETTE[Math.abs(h) % ORG_PALETTE.length];
}

function showEl(id)  { document.getElementById(id)?.classList.remove('hidden'); }
function hideEl(id)  { document.getElementById(id)?.classList.add('hidden'); }

function showFormErr(id, msg) {
  const el = document.getElementById(id);
  if (!el) return;
  el.textContent = msg;
  el.classList.remove('hidden');
}
function clearFormErr(id) { hideEl(id); }

function setSubmitting(btnId, yes, defaultHtml) {
  const btn = document.getElementById(btnId);
  if (!btn) return;
  btn.disabled = yes;
  if (yes) {
    btn.innerHTML = '<span class="btn-spinner"></span> Saving…';
  } else {
    btn.innerHTML = defaultHtml;
  }
}

/* ── Create Firebase Auth user WITHOUT signing in ────────── */
// Uses the Identity REST API so the current admin session is preserved.
async function createAuthUserREST(email, password) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FIREBASE_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: false }),
    }
  );
  const data = await res.json();
  if (data.error) {
    const msgs = {
      'EMAIL_EXISTS':          'This email is already registered.',
      'WEAK_PASSWORD':         'Password must be at least 6 characters.',
      'INVALID_EMAIL':         'Invalid email address.',
      'OPERATION_NOT_ALLOWED': 'Email/password sign-in is not enabled.',
    };
    throw new Error(msgs[data.error.message] || data.error.message);
  }
  return data.localId; // Firebase Auth UID
}

/* ── Send password reset / setup email via REST ─────────── */
// Org receives this email to set their own password for the first time.
async function sendPasswordResetREST(email) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${FIREBASE_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ requestType: 'PASSWORD_RESET', email }),
    }
  );
  const data = await res.json();
  if (data.error) throw new Error(data.error.message);
}

/* ── Random temp password (org never uses it — reset email replaces it) ── */
function genTempPassword() {
  return Math.random().toString(36).slice(2, 10) +
         Math.random().toString(36).slice(2, 6).toUpperCase() + '!9';
}

/* ── Tab switching ───────────────────────────────────────── */

function initTabs() {
  const tabBtns    = document.querySelectorAll('.tab-btn');
  const addLabel   = document.getElementById('btn-add-label');
  const addPrimary = document.getElementById('btn-add-primary');

  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      tabBtns.forEach(b => { b.classList.remove('active'); b.setAttribute('aria-selected', 'false'); });
      btn.classList.add('active');
      btn.setAttribute('aria-selected', 'true');

      const target = btn.dataset.tab;
      document.querySelectorAll('.tab-content').forEach(tc => tc.classList.remove('active'));
      document.getElementById('tab-' + target)?.classList.add('active');

      if (target === 'admins') {
        addLabel.textContent = 'Add Admin';
        addPrimary.onclick = openAdminModal;
      } else {
        addLabel.textContent = 'Add Organization';
        addPrimary.onclick = openOrgModal;
      }
    });
  });

  addPrimary.addEventListener('click', openOrgModal);
}

/* ══════════════════════════════════════════════════════════
   ORGANIZATIONS
   ══════════════════════════════════════════════════════════ */

let allOrgs = [];

function renderOrgs(orgs) {
  const tbody = document.getElementById('org-table-body');
  hideEl('org-loading');

  if (!orgs.length) {
    hideEl('org-table-wrap');
    showEl('org-empty');
    return;
  }
  hideEl('org-empty');
  showEl('org-table-wrap');

  const meta = t => TYPE_META[t] || { label: t, icon: 'business-outline', css: '' };

  tbody.innerHTML = orgs.map(o => {
    const m = meta(o.type);
    return `
    <tr>
      <td>
        <div class="org-profile">
          <div class="org-avatar" style="background:${avatarColor(o.name)}">
            <ion-icon name="${m.icon}"></ion-icon>
          </div>
          <div class="org-info">
            <span class="org-name">${o.name}</span>
            <span class="org-contact-email">${o.district || ''}, ${o.state || ''}</span>
          </div>
        </div>
      </td>
      <td><span class="org-type-badge ${m.css}"><ion-icon name="${m.icon}"></ion-icon> ${m.label}</span></td>
      <td style="font-size:var(--fs-xs);color:rgba(255,255,255,0.65)">${o.district || ''}, ${o.state || ''} ${o.postcode || ''}</td>
      <td style="font-size:var(--fs-xs);color:rgba(255,255,255,0.65)">${o.email || ''}</td>
      <td><span class="status-${o.status}"><span class="dot-indicator"></span>${o.status === 'active' ? 'Active' : 'Inactive'}</span></td>
      <td>
        <div class="table-actions">
          <button class="btn-action" title="Resend Setup Email" onclick="resendOrgSetup('${o.email}','${o.name.replace(/'/g,"\\'")}')"><ion-icon name="mail-outline"></ion-icon></button>
          <button class="btn-action" title="Edit" onclick="editOrg('${o.id}')"><ion-icon name="create-outline"></ion-icon></button>
          <button class="btn-action delete" title="Delete" onclick="deleteOrg('${o.id}','${o.name.replace(/'/g,"\\'")}')"><ion-icon name="trash-outline"></ion-icon></button>
        </div>
      </td>
    </tr>`;
  }).join('');
}

function updateOrgCounts(orgs) {
  document.getElementById('org-count-total').textContent    = orgs.length;
  document.getElementById('org-count-active').textContent   = orgs.filter(o => o.status === 'active').length;
  document.getElementById('org-count-inactive').textContent = orgs.filter(o => o.status === 'inactive').length;
}

function filterOrgs() {
  const q = (document.getElementById('org-search')?.value || '').toLowerCase();
  const t = document.getElementById('org-type-filter')?.value || 'all';
  const filtered = allOrgs.filter(o =>
    (t === 'all' || o.type === t) &&
    (o.name?.toLowerCase().includes(q) ||
     o.district?.toLowerCase().includes(q) ||
     o.email?.toLowerCase().includes(q) ||
     o.state?.toLowerCase().includes(q))
  );
  renderOrgs(filtered);
}

function listenOrgs() {
  // No orderBy — avoids index-building delay and pending-timestamp double-fire.
  // Sort client-side instead.
  db.collection('organizations').onSnapshot(snap => {
    allOrgs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    // Sort newest first (handle pending server timestamps gracefully)
    allOrgs.sort((a, b) => {
      const ta = a.createdAt?.toMillis?.() ?? 0;
      const tb = b.createdAt?.toMillis?.() ?? 0;
      return tb - ta;
    });
    filterOrgs();
    updateOrgCounts(allOrgs);
  }, err => {
    console.error('Orgs listener error:', err);
    hideEl('org-loading');
    showEl('org-empty');
    window.showToast?.('Failed to load organizations.', 'error');
  });
}

/* ── Org Modal ── */

function openOrgModal() {
  document.getElementById('org-form').reset();
  clearFormErr('org-form-error');
  document.getElementById('modal-org-title').innerHTML = '<span class="dot"></span> Add New Organization';
  document.getElementById('org-submit-btn').innerHTML  = 'Register Organization <ion-icon name="checkmark-outline"></ion-icon>';
  document.getElementById('modal-org')._editId = null;
  document.getElementById('modal-org').classList.remove('hidden');
}

window.editOrg = async function (id) {
  const snap = await db.collection('organizations').doc(id).get();
  if (!snap.exists) return;
  const o = snap.data();

  document.getElementById('o-name').value     = o.name        || '';
  document.getElementById('o-type').value     = o.type        || '';
  document.getElementById('o-status').value   = o.status      || 'active';
  document.getElementById('o-state').value    = o.state       || '';
  document.getElementById('o-district').value = o.district    || '';
  document.getElementById('o-postcode').value = o.postcode    || '';
  document.getElementById('o-address').value  = o.fullAddress || '';
  document.getElementById('o-email').value    = o.email       || '';
  document.getElementById('o-lat').value      = o.latitude    ?? '';
  document.getElementById('o-lng').value      = o.longitude   ?? '';

  document.getElementById('modal-org-title').innerHTML = '<span class="dot"></span> Edit Organization';
  document.getElementById('org-submit-btn').innerHTML  = 'Save Changes <ion-icon name="checkmark-outline"></ion-icon>';
  document.getElementById('modal-org')._editId = id;
  clearFormErr('org-form-error');
  document.getElementById('modal-org').classList.remove('hidden');
};

window.deleteOrg = async function (id, name) {
  if (!confirm(`Delete "${name}"?\nThis cannot be undone.`)) return;
  try {
    await db.collection('organizations').doc(id).delete();
    window.showToast?.(`"${name}" deleted.`, 'info');
  } catch (e) {
    window.showToast?.('Delete failed: ' + e.message, 'error');
  }
};

/* ── Resend password setup email to an existing org ─────── */
window.resendOrgSetup = async function (email, name) {
  if (!email) { window.showToast?.('No email on record for this organization.', 'error'); return; }
  if (!confirm(`Resend password setup email to:\n${email}\n\nThe organization will receive a link to set their password.`)) return;
  try {
    await sendPasswordResetREST(email);
    window.showToast?.(`Setup email resent to ${email}.`, 'success');
  } catch (err) {
    window.showToast?.('Failed to send email: ' + err.message, 'error');
  }
};

function initOrgModal() {
  const modal  = document.getElementById('modal-org');
  const form   = document.getElementById('org-form');
  const close  = document.getElementById('modal-close-org');
  const cancel = document.getElementById('modal-cancel-org');

  const closeModal = () => modal.classList.add('hidden');
  close.addEventListener('click', closeModal);
  cancel.addEventListener('click', closeModal);
  modal.addEventListener('click', e => { if (e.target === modal) closeModal(); });

  form.addEventListener('submit', async e => {
    e.preventDefault();
    clearFormErr('org-form-error');

    const name        = document.getElementById('o-name').value.trim();
    const type        = document.getElementById('o-type').value;
    const status      = document.getElementById('o-status').value;
    const state       = document.getElementById('o-state').value;
    const district    = document.getElementById('o-district').value.trim();
    const postcode    = document.getElementById('o-postcode').value.trim();
    const fullAddress = document.getElementById('o-address').value.trim();
    const email       = document.getElementById('o-email').value.trim();
    const lat         = parseFloat(document.getElementById('o-lat').value);
    const lng         = parseFloat(document.getElementById('o-lng').value);

    if (!name || !type || !state || !district || !postcode || !fullAddress || !email) {
      showFormErr('org-form-error', 'Please fill in all required fields.'); return;
    }
    if (isNaN(lat) || isNaN(lng)) {
      showFormErr('org-form-error', 'Enter valid latitude and longitude coordinates.'); return;
    }

    const SAVE_BTN_HTML = 'Register Organization <ion-icon name="checkmark-outline"></ion-icon>';
    setSubmitting('org-submit-btn', true, SAVE_BTN_HTML);

    const data = {
      name, type, status, state, district, postcode, fullAddress, email,
      latitude: lat, longitude: lng,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    };

    try {
      const editId = modal._editId;
      if (editId) {
        // Edit: update Firestore only (auth account already exists)
        await db.collection('organizations').doc(editId).update(data);
        window.showToast?.(`"${name}" updated successfully.`, 'success');
      } else {
        // New org: create Firebase Auth account → send setup email → save to Firestore
        const uid = await createAuthUserREST(email, genTempPassword());
        data.uid = uid;
        data.role = 'organization';
        data.createdAt = firebase.firestore.FieldValue.serverTimestamp();
        await db.collection('organizations').doc(uid).set(data);
        await sendPasswordResetREST(email);
        window.showToast?.(
          `"${name}" registered. Password setup email sent to ${email}.`,
          'success'
        );
      }
      closeModal();
    } catch (err) {
      showFormErr('org-form-error', err.message);
      window.showToast?.('Save failed: ' + err.message, 'error');
    } finally {
      setSubmitting('org-submit-btn', false, SAVE_BTN_HTML);
    }
  });
}

/* ══════════════════════════════════════════════════════════
   ADMINS
   ══════════════════════════════════════════════════════════ */

let allAdmins = [];

function renderAdmins(admins) {
  const tbody = document.getElementById('admin-table-body');
  hideEl('admin-loading');

  if (!admins.length) {
    hideEl('admin-table-wrap');
    showEl('admin-empty');
    return;
  }
  hideEl('admin-empty');
  showEl('admin-table-wrap');

  tbody.innerHTML = admins.map(a => `
    <tr>
      <td>
        <div class="org-profile">
          <div class="org-avatar" style="background:${avatarColor(a.name || a.email)};font-size:18px;font-weight:700">
            ${(a.name || a.email || '?').charAt(0).toUpperCase()}
          </div>
          <div class="org-info">
            <span class="org-name">${a.name || '—'}</span>
            <span class="org-contact-email">${a.role === 'superadmin' ? '⭐ Super Admin' : 'Admin'}</span>
          </div>
        </div>
      </td>
      <td style="font-size:var(--fs-xs);color:rgba(255,255,255,0.65)">${a.email || '—'}</td>
      <td style="font-size:var(--fs-sm)">${a.coverState || '—'}</td>
      <td style="font-size:var(--fs-sm)">${a.coverDistrict || '—'}</td>
      <td>
        <div class="table-actions">
          <button class="btn-action delete" title="Remove Admin"
            onclick="deleteAdmin('${a.id}','${(a.name||a.email||'').replace(/'/g,"\\'")}')">
            <ion-icon name="ban-outline"></ion-icon>
          </button>
        </div>
      </td>
    </tr>
  `).join('');
}

function updateAdminCounts(admins) {
  document.getElementById('admin-count-total').textContent  = admins.length;
  const states = new Set(admins.map(a => a.coverState).filter(Boolean));
  document.getElementById('admin-count-states').textContent = states.size;
}

function filterAdmins() {
  const q = (document.getElementById('admin-search')?.value || '').toLowerCase();
  const filtered = allAdmins.filter(a =>
    (a.name || '').toLowerCase().includes(q) ||
    (a.email || '').toLowerCase().includes(q) ||
    (a.coverState || '').toLowerCase().includes(q)
  );
  renderAdmins(filtered);
}

function listenAdmins() {
  db.collection('admins').onSnapshot(snap => {
    allAdmins = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    allAdmins.sort((a, b) => {
      const ta = a.createdAt?.toMillis?.() ?? 0;
      const tb = b.createdAt?.toMillis?.() ?? 0;
      return tb - ta;
    });
    filterAdmins();
    updateAdminCounts(allAdmins);
  }, err => {
    console.error('Admins listener error:', err);
    hideEl('admin-loading');
    showEl('admin-empty');
    window.showToast?.('Failed to load admins.', 'error');
  });
}

/* ── Admin Modal ── */

function openAdminModal() {
  document.getElementById('admin-form').reset();
  clearFormErr('admin-form-error');
  document.getElementById('modal-admin').classList.remove('hidden');
}

window.deleteAdmin = async function (id, name) {
  if (!confirm(`Remove admin "${name}"?\nThis only removes their Firestore record. Their login account remains.`)) return;
  try {
    await db.collection('admins').doc(id).delete();
    window.showToast?.(`Admin "${name}" removed.`, 'info');
  } catch (e) {
    window.showToast?.('Delete failed: ' + e.message, 'error');
  }
};

function initAdminModal() {
  const modal  = document.getElementById('modal-admin');
  const form   = document.getElementById('admin-form');
  const close  = document.getElementById('modal-close-admin');
  const cancel = document.getElementById('modal-cancel-admin');

  const closeModal = () => modal.classList.add('hidden');
  close.addEventListener('click', closeModal);
  cancel.addEventListener('click', closeModal);
  modal.addEventListener('click', e => { if (e.target === modal) closeModal(); });

  form.addEventListener('submit', async e => {
    e.preventDefault();
    clearFormErr('admin-form-error');

    const name     = document.getElementById('a-name').value.trim();
    const email    = document.getElementById('a-email').value.trim();
    const password = document.getElementById('a-password').value;
    const state    = document.getElementById('a-state').value;
    const district = document.getElementById('a-district').value.trim();

    if (!name || !email || !password || !state || !district) {
      showFormErr('admin-form-error', 'Please fill in all required fields.'); return;
    }
    if (password.length < 6) {
      showFormErr('admin-form-error', 'Password must be at least 6 characters.'); return;
    }

    const SAVE_BTN_HTML = 'Create Admin <ion-icon name="checkmark-outline"></ion-icon>';
    setSubmitting('admin-submit-btn', true, SAVE_BTN_HTML);

    try {
      // Create Firebase Auth account via REST — does NOT change the current session
      const uid = await createAuthUserREST(email, password);

      // Write the admin profile to Firestore (still signed in as original admin)
      await db.collection('admins').doc(uid).set({
        name, email,
        coverState:    state,
        coverDistrict: district,
        role:          'admin',
        uid,
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      });

      window.showToast?.(`Admin "${name}" created successfully.`, 'success');
      closeModal();
    } catch (err) {
      showFormErr('admin-form-error', err.message);
      window.showToast?.(err.message, 'error');
    } finally {
      setSubmitting('admin-submit-btn', false, SAVE_BTN_HTML);
    }
  });
}

/* ── Init ────────────────────────────────────────────────── */

document.addEventListener('DOMContentLoaded', () => {
  initTabs();
  initOrgModal();
  initAdminModal();

  listenOrgs();
  listenAdmins();

  document.getElementById('org-search')?.addEventListener('input', filterOrgs);
  document.getElementById('org-type-filter')?.addEventListener('change', filterOrgs);
  document.getElementById('admin-search')?.addEventListener('input', filterAdmins);
});
