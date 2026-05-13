/* ============================================================
   map.js — Map Page Logic
   ============================================================ */

'use strict';

let map;

function initFullMap() {
  if (typeof maplibregl === 'undefined') {
    setTimeout(initFullMap, 100);
    return;
  }

  map = new maplibregl.Map({
    container: 'full-map',
    style: {
      version: 8,
      sources: {
        'osm': {
          type: 'raster',
          tiles: ['https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'],
          tileSize: 256,
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
        }
      },
      layers: [{ id: 'osm', type: 'raster', source: 'osm' }]
    },
    center: [102.2095, 2.3849], // Alor Gajah
    zoom: 13,
    pitch: 0,
    bearing: 0,
    attributionControl: false
  });

  map.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right');

  map.on('load', () => {
    addMockData();
    setupControls();
  });
}

function createMarkerElement(icon, color, label) {
  const el = document.createElement('div');
  el.className = 'glass-marker';
  el.innerHTML = `
    <div class="gm-icon" style="background:${color}"><i class="ph ${icon}"></i></div>
    <div class="gm-label">${label}</div>
  `;
  return el;
}

function addMockData() {
  const data = [
    { lng: 102.2095, lat: 2.3849, color: '#f05f7e', icon: 'ph-fire', label: 'CRITICAL', desc: 'Fire: Sector 4A<br/>Response en route.' },
    { lng: 102.2150, lat: 2.3920, color: '#30d158', icon: 'ph-shield-check', label: 'U4', desc: 'Active Patrol<br/>Officer Aziz S.' },
    { lng: 102.1950, lat: 2.3800, color: '#f5a623', icon: 'ph-warning', label: 'CROWD', desc: 'Crowd Surge<br/>Main Square North' }
  ];

  data.forEach(d => {
    const el = createMarkerElement(d.icon, d.color, d.label);
    
    new maplibregl.Marker({ element: el, anchor: 'bottom' })
      .setLngLat([d.lng, d.lat])
      .setPopup(new maplibregl.Popup({ offset: [0, -30] })
        .setHTML(`
          <div style="font-size:14px;font-weight:600;margin-bottom:4px;color:${d.color}">${d.label}</div>
          <div style="font-size:12px;color:rgba(255,255,255,0.8)">${d.desc}</div>
        `))
      .addTo(map);
  });
}

function setupControls() {
  document.getElementById('zoom-in').addEventListener('click', () => map.zoomIn());
  document.getElementById('zoom-out').addEventListener('click', () => map.zoomOut());
  
  document.getElementById('locate-me').addEventListener('click', () => {
    map.flyTo({ center: [102.2095, 2.3849], zoom: 14 });
  });

  let is3D = false;
  const btn3D = document.getElementById('toggle-3d');
  btn3D.addEventListener('click', () => {
    is3D = !is3D;
    if (is3D) {
      map.flyTo({ pitch: 60, bearing: -20 });
      btn3D.innerHTML = '<i class="ph ph-map-trifold"></i> 2D View';
      btn3D.classList.remove('btn-primary');
      btn3D.classList.add('btn-glass');
    } else {
      map.flyTo({ pitch: 0, bearing: 0 });
      btn3D.innerHTML = '<i class="ph ph-stack"></i> 3D View';
      btn3D.classList.remove('btn-glass');
      btn3D.classList.add('btn-primary');
    }
  });

  // Pill filters interaction
  const pills = document.querySelectorAll('.map-pill');
  pills.forEach(p => {
    p.addEventListener('click', () => p.classList.toggle('active'));
  });
}

document.addEventListener('DOMContentLoaded', initFullMap);
