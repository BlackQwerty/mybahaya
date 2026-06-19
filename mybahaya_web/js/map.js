/* ============================================================
   map.js — Map Page Logic
   Handles normal map view AND "view report on map" mode
   (triggered by report.html via ?lat=&lng=&id=&category=&details=)
   ============================================================ */

'use strict';

let map;

/* ── Category colour for report marker ── */
const CAT_COLORS = {
  Theft:   '#bf8fff',
  Assault: '#FF3B30',
  Fire:    '#ff8c5a',
  Medical: '#30D158',
  Other:   '#aca494',
};
const CAT_ICONS = {
  Theft:   'lock-open-outline',
  Assault: 'alert-circle-outline',
  Fire:    'flame-outline',
  Medical: 'medkit-outline',
  Other:   'help-circle-outline',
};

function initFullMap() {
  if (typeof maplibregl === 'undefined') { setTimeout(initFullMap, 100); return; }

  // Parse URL params — set by report.html "View on Map"
  const params   = new URLSearchParams(window.location.search);
  const focusLat = parseFloat(params.get('lat'));
  const focusLng = parseFloat(params.get('lng'));
  const focusId  = params.get('id')       || '';
  const focusCat = params.get('category') || 'Other';
  const focusDet = params.get('details')  || '';
  const isReportView = !isNaN(focusLat) && !isNaN(focusLng);

  const initCenter = isReportView ? [focusLng, focusLat] : [109.0, 3.8]; // Malaysia centre
  const initZoom   = isReportView ? 15 : 6;

  map = new maplibregl.Map({
    container: 'full-map',
    style: {
      version: 8,
      sources: {
        osm: {
          type: 'raster',
          tiles: ['https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'],
          tileSize: 256,
          attribution: '&copy; OpenStreetMap contributors &copy; CARTO'
        }
      },
      layers: [{ id: 'osm', type: 'raster', source: 'osm' }]
    },
    center: initCenter,
    zoom: initZoom,
    pitch: 0, bearing: 0,
    attributionControl: false
  });

  map.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right');

  map.on('load', () => {
    if (isReportView) {
      showReportMarker(focusLat, focusLng, focusCat, focusId, focusDet);
      showReportPanel(focusCat, focusId, focusDet, focusLat, focusLng);
    } else {
      addMockData();
    }
    setupControls();
  });
}

/* ── Show highlighted report marker ── */
function showReportMarker(lat, lng, cat, id, details) {
  const color = CAT_COLORS[cat] || CAT_COLORS.Other;
  const icon  = CAT_ICONS[cat]  || CAT_ICONS.Other;

  const el = document.createElement('div');
  el.className = 'glass-marker report-focus-marker';
  el.innerHTML = `
    <div class="gm-icon" style="background:${color}; width:46px; height:46px; box-shadow:0 0 20px ${color}80">
      <ion-icon name="${icon}" style="font-size:22px"></ion-icon>
    </div>
    <div class="gm-label" style="font-size:11px">${cat.toUpperCase()}</div>
  `;

  const popup = new maplibregl.Popup({ offset: [0, -34], closeButton: false })
    .setHTML(`
      <div style="font-size:13px;font-weight:700;color:${color};margin-bottom:4px">${cat} Incident</div>
      ${id ? `<div style="font-size:10px;color:rgba(255,255,255,0.40);font-family:monospace;margin-bottom:6px">#${id.slice(0,8).toUpperCase()}</div>` : ''}
      ${details ? `<div style="font-size:11px;color:rgba(255,255,255,0.75);line-height:1.5;max-width:200px">${details}</div>` : ''}
      <div style="font-size:10px;color:rgba(255,255,255,0.35);margin-top:6px">${lat.toFixed(5)}, ${lng.toFixed(5)}</div>
    `);

  new maplibregl.Marker({ element: el, anchor: 'bottom' })
    .setLngLat([lng, lat])
    .setPopup(popup)
    .addTo(map);

  // Open popup immediately
  setTimeout(() => {
    document.querySelector('.maplibregl-marker')?.click();
    popup.addTo(map).setLngLat([lng, lat]);
  }, 300);
}

/* ── Report detail side panel (only in report-view mode) ── */
function showReportPanel(cat, id, details, lat, lng) {
  const color = CAT_COLORS[cat] || CAT_COLORS.Other;
  const icon  = CAT_ICONS[cat]  || CAT_ICONS.Other;

  const panel = document.createElement('div');
  panel.style.cssText = `
    position:fixed; top:72px; left:16px; z-index:50;
    width:280px; border-radius:16px;
    background:rgba(52,21,21,0.85);
    backdrop-filter:blur(24px); -webkit-backdrop-filter:blur(24px);
    border:1px solid rgba(255,255,255,0.10);
    box-shadow:0 16px 40px rgba(0,0,0,0.55);
    font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text','Helvetica Neue',Arial,sans-serif;
    overflow:hidden;
  `;
  panel.innerHTML = `
    <div style="padding:14px 16px; border-bottom:1px solid rgba(255,255,255,0.08); display:flex; align-items:center; gap:10px">
      <a href="report.html" style="display:flex;align-items:center;gap:6px;text-decoration:none;
         color:rgba(255,255,255,0.60); font-size:12px; font-weight:500;
         padding:5px 10px; border-radius:99px; background:rgba(255,255,255,0.06);
         border:1px solid rgba(255,255,255,0.10);">
        <ion-icon name="chevron-back-outline" style="font-size:14px"></ion-icon> Reports
      </a>
    </div>
    <div style="padding:16px">
      <div style="display:flex; align-items:center; gap:10px; margin-bottom:12px">
        <div style="width:36px;height:36px;border-radius:10px;background:${color}20;
             border:1px solid ${color}50; display:flex;align-items:center;justify-content:center;flex-shrink:0">
          <ion-icon name="${icon}" style="font-size:18px;color:${color}"></ion-icon>
        </div>
        <div>
          <div style="font-size:13px;font-weight:700;color:white">${cat} Incident</div>
          ${id ? `<div style="font-size:10px;color:rgba(255,255,255,0.35);font-family:monospace">#${id.slice(0,8).toUpperCase()}</div>` : ''}
        </div>
      </div>
      ${details
        ? `<p style="font-size:12px;color:rgba(255,255,255,0.65);line-height:1.55;margin-bottom:12px">${details}</p>`
        : `<p style="font-size:12px;color:rgba(255,255,255,0.30);font-style:italic;margin-bottom:12px">No description provided.</p>`}
      <div style="font-size:11px;color:rgba(255,255,255,0.35)">
        <ion-icon name="location-outline" style="vertical-align:middle;margin-right:4px"></ion-icon>
        ${lat.toFixed(5)}, ${lng.toFixed(5)}
      </div>
    </div>
  `;
  document.body.appendChild(panel);
}

/* ── Mock markers (normal map view) ── */
function createMarkerElement(icon, color, label) {
  const el = document.createElement('div');
  el.className = 'glass-marker';
  el.innerHTML = `
    <div class="gm-icon" style="background:${color}"><ion-icon name="${icon}"></ion-icon></div>
    <div class="gm-label">${label}</div>
  `;
  return el;
}

function addMockData() {
  const data = [
    { lng:109.0, lat:3.8,    color:'#f05f7e', icon:'flame-outline',           label:'FIRE',    desc:'Fire alert<br/>Kuching area' },
    { lng:101.7, lat:3.15,   color:'#30d158', icon:'shield-checkmark-outline', label:'SAFE',    desc:'Safe zone<br/>Kuala Lumpur' },
    { lng:100.37,lat:5.42,   color:'#f5a623', icon:'warning-outline',          label:'ALERT',   desc:'Alert<br/>George Town' },
  ];

  data.forEach(d => {
    const el = createMarkerElement(d.icon, d.color, d.label);
    new maplibregl.Marker({ element: el, anchor: 'bottom' })
      .setLngLat([d.lng, d.lat])
      .setPopup(new maplibregl.Popup({ offset: [0, -30] })
        .setHTML(`<div style="font-size:14px;font-weight:600;color:${d.color};margin-bottom:4px">${d.label}</div>
                  <div style="font-size:12px;color:rgba(255,255,255,0.8)">${d.desc}</div>`))
      .addTo(map);
  });
}

/* ── Map controls ── */
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

  document.querySelectorAll('.map-pill').forEach(p =>
    p.addEventListener('click', () => p.classList.toggle('active'))
  );
}

document.addEventListener('DOMContentLoaded', initFullMap);
