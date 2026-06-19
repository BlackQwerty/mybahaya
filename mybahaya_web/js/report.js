/* ============================================================
   report.js — Reports page: real Firestore data, 2-layer filter
   Firestore schema (set by Spring Boot):
     reports/{reportId}: { reportId, userId, category, details,
       imageUrl, location:{latitude,longitude}, createdAt }
   ============================================================ */

'use strict';

/* ── Category metadata ── */
const CAT_META = {
  Theft:   { icon: 'lock-open-outline',           label: 'Theft',   cls: 'cat-Theft'   },
  Assault: { icon: 'alert-circle-outline',         label: 'Assault', cls: 'cat-Assault' },
  Fire:    { icon: 'flame-outline',               label: 'Fire',    cls: 'cat-Fire'    },
  Medical: { icon: 'medkit-outline',              label: 'Medical', cls: 'cat-Medical' },
  Other:   { icon: 'help-circle-outline',         label: 'Other',   cls: 'cat-Other'   },
};
function catMeta(cat) {
  return CAT_META[cat] || { icon: 'warning-outline', label: cat || 'Unknown', cls: 'cat-Other' };
}

/* ── Malaysian state bounding boxes (rough, for client-side geo filter) ── */
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
  if (!b) return true; // unknown state → show all
  const lat = report.location?.latitude;
  const lng = report.location?.longitude;
  if (lat == null || lng == null) return false;
  return lat >= b.minLat && lat <= b.maxLat && lng >= b.minLng && lng <= b.maxLng;
}

/* ── Timestamp formatting ── */
function fmtTime(ts) {
  if (!ts) return '—';
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

/* ── Short ID ── */
function shortId(id) { return (id || '').slice(0, 8).toUpperCase(); }

/* ── Render ── */
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
    const m    = catMeta(r.category);
    const lat  = r.location?.latitude;
    const lng  = r.location?.longitude;
    const hasLoc = lat != null && lng != null;

    const mapHref = hasLoc
      ? `map.html?lat=${lat}&lng=${lng}&id=${encodeURIComponent(r.reportId || r.id)}&category=${encodeURIComponent(r.category || '')}&details=${encodeURIComponent((r.details || '').slice(0,120))}`
      : null;

    return `
    <div class="glass-card report-card fade-in" style="animation-delay:${i * 0.04}s" role="listitem">

      <div class="rc-image-bg">
        ${r.imageUrl
          ? `<img src="${r.imageUrl}" alt="${m.label}" loading="lazy" />`
          : `<div class="rc-image-placeholder"><ion-icon name="${m.icon}" class="cat-icon-${r.category || 'Other'}"></ion-icon></div>`
        }
      </div>

      <div class="rc-detail-panel">
        <div class="rc-id">#${shortId(r.reportId || r.id)}</div>
        <div class="rc-title">${m.label}</div>
        <div class="rc-details-label">Details:</div>
        <p class="rc-desc${!r.details ? ' no-desc' : ''}">${r.details || 'No description provided.'}</p>
        <span class="rc-time">${fmtTime(r.createdAt)}</span>
        ${hasLoc
          ? `<a class="rc-loc-badge" href="${mapHref}"><ion-icon name="location-outline"></ion-icon>${lat.toFixed(3)}, ${lng.toFixed(3)}</a>`
          : `<span class="no-location-badge"><ion-icon name="location-outline"></ion-icon>No location</span>`
        }
      </div>

    </div>`;
  }).join('');
}

/* ── Filter & sort state ── */
let allReports   = [];
let currentScope = 'malaysia';  // 'malaysia' | 'state'
let currentState = '';
let currentCat   = 'all';
let currentSearch = '';
let currentSort  = 'newest';

function applyFilters() {
  let list = allReports.filter(r => {
    // Layer 1: scope
    if (currentScope === 'state' && currentState) {
      if (!inState(r, currentState)) return false;
    }

    // Layer 2: category
    if (currentCat !== 'all' && r.category !== currentCat) return false;

    // Search
    if (currentSearch) {
      const q = currentSearch.toLowerCase();
      const hay = [r.category, r.details, r.reportId, r.id].join(' ').toLowerCase();
      if (!hay.includes(q)) return false;
    }

    return true;
  });

  // Sort
  list = list.slice().sort((a, b) => {
    const ta = a.createdAt?.toMillis?.() ?? 0;
    const tb = b.createdAt?.toMillis?.() ?? 0;
    return currentSort === 'oldest' ? ta - tb : tb - ta;
  });

  renderReports(list);
}

/* ── Firestore listener ── */
function listenReports() {
  const loading = document.getElementById('reports-loading');

  db.collection('reports').onSnapshot(snap => {
    loading.classList.add('hidden');
    allReports = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    applyFilters();
  }, err => {
    loading.innerHTML = `<ion-icon name="alert-circle-outline" style="font-size:20px;color:var(--accent-rose)"></ion-icon>
      <span style="color:var(--accent-rose)">Failed to load: ${err.message}</span>`;
  });
}

/* ── Filter UI wiring ── */
function initFilters() {
  // Search
  document.getElementById('report-search').addEventListener('input', e => {
    currentSearch = e.target.value.trim();
    applyFilters();
  });

  // Layer 1 — scope chips
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

  // State dropdown
  document.getElementById('state-select').addEventListener('change', e => {
    currentState = e.target.value;
    applyFilters();
  });

  // Layer 2 — category chips
  document.querySelectorAll('[data-cat]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('[data-cat]').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentCat = btn.dataset.cat;
      applyFilters();
    });
  });

  // Sort
  document.getElementById('report-sort').addEventListener('change', e => {
    currentSort = e.target.value;
    applyFilters();
  });

  // Clear all filters
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
  listenReports();
});
