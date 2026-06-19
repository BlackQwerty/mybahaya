/* ============================================================
   map.js — Map Page Logic
   Real Firestore reports, grouped markers, category legend & filter
   ============================================================ */

'use strict';

/* ── Category metadata ── */
const CAT_META = {
  Theft:   { icon: 'lock-open-outline',    label: 'Theft',   color: '#bf8fff', bg: 'rgba(155,89,182,0.90)' },
  Assault: { icon: 'alert-circle-outline', label: 'Assault', color: '#FF3B30', bg: 'rgba(255,59,48,0.90)'  },
  Fire:    { icon: 'flame-outline',        label: 'Fire',    color: '#ff8c5a', bg: 'rgba(255,107,53,0.90)' },
  Medical: { icon: 'medkit-outline',       label: 'Medical', color: '#30D158', bg: 'rgba(48,209,88,0.90)'  },
  Other:   { icon: 'help-circle-outline',  label: 'Other',   color: '#aca494', bg: 'rgba(172,164,148,0.90)'},
};

function catMeta(cat) { return CAT_META[cat] || CAT_META.Other; }

function fmtTime(ts) {
  if (!ts) return '—';
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

let map;
let allReports    = [];
let activeMarkers = [];
let activeCategory = 'all';

/* ── Map init ── */
function initMap() {
  if (typeof maplibregl === 'undefined') { setTimeout(initMap, 100); return; }

  const params       = new URLSearchParams(window.location.search);
  const focusLat     = parseFloat(params.get('lat'));
  const focusLng     = parseFloat(params.get('lng'));
  const focusId      = params.get('id')       || '';
  const focusCat     = params.get('category') || 'Other';
  const focusDet     = params.get('details')  || '';
  const isReportView = !isNaN(focusLat) && !isNaN(focusLng);

  map = new maplibregl.Map({
    container: 'full-map',
    style: {
      version: 8,
      sources: { osm: {
        type: 'raster',
        tiles: ['https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'],
        tileSize: 256,
        attribution: '&copy; OpenStreetMap contributors &copy; CARTO'
      }},
      layers: [{ id: 'osm', type: 'raster', source: 'osm' }]
    },
    center: isReportView ? [focusLng, focusLat] : [109.0, 3.8],
    zoom:   isReportView ? 15 : 6,
    pitch: 0, bearing: 0,
    attributionControl: false
  });

  map.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right');

  map.on('load', () => {
    setupControls();
    listenReports();
    if (isReportView) {
      showFocusMarker(focusLat, focusLng, focusCat, focusId, focusDet);
      showReportPanel(focusCat, focusId, focusDet, focusLat, focusLng);
    }
  });
}

/* ── Firestore real-time listener ── */
function listenReports() {
  const loadEl = document.getElementById('map-loading');
  if (loadEl) loadEl.classList.remove('hidden');

  db.collection('reports').onSnapshot(snap => {
    allReports = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    if (loadEl) loadEl.classList.add('hidden');
    renderMarkers();
    updatePanel();
  }, err => {
    if (loadEl) loadEl.querySelector('.map-loading-label').textContent = 'Failed to load';
    console.error('Firestore:', err);
  });
}

/* ── Group reports by location (3 d.p. ≈ 100 m radius) ── */
function groupByLocation(reports) {
  const groups = {};
  reports.forEach(r => {
    if (!r.location?.latitude || !r.location?.longitude) return;
    const lat = r.location.latitude;
    const lng = r.location.longitude;
    const key = `${lat.toFixed(3)},${lng.toFixed(3)}`;
    if (!groups[key]) groups[key] = { lat, lng, items: [] };
    groups[key].items.push(r);
  });
  return Object.values(groups);
}

/* ── Build conic-gradient ring for a stack marker ── */
function buildGradient(items) {
  const colorMap = {
    Theft: '#bf8fff', Assault: '#FF3B30', Fire: '#ff8c5a',
    Medical: '#30D158', Other: '#aca494',
  };
  const counts = {};
  items.forEach(r => {
    const cat = r.category in colorMap ? r.category : 'Other';
    counts[cat] = (counts[cat] || 0) + 1;
  });
  const total = items.length;
  let pct = 0;
  const stops = Object.entries(counts).map(([cat, n]) => {
    const from = pct;
    pct += (n / total) * 100;
    return `${colorMap[cat]} ${from.toFixed(1)}% ${pct.toFixed(1)}%`;
  });
  return `conic-gradient(${stops.join(', ')})`;
}

/* ── Popup HTML — single report ── */
function buildSinglePopup(r) {
  const m   = catMeta(r.category);
  const lat = r.location.latitude;
  const lng = r.location.longitude;
  return `
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px">
      <div style="width:26px;height:26px;border-radius:50%;background:${m.bg};
           display:flex;align-items:center;justify-content:center;flex-shrink:0;
           border:2px solid rgba(255,255,255,0.25)">
        <ion-icon name="${m.icon}" style="font-size:12px;color:#fff"></ion-icon>
      </div>
      <div>
        <div style="font-size:12px;font-weight:700;color:${m.color}">${m.label}</div>
        <div style="font-size:9px;color:rgba(255,255,255,0.4);font-family:monospace">#${shortId(r.reportId || r.id)}</div>
      </div>
    </div>
    ${r.details
      ? `<p style="font-size:11px;color:rgba(255,255,255,0.75);line-height:1.5;margin:0 0 8px">${r.details.slice(0, 150)}${r.details.length > 150 ? '…' : ''}</p>`
      : `<p style="font-size:11px;color:rgba(255,255,255,0.30);font-style:italic;margin:0 0 8px">No description provided.</p>`
    }
    <div style="display:flex;justify-content:space-between;font-size:10px;color:rgba(255,255,255,0.35)">
      <span><ion-icon name="time-outline" style="vertical-align:middle;margin-right:2px"></ion-icon>${fmtTime(r.createdAt)}</span>
      <span>${lat.toFixed(4)}, ${lng.toFixed(4)}</span>
    </div>`;
}

/* ── Popup HTML — stacked reports ── */
function buildStackPopup(items, lat, lng) {
  const rows = items.map(r => {
    const m = catMeta(r.category);
    return `
      <div style="display:flex;align-items:center;gap:8px;padding:7px 0;
           border-bottom:1px solid rgba(255,255,255,0.06)">
        <div style="width:22px;height:22px;border-radius:50%;background:${m.bg};flex-shrink:0;
             display:flex;align-items:center;justify-content:center">
          <ion-icon name="${m.icon}" style="font-size:10px;color:#fff"></ion-icon>
        </div>
        <div style="flex:1;min-width:0">
          <div style="font-size:11px;font-weight:600;color:${m.color}">
            ${m.label}
            <span style="font-size:9px;color:rgba(255,255,255,0.35);font-weight:400;
                  font-family:monospace;margin-left:4px">#${shortId(r.reportId || r.id)}</span>
          </div>
          ${r.details ? `<div style="font-size:10px;color:rgba(255,255,255,0.55);white-space:nowrap;
              overflow:hidden;text-overflow:ellipsis;max-width:155px">${r.details.slice(0, 55)}${r.details.length > 55 ? '…' : ''}</div>` : ''}
        </div>
        <div style="font-size:9px;color:rgba(255,255,255,0.30);flex-shrink:0">${fmtTime(r.createdAt)}</div>
      </div>`;
  }).join('');

  return `
    <div style="font-size:10px;color:rgba(255,255,255,0.40);text-transform:uppercase;
         letter-spacing:0.8px;margin-bottom:6px">
      ${items.length} reports &nbsp;·&nbsp; ${lat.toFixed(4)}, ${lng.toFixed(4)}
    </div>
    <div style="max-height:220px;overflow-y:auto;margin:0 -4px;padding:0 4px">
      ${rows}
    </div>`;
}

/* ── Render all markers (grouped) ── */
function renderMarkers() {
  activeMarkers.forEach(m => m.remove());
  activeMarkers = [];

  const filtered = allReports.filter(r => {
    if (!r.location?.latitude || !r.location?.longitude) return false;
    if (activeCategory !== 'all' && r.category !== activeCategory) return false;
    return true;
  });

  const groups = groupByLocation(filtered);

  groups.forEach(({ lat, lng, items }) => {
    let el, popup;

    if (items.length === 1) {
      /* ── Single report → category pin ── */
      const r = items[0];
      const m = catMeta(r.category);

      el = document.createElement('div');
      el.className = `cat-pin cat-pin-${r.category || 'Other'}`;
      el.innerHTML = `<ion-icon name="${m.icon}"></ion-icon>`;

      popup = new maplibregl.Popup({ offset: [0, -22], closeButton: true, maxWidth: '220px' })
        .setHTML(buildSinglePopup(r));

    } else {
      /* ── Multiple reports → stack marker ── */
      el = document.createElement('div');
      el.className = 'stack-marker-ring';
      el.style.background = buildGradient(items);
      el.innerHTML = `
        <div class="stack-marker-inner">
          <span class="stack-count">${items.length}</span>
        </div>`;

      popup = new maplibregl.Popup({ offset: [0, -26], closeButton: true, maxWidth: '250px' })
        .setHTML(buildStackPopup(items, lat, lng));
    }

    const marker = new maplibregl.Marker({ element: el, anchor: 'center' })
      .setLngLat([lng, lat])
      .setPopup(popup)
      .addTo(map);

    activeMarkers.push(marker);
  });
}

/* ── Update right panel + legend counts ── */
function updatePanel() {
  const counts = {};
  Object.keys(CAT_META).forEach(k => { counts[k] = 0; });
  allReports.forEach(r => {
    const cat = r.category in counts ? r.category : 'Other';
    counts[cat]++;
  });

  /* Legend counts */
  const countAll = document.getElementById('count-all');
  if (countAll) countAll.textContent = allReports.length;
  Object.entries(counts).forEach(([cat, n]) => {
    const el = document.getElementById(`count-${cat}`);
    if (el) el.textContent = n;
  });

  /* Stats total */
  const totalEl = document.getElementById('stats-total');
  if (totalEl) totalEl.textContent = allReports.length;

  /* Category bars */
  const statsCatsEl = document.getElementById('stats-cats');
  if (statsCatsEl) {
    const total = allReports.length || 1;
    statsCatsEl.innerHTML = Object.entries(counts).map(([cat, n]) => {
      const m   = catMeta(cat);
      const pct = Math.round(n / total * 100);
      return `
        <div class="stats-cat-row">
          <span class="stats-cat-label">${m.label}</span>
          <div class="stats-cat-bar-bg">
            <div class="stats-cat-bar-fill" style="width:${pct}%;background:${m.color}"></div>
          </div>
          <span class="stats-cat-num">${n}</span>
        </div>`;
    }).join('');
  }

  /* Recent activity */
  const recentEl = document.getElementById('recent-activity');
  if (recentEl) {
    const recent = [...allReports]
      .filter(r => r.createdAt)
      .sort((a, b) => (b.createdAt?.toMillis?.() ?? 0) - (a.createdAt?.toMillis?.() ?? 0))
      .slice(0, 5);

    if (!recent.length) {
      recentEl.innerHTML = `<p class="no-data-text">No reports yet</p>`;
      return;
    }

    recentEl.innerHTML = recent.map(r => {
      const m      = catMeta(r.category);
      const lat    = r.location?.latitude;
      const lng    = r.location?.longitude;
      const hasLoc = lat != null && lng != null;
      return `
        <div class="map-act-item${hasLoc ? ' clickable' : ''}"
             ${hasLoc ? `onclick="flyTo(${lat},${lng})"` : ''}>
          <div class="act-dot" style="background:${m.color};box-shadow:0 0 6px ${m.color}70"></div>
          <div>
            <p class="act-title">${m.label} Incident</p>
            <p class="act-sub">${fmtTime(r.createdAt)}</p>
          </div>
        </div>`;
    }).join('');
  }
}

/* ── Fly to coordinates ── */
function flyTo(lat, lng) {
  map.flyTo({ center: [lng, lat], zoom: 14, duration: 1200 });
}

/* ── Focus marker for report-view mode ── */
function showFocusMarker(lat, lng, cat, id, details) {
  const m  = catMeta(cat);
  const el = document.createElement('div');
  el.className = 'focus-marker';
  el.style.setProperty('--focus-color', m.color);
  el.style.setProperty('--focus-bg', m.bg);
  el.innerHTML = `<div class="focus-pulse"></div><ion-icon name="${m.icon}"></ion-icon>`;

  const popup = new maplibregl.Popup({ offset: [0, -30], closeButton: false })
    .setHTML(`
      <div style="font-size:13px;font-weight:700;color:${m.color};margin-bottom:4px">${cat} Incident</div>
      ${id ? `<div style="font-size:10px;color:rgba(255,255,255,0.40);font-family:monospace;margin-bottom:6px">#${id.slice(0,8).toUpperCase()}</div>` : ''}
      ${details ? `<div style="font-size:11px;color:rgba(255,255,255,0.75);line-height:1.5">${details}</div>` : ''}
      <div style="font-size:10px;color:rgba(255,255,255,0.35);margin-top:6px">${lat.toFixed(5)}, ${lng.toFixed(5)}</div>
    `);

  new maplibregl.Marker({ element: el, anchor: 'center' })
    .setLngLat([lng, lat])
    .setPopup(popup)
    .addTo(map);

  setTimeout(() => { popup.addTo(map).setLngLat([lng, lat]); }, 400);
}

/* ── Report detail side panel (report-view mode) ── */
function showReportPanel(cat, id, details, lat, lng) {
  const m     = catMeta(cat);
  const panel = document.createElement('div');
  panel.style.cssText = `
    position:fixed; top:72px; left:16px; z-index:50; width:260px; border-radius:16px;
    background:rgba(52,21,21,0.88); backdrop-filter:blur(24px);
    -webkit-backdrop-filter:blur(24px); border:1px solid rgba(255,255,255,0.10);
    box-shadow:0 16px 40px rgba(0,0,0,0.55);
    font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text',sans-serif; overflow:hidden;
  `;
  panel.innerHTML = `
    <div style="padding:12px 14px;border-bottom:1px solid rgba(255,255,255,0.08)">
      <a href="report.html" style="display:inline-flex;align-items:center;gap:5px;text-decoration:none;
         color:rgba(255,255,255,0.6);font-size:12px;font-weight:500;padding:4px 10px;
         border-radius:99px;background:rgba(255,255,255,0.06);border:1px solid rgba(255,255,255,0.10)">
        <ion-icon name="chevron-back-outline" style="font-size:13px"></ion-icon> Reports
      </a>
    </div>
    <div style="padding:14px">
      <div style="display:flex;align-items:center;gap:10px;margin-bottom:10px">
        <div style="width:34px;height:34px;border-radius:10px;background:${m.bg};
             display:flex;align-items:center;justify-content:center;flex-shrink:0">
          <ion-icon name="${m.icon}" style="font-size:17px;color:#fff"></ion-icon>
        </div>
        <div>
          <div style="font-size:13px;font-weight:700;color:white">${cat} Incident</div>
          ${id ? `<div style="font-size:10px;color:rgba(255,255,255,0.35);font-family:monospace">#${id.slice(0,8).toUpperCase()}</div>` : ''}
        </div>
      </div>
      ${details
        ? `<p style="font-size:12px;color:rgba(255,255,255,0.65);line-height:1.55;margin-bottom:10px">${details}</p>`
        : `<p style="font-size:12px;color:rgba(255,255,255,0.28);font-style:italic;margin-bottom:10px">No description.</p>`}
      <div style="font-size:11px;color:rgba(255,255,255,0.35)">
        <ion-icon name="location-outline" style="vertical-align:middle;margin-right:3px"></ion-icon>
        ${lat.toFixed(5)}, ${lng.toFixed(5)}
      </div>
    </div>
  `;
  document.body.appendChild(panel);
}

/* ── Controls ── */
function setupControls() {
  document.getElementById('zoom-in').addEventListener('click',  () => map.zoomIn());
  document.getElementById('zoom-out').addEventListener('click', () => map.zoomOut());

  document.getElementById('locate-me').addEventListener('click', () => {
    navigator.geolocation?.getCurrentPosition(
      pos => map.flyTo({ center: [pos.coords.longitude, pos.coords.latitude], zoom: 14 }),
      ()  => map.flyTo({ center: [109.0, 3.8], zoom: 6 })
    );
  });

  let is3D = false;
  const btn3D = document.getElementById('toggle-3d');
  btn3D.addEventListener('click', () => {
    is3D = !is3D;
    if (is3D) {
      map.flyTo({ pitch: 60, bearing: -20 });
      btn3D.innerHTML = '<ion-icon name="map-outline"></ion-icon> 2D View';
      btn3D.classList.replace('btn-primary', 'btn-glass');
    } else {
      map.flyTo({ pitch: 0, bearing: 0 });
      btn3D.innerHTML = '<ion-icon name="layers-outline"></ion-icon> 3D View';
      btn3D.classList.replace('btn-glass', 'btn-primary');
    }
  });

  /* Legend items as category filters */
  document.querySelectorAll('#legend-list .legend-item').forEach(item => {
    item.addEventListener('click', () => {
      document.querySelectorAll('#legend-list .legend-item').forEach(i => i.classList.remove('active'));
      item.classList.add('active');
      activeCategory = item.dataset.cat;
      renderMarkers();
    });
  });
}

document.addEventListener('DOMContentLoaded', initMap);
