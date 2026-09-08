/* ============================================================
   home.js — Home Page  |  All data from Firestore, zero hardcoded
   ============================================================ */

'use strict';

/* ── Category metadata ── */
const CAT_META = {
  Theft:   { icon: 'lock-open-outline',    label: 'Theft',   color: '#bf8fff', bg: 'rgba(155,89,182,0.18)', border: 'rgba(155,89,182,0.45)' },
  Assault: { icon: 'alert-circle-outline', label: 'Assault', color: '#FF3B30', bg: 'rgba(255,59,48,0.18)',  border: 'rgba(255,59,48,0.45)'  },
  Fire:    { icon: 'flame-outline',        label: 'Fire',    color: '#ff8c5a', bg: 'rgba(255,107,53,0.18)', border: 'rgba(255,107,53,0.45)' },
  Medical: { icon: 'medkit-outline',       label: 'Medical', color: '#30D158', bg: 'rgba(48,209,88,0.18)',  border: 'rgba(48,209,88,0.45)'  },
  Other:   { icon: 'help-circle-outline',  label: 'Other',   color: '#aca494', bg: 'rgba(172,164,148,0.18)',border: 'rgba(172,164,148,0.35)' },
};

function catMeta(cat) { return CAT_META[cat] || CAT_META.Other; }

function fmtTime(ts) {
  if (!ts) return '-';
  const dt   = ts.toDate ? ts.toDate() : new Date(ts);
  const diff = Date.now() - dt.getTime();
  const m = Math.floor(diff / 60000);
  const h = Math.floor(diff / 3600000);
  const d = Math.floor(diff / 86400000);
  if (m < 1)  return 'Just now';
  if (m < 60) return `${m}m ago`;
  if (h < 24) return `${h}h ago`;
  if (d < 7)  return `${d}d ago`;
  const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return `${dt.getDate()} ${mo[dt.getMonth()]}`;
}

function shortId(id) { return (id || '').slice(0, 8).toUpperCase(); }

function todayMidnight() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

/* ── Animated counter ── */
function animateCounter(el, target, duration = 1000) {
  if (!el) return;
  let start = null;
  const step = ts => {
    if (!start) start = ts;
    const p = Math.min((ts - start) / duration, 1);
    const eased = 1 - Math.pow(1 - p, 3);
    el.textContent = Math.floor(eased * target).toLocaleString();
    if (p < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
}

/* ══════════════════════════════════════════════════════════
   1. HERO — Greeting + live clock
   ══════════════════════════════════════════════════════════ */
function initHero() {
  const greetEl    = document.getElementById('hero-greeting');
  const clockEl    = document.getElementById('hero-clock');
  const subtitleEl = document.getElementById('hero-sub');

  // Defaults until the role/profile resolves
  let displayName = 'Admin';
  let subText     = 'Live situational awareness · Malaysia';

  function updateGreeting() {
    const h = new Date().getHours();
    const period = h < 12 ? 'Morning' : h < 17 ? 'Afternoon' : 'Evening';
    if (greetEl) greetEl.textContent = `Good ${period}, ${displayName}`;
    if (subtitleEl) subtitleEl.textContent = subText;
  }

  function updateClock() {
    if (!clockEl) return;
    const now = new Date();
    const days = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    const mos  = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const hh   = String(now.getHours()).padStart(2, '0');
    const mm   = String(now.getMinutes()).padStart(2, '0');
    const ss   = String(now.getSeconds()).padStart(2, '0');
    clockEl.textContent = `${days[now.getDay()]}, ${now.getDate()} ${mos[now.getMonth()]} ${now.getFullYear()} · ${hh}:${mm}:${ss}`;
  }

  updateGreeting();
  updateClock();
  setInterval(updateClock, 1000);

  // Resolve the real display name once auth.js determines the role.
  (window.authReady || Promise.resolve()).then(() => {
    const org = window.currentUserOrg;
    if (org) {
      // Org user → use the organization's name + its location
      displayName = org.name || 'Organization';
      const loc = [org.district, org.state].filter(Boolean).join(', ');
      subText = `Live situational awareness · ${loc || 'Malaysia'}`;
      updateGreeting();
    } else if (window.currentUserIsAdmin) {
      // Admin → look up their name + coverage area from /admins
      const user = firebase.auth().currentUser;
      db.collection('admins').doc(user.uid).get().then(snap => {
        const data = snap.data() || {};
        if (data.name) displayName = data.name;
        if (data.coverDistrict && data.coverState) {
          subText = `Live situational awareness · ${data.coverDistrict}, ${data.coverState}`;
        }
        updateGreeting();
      }).catch(() => updateGreeting());
    } else {
      updateGreeting();
    }
  });
}

/* ══════════════════════════════════════════════════════════
   2. STATS + CATEGORY CARDS — from Firestore
   ══════════════════════════════════════════════════════════ */
let homeMap = null;
let homeMapMarkers = [];
let chartInstance = null;
let allReports = [];

function processReports(reports) {
  allReports = reports;
  const today = todayMidnight();

  /* Stats */
  const total   = reports.length;
  const todayN  = reports.filter(r => {
    const dt = r.createdAt?.toDate?.();
    return dt && dt >= today;
  }).length;

  animateCounter(document.getElementById('val-total'),   total);
  animateCounter(document.getElementById('val-today'),   todayN);

  /* Category counts */
  const counts = { Theft: 0, Assault: 0, Fire: 0, Medical: 0, Other: 0 };
  reports.forEach(r => {
    const cat = r.category in counts ? r.category : 'Other';
    counts[cat]++;
  });

  /* Category breakdown cards */
  const catRow = document.getElementById('cat-breakdown');
  if (catRow) {
    catRow.innerHTML = Object.entries(CAT_META).map(([cat, m]) => `
      <a href="report.html" class="glass-card cat-card fade-in" title="View ${m.label} reports"
         style="--cat-color:${m.color};--cat-bg:${m.bg};--cat-border:${m.border}">
        <div class="cat-card-icon"><ion-icon name="${m.icon}"></ion-icon></div>
        <p class="cat-card-count">${counts[cat]}</p>
        <p class="cat-card-label">${m.label}</p>
      </a>
    `).join('');
  }

  /* Chart — last 7 days by category */
  updateChart(reports, counts);

  /* Recent activity */
  updateActivity(reports);

  /* Map markers */
  if (homeMap) updateMapMarkers(reports);

  /* Map badges */
  updateMapBadges(reports, today);
}

/* ══════════════════════════════════════════════════════════
   3. ORGANIZATIONS COUNT
   ══════════════════════════════════════════════════════════ */
function listenOrgs() {
  db.collection('organizations').onSnapshot(snap => {
    const orgs   = snap.docs.map(d => d.data());
    const active = orgs.filter(o => o.status === 'active').length;
    animateCounter(document.getElementById('val-orgs'), active);
  });
}

/* ══════════════════════════════════════════════════════════
   4. CHART — last 7 days per category
   ══════════════════════════════════════════════════════════ */
function updateChart(reports, counts) {
  const ctx = document.getElementById('incidentChart');
  if (!ctx) return;

  /* Build last-7-days labels */
  const days   = [];
  const labels = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() - i);
    days.push(d);
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    labels.push(`${d.getDate()} ${mo[d.getMonth()]}`);
  }

  /* Count per category per day */
  const catKeys = Object.keys(CAT_META);
  const series  = {};
  catKeys.forEach(cat => { series[cat] = new Array(7).fill(0); });

  reports.forEach(r => {
    const dt = r.createdAt?.toDate?.();
    if (!dt) return;
    const cat = r.category in series ? r.category : 'Other';
    for (let i = 0; i < 7; i++) {
      const dayStart = days[i];
      const dayEnd   = new Date(dayStart); dayEnd.setDate(dayEnd.getDate() + 1);
      if (dt >= dayStart && dt < dayEnd) { series[cat][i]++; break; }
    }
  });

  const datasets = catKeys.map(cat => {
    const m = CAT_META[cat];
    return {
      label: m.label,
      data:  series[cat],
      borderColor: m.color,
      backgroundColor: m.color + '22',
      borderWidth: 2,
      pointRadius: 4,
      pointBackgroundColor: m.color,
      tension: 0.4,
      fill: false,
    };
  });

  if (chartInstance) chartInstance.destroy();

  chartInstance = new Chart(ctx, {
    type: 'line',
    data: { labels, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
      plugins: {
        legend: { display: false },
      tooltip: {
          backgroundColor: 'rgba(255,255,255,0.96)',
          borderColor: 'rgba(166,27,43,0.12)',
          borderWidth: 1,
          titleColor: '#1d1d1f',
          bodyColor:  '#6e6e73',
          padding: 12, cornerRadius: 10,
        },
      },
      scales: {
        x: {
          grid:   { color: 'rgba(166,27,43,0.05)' },
          ticks:  { color: '#6e6e73', font: { size: 10 } },
          border: { display: false },
        },
        y: {
          grid:      { color: 'rgba(166,27,43,0.05)' },
          ticks:     { color: '#6e6e73', font: { size: 10 }, precision: 0 },
          border:    { display: false },
          beginAtZero: true,
        },
      },
    },
  });

  /* Custom legend */
  const legend = document.getElementById('chart-legend');
  if (legend) {
    legend.innerHTML = catKeys.map(cat => {
      const m = CAT_META[cat];
      return `<div class="chart-legend-item">
        <div class="chart-legend-dot" style="background:${m.color}"></div>${m.label}
      </div>`;
    }).join('');
  }
}

/* ══════════════════════════════════════════════════════════
   5. RECENT ACTIVITY — last 8 reports
   ══════════════════════════════════════════════════════════ */
function updateActivity(reports) {
  const list = document.getElementById('activity-list');
  if (!list) return;

  const recent = [...reports]
    .filter(r => r.createdAt)
    .sort((a, b) => (b.createdAt?.toMillis?.() ?? 0) - (a.createdAt?.toMillis?.() ?? 0))
    .slice(0, 8);

  if (!recent.length) {
    list.innerHTML = `<li class="activity-empty">No reports yet</li>`;
    return;
  }

  list.innerHTML = recent.map(r => {
    const m      = catMeta(r.category);
    const lat    = r.location?.latitude;
    const lng    = r.location?.longitude;
    const mapUrl = (lat != null && lng != null)
      ? `map.html?lat=${lat}&lng=${lng}&id=${encodeURIComponent(r.reportId || r.id)}&category=${encodeURIComponent(r.category || '')}&details=${encodeURIComponent((r.details || '').slice(0, 120))}`
      : 'map.html';

    return `
      <li class="activity-item" role="listitem" onclick="location.href='${mapUrl}'" style="cursor:pointer">
        <div class="activity-icon-wrap" style="background:${m.bg};color:${m.color};border:1px solid ${m.border}">
          <ion-icon name="${m.icon}"></ion-icon>
        </div>
        <div class="activity-body">
          <p class="activity-title">${m.label} Incident
            <span class="activity-id">#${shortId(r.reportId || r.id)}</span>
          </p>
          <p class="activity-desc">
            ${r.details
              ? r.details.slice(0, 60) + (r.details.length > 60 ? '…' : '')
              : '<span style="opacity:0.5;font-style:italic">No description</span>'
            }
          </p>
        </div>
        <span class="activity-time">${fmtTime(r.createdAt)}</span>
      </li>`;
  }).join('');
}

/* ══════════════════════════════════════════════════════════
   6. MINI MAP — real markers
   ══════════════════════════════════════════════════════════ */
function initHomeMap() {
  if (typeof maplibregl === 'undefined') return;

  homeMap = new maplibregl.Map({
    container: 'home-map',
    style: {
      version: 8,
      sources: { osm: {
        type: 'raster',
        tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
        tileSize: 256,
        attribution: '&copy; OpenStreetMap contributors'
      }},
      layers: [{ id: 'osm', type: 'raster', source: 'osm' }]
    },
    center: [109.0, 3.8],
    zoom: 6,
    interactive: true,
    attributionControl: false,
  });

  homeMap.on('load', () => {
    if (allReports.length) updateMapMarkers(allReports);
  });
}

function updateMapMarkers(reports) {
  homeMapMarkers.forEach(m => m.remove());
  homeMapMarkers = [];

  const withLoc = reports.filter(r => r.location?.latitude && r.location?.longitude);

  /* Auto-fit Malaysia if no reports, or fit to markers */
  if (withLoc.length > 0) {
    const lngs = withLoc.map(r => r.location.longitude);
    const lats = withLoc.map(r => r.location.latitude);
    const pad  = 0.3;
    homeMap.fitBounds(
      [[Math.min(...lngs) - pad, Math.min(...lats) - pad],
       [Math.max(...lngs) + pad, Math.max(...lats) + pad]],
      { padding: 40, maxZoom: 13, duration: 800 }
    );
  }

  withLoc.forEach(r => {
    const m   = catMeta(r.category);
    const el  = document.createElement('div');
    el.className = 'home-pin';
    el.style.cssText = `
      width:12px; height:12px; border-radius:50%;
      background:${m.color}; border:2px solid rgba(255,255,255,0.6);
      box-shadow:0 0 8px ${m.color}; cursor:pointer;
    `;

    const lat = r.location.latitude;
    const lng = r.location.longitude;

    const popup = new maplibregl.Popup({ offset: 14, closeButton: false })
      .setHTML(`<div style="font-size:11px;font-weight:600;color:${m.color}">${m.label}</div>
                <div style="font-size:10px;color:rgba(255,255,255,0.5)">${fmtTime(r.createdAt)}</div>`);

    const marker = new maplibregl.Marker({ element: el })
      .setLngLat([lng, lat])
      .setPopup(popup)
      .addTo(homeMap);

    homeMapMarkers.push(marker);
  });
}

function updateMapBadges(reports, today) {
  const withLoc = reports.filter(r => r.location?.latitude && r.location?.longitude);
  const todayN  = reports.filter(r => {
    const dt = r.createdAt?.toDate?.();
    return dt && dt >= today;
  }).length;

  const b = document.getElementById('map-badges');
  if (!b) return;
  b.innerHTML = `
    <span class="badge badge-total">
      <ion-icon name="ellipse" style="font-size:8px;color:var(--accent-primary)"></ion-icon>
      ${reports.length} Total
    </span>
    <span class="badge badge-today">
      <ion-icon name="ellipse" style="font-size:8px;color:#30D158"></ion-icon>
      ${todayN} Today
    </span>
    <span class="badge badge-loc">
      <ion-icon name="ellipse" style="font-size:8px;color:#ff8c5a"></ion-icon>
      ${withLoc.length} With Location
    </span>`;
}

/* ══════════════════════════════════════════════════════════
   MAIN FIRESTORE LISTENER
   ══════════════════════════════════════════════════════════ */
function listenReports() {
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
    console.log(`[MyBahaya Home] Snapshot received: ${snap.docs.length} docs, ${snap.docChanges().length} doc changes`);

    const reports = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    const docChanges = snap.docChanges();

    if (!initialLoadDone) {
      // First snapshot: mark all existing documents as seen, don't play sound
      snap.docs.forEach(d => {
        seenIds.add(d.id);
        const data = d.data() || {};
        seenStatusUpdates.add(`${d.id}_${data.status}`);
      });
      initialLoadDone = true;
      console.log(`[MyBahaya Home] Initial snapshot recorded with ${seenIds.size} existing reports.`);
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
        console.log(`[MyBahaya Home] 🚨 ${newDocs.length} real-time report event(s) detected! Triggering alert sound...`);
        if (typeof window.playAlertSound === 'function') {
          window.playAlertSound(3);
        }
        const first = newDocs[0].data;
        const cat = first.category || 'Incident';
        const actionWord = newDocs[0].isNew ? 'received' : 'updated to Received';
        if (typeof showToast === 'function') {
          showToast(`🚨 New ${cat} report ${actionWord} in real time!`, 'info', 5000);
        }
      }
    }

    processReports(reports);
  }, err => console.error('[MyBahaya Home] Reports listener error:', err));
}

/* ══════════════════════════════════════════════════════════
   INIT
   ══════════════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', () => {
  initHero();
  // Wait until auth.js resolves the role so the org filter is in place.
  (window.authReady || Promise.resolve()).then(listenReports);
  listenOrgs();

  /* Load MapLibre dynamically */
  const script = document.createElement('script');
  script.src = 'https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.js';
  script.onload = initHomeMap;
  document.head.appendChild(script);

  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = 'https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.css';
  document.head.appendChild(link);
});
