/* ============================================================
   report.js — Reports page: clickable cards + detail modal
   ============================================================ */

'use strict';

// const API_BASE = 'https://api.mybahaya.com/api';
const API_BASE = 'http://Shukri-Mac.local:8080/api';
const OLD_MINIO_URL = 'http://178.105.158.80:9000';
const MINIO_BASE_URL = 'http://Shukri-Mac.local:9000';

function safeImageUrl(url) {
  if (!url) return '';
  return url
    .replace(OLD_MINIO_URL, MINIO_BASE_URL)
    .replace('http://minio:9000', MINIO_BASE_URL)
    .replace('http://localhost:9000', MINIO_BASE_URL);
}

/* ── AI Analysis is computed SERVER-SIDE (Spring Boot + Gemini 2.5 Flash).
   The web only DISPLAYS the ai.* fields that the backend writes to Firestore.
   No API key lives in this file — that's the whole point of keeping it secure. ── */

// Renders the inner HTML of the AI Analysis section from an ai object
function renderAiBody(ai) {
  if (!ai || ai.severity == null) return `<p class="rdm-ai-pending">No AI analysis yet.</p>`;
  const severityLabels = { 1: 'Minor', 2: 'Low', 3: 'Moderate', 4: 'High', 5: 'Critical' };
  const severityColors = { 1: '#30d158', 2: '#5b8dee', 3: '#f5a623', 4: '#ff6b35', 5: '#ff3b30' };
  const sc = severityColors[ai.severity] || '#aca494';
  return `
    <div class="rdm-ai-grid">
      <div class="rdm-ai-item">
        <span class="rdm-ai-label">Severity</span>
        <span class="rdm-severity" style="background:${sc}22;color:${sc};border-color:${sc}55">
          ${ai.severity}/5 - ${severityLabels[ai.severity] || 'Unknown'}
        </span>
      </div>
      ${ai.suggestedCategory ? `
      <div class="rdm-ai-item">
        <span class="rdm-ai-label">AI Suggested Category</span>
        <span>${ai.suggestedCategory}</span>
      </div>` : ''}
      ${ai.looksFake ? `
      <div class="rdm-ai-item rdm-ai-fake">
        <ion-icon name="warning-outline"></ion-icon>
        <span>AI flagged this report as possibly fake or staged</span>
      </div>` : ''}
    </div>
    ${ai.summary ? `<p class="rdm-ai-summary">${ai.summary}</p>` : ''}
    ${ai.hazards && ai.hazards.length ? `
    <div class="rdm-hazards">
      ${ai.hazards.map(h => `<span class="rdm-hazard-tag">${h}</span>`).join('')}
    </div>` : ''}
  `;
}

/* ── Status metadata ── */
const STATUS_META = {
  NEW:         { label: 'Pending',     color: '#aca494', icon: 'time-outline' },
  RECEIVED:    { label: 'Received',    color: '#5b8dee', icon: 'checkmark-circle-outline' },
  IN_PROGRESS: { label: 'En Route',    color: '#f5a623', icon: 'car-outline' },
  RESOLVED:    { label: 'Resolved',    color: '#30d158', icon: 'checkmark-done-outline' },
};
const NEXT_STATUS = { NEW: 'RECEIVED', RECEIVED: 'IN_PROGRESS', IN_PROGRESS: 'RESOLVED' };

/* ── Category metadata ── */
const CAT_META = {
  Theft:   { icon: 'lock-open-outline',    label: 'Theft',    cls: 'cat-Theft'   },
  Assault: { icon: 'alert-circle-outline',  label: 'Assault',  cls: 'cat-Assault' },
  Fire:    { icon: 'flame-outline',         label: 'Fire',     cls: 'cat-Fire'    },
  Medical: { icon: 'medkit-outline',        label: 'Medical',  cls: 'cat-Medical' },
  Other:   { icon: 'help-circle-outline',   label: 'Other',    cls: 'cat-Other'   },
};
function catMeta(cat) {
  return CAT_META[cat] || { icon: 'warning-outline', label: cat || 'Unknown', cls: 'cat-Other' };
}

/* ── State bounding boxes ── */
const STATE_BOUNDS = {
  'Perlis':          { minLat:6.10, maxLat:6.80, minLng:100.00, maxLng:100.60 },
  'Kedah':           { minLat:5.50, maxLat:6.80, minLng:99.70,  maxLng:101.00 },
  'Pulau Pinang':    { minLat:5.00, maxLat:5.70, minLng:100.00, maxLng:100.60 },
  'Perak':           { minLat:3.70, maxLat:6.00, minLng:100.20, maxLng:101.80 },
  'Selangor':        { minLat:2.70, maxLat:3.80, minLng:101.00, maxLng:102.00 },
  'Kuala Lumpur':    { minLat:3.00, maxLat:3.30, minLng:101.50, maxLng:101.80 },
  'Putrajaya':       { minLat:2.90, maxLat:3.05, minLng:101.60, maxLng:101.80 },
  'Negeri Sembilan': { minLat:2.40, maxLat:3.30, minLng:101.70, maxLng:102.80 },
  'Melaka':          { minLat:2.00, maxLat:2.50, minLng:102.00, maxLng:102.60 },
  'Johor':           { minLat:1.20, maxLat:2.80, minLng:102.50, maxLng:104.30 },
  'Pahang':          { minLat:2.90, maxLat:5.30, minLng:101.30, maxLng:103.80 },
  'Terengganu':      { minLat:4.00, maxLat:5.90, minLng:102.30, maxLng:103.50 },
  'Kelantan':        { minLat:4.60, maxLat:6.20, minLng:101.30, maxLng:102.50 },
  'Sabah':           { minLat:4.00, maxLat:7.40, minLng:115.50, maxLng:119.30 },
  'Sarawak':         { minLat:0.80, maxLat:5.20, minLng:109.60, maxLng:119.30 },
  'Labuan':          { minLat:5.20, maxLat:5.40, minLng:115.10, maxLng:115.30 },
};

function inState(report, stateName) {
  const b = STATE_BOUNDS[stateName];
  if (!b) return true;
  const lat = report.location?.latitude;
  const lng = report.location?.longitude;
  if (lat == null || lng == null) return false;
  return lat >= b.minLat && lat <= b.maxLat && lng >= b.minLng && lng <= b.maxLng;
}

/* ── Timestamp formatting ── */
function fmtTime(ts) {
  if (!ts) return '-';
  const dt = ts.toDate ? ts.toDate() : new Date(ts);
  const now = Date.now();
  const diff = now - dt.getTime();
  const m = Math.floor(diff / 60000);
  const h = Math.floor(diff / 3600000);
  const d = Math.floor(diff / 86400000);
  if (m < 1) return 'Just now';
  if (m < 60) return `${m}m ago`;
  if (h < 24) return `${h}h ago`;
  if (d < 7)  return `${d}d ago`;
  const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return `${dt.getDate()} ${mo[dt.getMonth()]} ${dt.getFullYear()}`;
}

function fmtFullDate(ts) {
  if (!ts) return '-';
  const dt = ts.toDate ? ts.toDate() : new Date(ts);
  const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const h = dt.getHours().toString().padStart(2, '0');
  const mn = dt.getMinutes().toString().padStart(2, '0');
  return `${dt.getDate()} ${mo[dt.getMonth()]} ${dt.getFullYear()}, ${h}:${mn}`;
}

function shortId(id) { return (id || '').slice(0, 8).toUpperCase(); }

/* ── Reverse geocoding using OpenStreetMap Nominatim (free, no key) ── */
const geoCache = {};
async function reverseGeocode(lat, lng) {
  const key = `${lat.toFixed(5)},${lng.toFixed(5)}`;
  if (geoCache[key]) return geoCache[key];
  try {
    const res = await fetch(`https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&zoom=16&addressdetails=1`, {
      headers: { 'Accept-Language': 'en' }
    });
    const data = await res.json();
    const addr = data.display_name || `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
    geoCache[key] = addr;
    return addr;
  } catch {
    return `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
  }
}

/* ── Update Status (called from modal button) ── */
window.updateReportStatus = async function (reportId, nextStatus) {
  if (!confirm(`Mark report as "${STATUS_META[nextStatus]?.label || nextStatus}"?`)) return;
  try {
    const token = await firebase.auth().currentUser.getIdToken();
    const res = await fetch(`${API_BASE}/reports/${reportId}/status`, {
      method: 'PATCH',
      headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: nextStatus }),
    });
    const data = await res.json();
    if (!data.ok) throw new Error(data.message || 'Update failed');
    window.showToast?.('Status updated to ' + (STATUS_META[nextStatus]?.label || nextStatus), 'success');
    closeDetailModal();
  } catch (e) {
    window.showToast?.('Failed: ' + e.message, 'error');
  }
};

/* ── Verify / Reject report ── */
window.verifyReport = async function (reportId, action) {
  const label = action === 'VERIFIED' ? 'Verify as real' : 'Mark as False Alarm';
  if (!confirm(`${label}? This will be visible to all citizens in the community feed.`)) return;
  try {
    const token = await firebase.auth().currentUser.getIdToken();
    const res = await fetch(`${API_BASE}/reports/${reportId}/verify`, {
      method: 'PATCH',
      headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
      body: JSON.stringify({ action }),
    });
    const data = await res.json();
    if (!data.ok) throw new Error(data.message || 'Failed');
    window.showToast?.(action === 'VERIFIED' ? '✓ Report verified' : '✗ Marked as false alarm', 'success');
    closeDetailModal();
  } catch (e) {
    window.showToast?.('Failed: ' + e.message, 'error');
  }
};

/* ══════════════════════════════════════════════════════════
   DETAIL MODAL — opens when you click a report card
   ══════════════════════════════════════════════════════════ */

function buildMediaPanel(r) {
  const photos = (r.imageUrls && r.imageUrls.length > 0)
    ? r.imageUrls.map(safeImageUrl)
    : (r.imageUrl ? [safeImageUrl(r.imageUrl)] : []);

  const hasVideo = !!r.videoUrl;

  if (!photos.length && !hasVideo) {
    const m = catMeta(r.category);
    return `<div class="rdm-image-placeholder"><ion-icon name="${m.icon}"></ion-icon></div>`;
  }

  const items = [
    ...photos.map(url => ({ type: 'photo', url })),
    ...(hasVideo ? [{ type: 'video', url: safeImageUrl(r.videoUrl) }] : []),
  ];

  const first = items[0];
  const showStrip = items.length > 1;

  const mainHtml = first.type === 'photo'
    ? `<img class="rdm-main-media" src="${first.url}" alt="Report photo" />`
    : `<video class="rdm-main-media" src="${first.url}" controls></video>`;

  const stripHtml = showStrip ? `
    <div class="rdm-thumb-strip">
      ${items.map((item, i) => `
        <div class="rdm-thumb${i === 0 ? ' active' : ''}" data-type="${item.type}" data-url="${item.url}">
          ${item.type === 'photo'
            ? `<img src="${item.url}" alt="Photo ${i + 1}" />`
            : `<span class="rdm-thumb-video-icon"><ion-icon name="play-circle-outline"></ion-icon></span>`
          }
        </div>`).join('')}
    </div>` : '';

  return `<div class="rdm-main-area">${mainHtml}</div>${stripHtml}`;
}

function wireMediaThumbs(modal) {
  modal.querySelectorAll('.rdm-thumb').forEach(thumb => {
    thumb.addEventListener('click', () => {
      modal.querySelectorAll('.rdm-thumb').forEach(t => t.classList.remove('active'));
      thumb.classList.add('active');
      const area = modal.querySelector('.rdm-main-area');
      const { type, url } = thumb.dataset;
      if (type === 'photo') {
        area.innerHTML = `<img class="rdm-main-media" src="${url}" alt="Report photo" />`;
      } else {
        area.innerHTML = `<video class="rdm-main-media" src="${url}" controls autoplay></video>`;
      }
    });
  });
}

function openDetailModal(r) {
  // Remove any existing modal
  document.getElementById('report-detail-modal')?.remove();

  const m = catMeta(r.category);
  const s = STATUS_META[r.status] || STATUS_META.NEW;
  const lat = r.location?.latitude;
  const lng = r.location?.longitude;
  const hasLoc = lat != null && lng != null;
  const next = NEXT_STATUS[r.status];
  const ai = r.ai || {};
  const hasSeverity = ai.severity != null;

  const modal = document.createElement('div');
  modal.id = 'report-detail-modal';
  modal.className = 'rdm-overlay';
  modal.innerHTML = `
    <div class="rdm-backdrop"></div>
    <div class="rdm-card">

      <!-- Close button -->
      <button class="rdm-close" id="rdm-close-btn">
        <ion-icon name="close-outline"></ion-icon>
      </button>

      <!-- Media (photos gallery + optional video) -->
      <div class="rdm-image">
        ${buildMediaPanel(r)}
      </div>

      <!-- Content -->
      <div class="rdm-content">

        <!-- Header: Category + Status -->
        <div class="rdm-header">
          <div class="rdm-badges">
            <span class="rdm-cat-badge ${m.cls}"><ion-icon name="${m.icon}"></ion-icon> ${m.label}</span>
            <span class="rdm-status-badge" style="background:${s.color}22;color:${s.color};border-color:${s.color}55">
              <ion-icon name="${s.icon}"></ion-icon> ${s.label}
            </span>
          </div>
          <span class="rdm-report-id">#${shortId(r.reportId || r.id)}</span>
        </div>

        <!-- Assigned org -->
        ${r.assignedOrgName ? `
        <div class="rdm-org-row">
          <ion-icon name="business-outline"></ion-icon>
          <span>${r.assignedOrgName}</span>
          ${(r.etaMinutes && r.status !== 'RESOLVED') ? `<span class="rdm-eta">ETA ~${r.etaMinutes} min</span>` : ''}
        </div>` : ''}

        <!-- Details -->
        <div class="rdm-section">
          <div class="rdm-section-label">Incident Details</div>
          <p class="rdm-details-text">${r.details || 'No description provided.'}</p>
        </div>

        <!-- AI Analysis -->
        <div class="rdm-section rdm-ai-section">
          <div class="rdm-section-label"><ion-icon name="sparkles-outline"></ion-icon> AI Analysis</div>
          <div id="rdm-ai-body">${
            hasSeverity
              ? renderAiBody(ai)
              : `<p class="rdm-ai-pending">AI analysis is processing or not yet available for this report.</p>`
          }</div>
        </div>

        <!-- Location -->
        <div class="rdm-section">
          <div class="rdm-section-label"><ion-icon name="location-outline"></ion-icon> Location</div>
          ${hasLoc ? `<p class="rdm-location-text" id="rdm-location-addr">Loading address...</p>` : `<p class="rdm-location-text">No location data</p>`}
        </div>

        <!-- Timestamp -->
        <div class="rdm-section">
          <div class="rdm-section-label"><ion-icon name="time-outline"></ion-icon> Reported</div>
          <p class="rdm-time">${fmtFullDate(r.createdAt)}</p>
        </div>

        <!-- Verification (only shown while PENDING) -->
        ${(!r.verificationStatus || r.verificationStatus === 'PENDING') ? `
        <div class="rdm-verify-row">
          <span class="rdm-verify-label"><ion-icon name="shield-checkmark-outline"></ion-icon> Verification</span>
          <div class="rdm-verify-btns">
            <button class="rdm-verify-btn rdm-verify-yes" onclick="verifyReport('${r.reportId || r.id}','VERIFIED')">
              <ion-icon name="checkmark-circle-outline"></ion-icon> Confirm Real
            </button>
            <button class="rdm-verify-btn rdm-verify-no" onclick="verifyReport('${r.reportId || r.id}','REJECTED')">
              <ion-icon name="close-circle-outline"></ion-icon> False Alarm
            </button>
          </div>
        </div>` : `
        <div class="rdm-verify-badge ${r.verificationStatus === 'VERIFIED' ? 'rdm-vb-verified' : 'rdm-vb-rejected'}">
          <ion-icon name="${r.verificationStatus === 'VERIFIED' ? 'shield-checkmark-outline' : 'warning-outline'}"></ion-icon>
          ${r.verificationStatus === 'VERIFIED' ? 'Verified - Confirmed real incident' : 'False Alarm - This report was rejected'}
        </div>`}

        <!-- Status Update Button -->
        ${next ? `
        <button class="rdm-update-btn" onclick="updateReportStatus('${r.reportId || r.id}','${next}')">
          <ion-icon name="${STATUS_META[next].icon}"></ion-icon> Mark as ${STATUS_META[next].label}
        </button>` : `
        <div class="rdm-resolved-banner">
          <ion-icon name="checkmark-done-outline"></ion-icon> This report has been resolved
        </div>`}
      </div>
    </div>`;

  document.body.appendChild(modal);
  requestAnimationFrame(() => modal.classList.add('open'));

  // Close handlers
  modal.querySelector('.rdm-backdrop').addEventListener('click', closeDetailModal);
  modal.querySelector('#rdm-close-btn').addEventListener('click', closeDetailModal);
  document.addEventListener('keydown', handleEsc);

  // Wire photo/video thumbnail strip
  wireMediaThumbs(modal);

  // Reverse geocode
  if (hasLoc) {
    reverseGeocode(lat, lng).then(addr => {
      const el = document.getElementById('rdm-location-addr');
      if (el) el.textContent = addr;
    });
  }
}

function closeDetailModal() {
  const modal = document.getElementById('report-detail-modal');
  if (!modal) return;
  modal.classList.remove('open');
  setTimeout(() => modal.remove(), 250);
  document.removeEventListener('keydown', handleEsc);
}

function handleEsc(e) { if (e.key === 'Escape') closeDetailModal(); }

/* ── Render report grid cards (clickable) ── */
function renderReports(reports) {
  const grid  = document.getElementById('reports-grid');
  const empty = document.getElementById('empty-state');
  const badge = document.getElementById('total-count-badge');
  badge.textContent = `${reports.length} report${reports.length !== 1 ? 's' : ''}`;

  if (!reports.length) {
    grid.innerHTML = '';
    empty.classList.remove('hidden');
    return;
  }
  empty.classList.add('hidden');

  grid.innerHTML = reports.map((r, i) => {
    const m = catMeta(r.category);
    const s = STATUS_META[r.status] || STATUS_META.NEW;

    return `
    <div class="glass-card report-card fade-in" style="animation-delay:${i * 0.04}s;cursor:pointer" role="listitem" data-idx="${i}">
      <div class="rc-image-bg">
        ${r.imageUrl
          ? `<img src="${safeImageUrl(r.imageUrl)}" alt="${m.label}" loading="lazy" />`
          : `<div class="rc-image-placeholder"><ion-icon name="${m.icon}" class="cat-icon-${r.category || 'Other'}"></ion-icon></div>`
        }
      </div>
      <div class="rc-detail-panel">
        <div class="rc-id">#${shortId(r.reportId || r.id)}</div>
        <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-bottom:4px">
          <div class="rc-title" style="margin:0">${m.label}</div>
          <span style="font-size:10px;font-weight:700;letter-spacing:.5px;padding:3px 9px;border-radius:20px;background:${s.color}22;color:${s.color};border:1px solid ${s.color}55">${s.label.toUpperCase()}</span>
        </div>
        <div class="rc-details-label">Details:</div>
        <p class="rc-desc${!r.details ? ' no-desc' : ''}">${r.details || 'No description provided.'}</p>
        <span class="rc-time">${fmtTime(r.createdAt)}</span>
      </div>
    </div>`;
  }).join('');

  // Attach click handlers
  grid.querySelectorAll('.report-card').forEach(card => {
    card.addEventListener('click', () => {
      const idx = parseInt(card.dataset.idx);
      openDetailModal(reports[idx]);
    });
  });
}

/* ── Filter & sort state ── */
let allReports   = [];
let currentScope = 'malaysia';
let currentState = '';
let currentCat   = 'all';
let currentSearch = '';
let currentSort  = 'newest';

function applyFilters() {
  let list = allReports.filter(r => {
    if (currentScope === 'state' && currentState) {
      if (!inState(r, currentState)) return false;
    }
    if (currentCat !== 'all' && r.category !== currentCat) return false;
    if (currentSearch) {
      const q = currentSearch.toLowerCase();
      const hay = [r.category, r.details, r.reportId, r.id].join(' ').toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });

  list = list.slice().sort((a, b) => {
    const ta = a.createdAt?.toMillis?.() ?? 0;
    const tb = b.createdAt?.toMillis?.() ?? 0;
    return currentSort === 'oldest' ? ta - tb : tb - ta;
  });

  renderReports(list);
}

// play alert sound function for new reports entered
function playAlertSound(times = 3) {
  if (typeof window.playAlertSound === 'function') {
    window.playAlertSound(times);
  } else {
    const audio = new Audio('assets/sounds/chime-sounds.mp3');
    audio.volume = 1;
    audio.play().catch(error => {
      console.warn('Browser blocked audio playback: ', error);
    });
  }
}

/* ── Firestore listener ── */
function listenReports() {
  const loading = document.getElementById('reports-loading');

  // Admins see all reports; org users see only reports assigned to their org.
  let query = db.collection('reports');
  const org = window.currentUserOrg;
  if (org && !window.currentUserIsAdmin) {
    query = query.where('assignedOrgId', '==', org.id);
  }

  // Track IDs and statuses that are already known — prevents sound from firing on initial load or duplicate events
  const seenIds = new Set();
  const seenStatusUpdates = new Set();
  let initialLoadDone = false;

  query.onSnapshot(snap => {
    loading.classList.add('hidden');
    console.log(`[MyBahaya ReportCentre] Snapshot received: ${snap.docs.length} docs, ${snap.docChanges().length} doc changes`);

    allReports = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    const docChanges = snap.docChanges();

    if (!initialLoadDone) {
      // First snapshot: mark all existing documents as seen, don't play sound
      snap.docs.forEach(d => {
        seenIds.add(d.id);
        const data = d.data() || {};
        seenStatusUpdates.add(`${d.id}_${data.status}`);
      });
      initialLoadDone = true;
      console.log(`[MyBahaya ReportCentre] Initial snapshot recorded with ${seenIds.size} existing reports.`);
    } else {
      // Find newly added reports OR existing reports whose status changed to RECEIVED or NEW
      const newDocs = [];

      docChanges.forEach(change => {
        const id = change.doc.id;
        const data = change.doc.data() || {};

        if (change.type === 'added' && !seenIds.has(id)) {
          seenIds.add(id);
          seenStatusUpdates.add(`${id}_${data.status}`);
          newDocs.push({ id, data, isNew: true });
        } else if (change.type === 'modified') {
          const statusKey = `${id}_${data.status}`;
          if ((data.status === 'RECEIVED' || data.status === 'NEW') && !seenStatusUpdates.has(statusKey)) {
            seenStatusUpdates.add(statusKey);
            newDocs.push({ id, data, isNew: false });
          }
        }
      });

      if (newDocs.length > 0) {
        console.log(`[MyBahaya ReportCentre] 🚨 ${newDocs.length} real-time report event(s) detected! Triggering alert sound...`);
        playAlertSound(3);
        const first = newDocs[0].data;
        const cat = first.category || 'Incident';
        const actionWord = newDocs[0].isNew ? 'received' : 'updated to Received';
        if (typeof showToast === 'function') {
          showToast(`🚨 New ${cat} report ${actionWord} in real time!`, 'info', 5000);
        }
      }
    }

    applyFilters();
  }, err => {
    loading.innerHTML = `<ion-icon name="alert-circle-outline" style="font-size:20px;color:var(--accent-rose)"></ion-icon>
      <span style="color:var(--accent-rose)">Failed to load: ${err.message}</span>`;
    console.error('[MyBahaya ReportCentre] Listener error:', err);
  });
}

/* ── Filter UI wiring ── */
function initFilters() {
  document.getElementById('report-search').addEventListener('input', e => {
    currentSearch = e.target.value.trim();
    applyFilters();
  });

  document.querySelectorAll('[data-scope]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('[data-scope]').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentScope = btn.dataset.scope;
      const stateSelect = document.getElementById('state-select');
      if (currentScope === 'state') {
        stateSelect.classList.remove('hidden');
      } else {
        stateSelect.classList.add('hidden');
        currentState = '';
      }
      applyFilters();
    });
  });

  document.getElementById('state-select').addEventListener('change', e => {
    currentState = e.target.value;
    applyFilters();
  });

  document.querySelectorAll('[data-cat]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('[data-cat]').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentCat = btn.dataset.cat;
      applyFilters();
    });
  });

  document.getElementById('report-sort').addEventListener('change', e => {
    currentSort = e.target.value;
    applyFilters();
  });

  document.getElementById('btn-clear-filter').addEventListener('click', () => {
    document.getElementById('report-search').value = '';
    currentSearch = ''; currentCat = 'all'; currentScope = 'malaysia';
    currentState  = ''; currentSort = 'newest';
    document.querySelectorAll('[data-scope]').forEach(b => b.classList.remove('active'));
    document.querySelector('[data-scope="malaysia"]').classList.add('active');
    document.querySelectorAll('[data-cat]').forEach(b => b.classList.remove('active'));
    document.querySelector('[data-cat="all"]').classList.add('active');
    document.getElementById('state-select').classList.add('hidden');
    document.getElementById('state-select').value = '';
    document.getElementById('report-sort').value = 'newest';
    applyFilters();
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initFilters();
  // Wait until auth.js resolves the role so the org filter is in place.
  (window.authReady || Promise.resolve()).then(listenReports);
});
