/* ============================================================
   home.js — Home Page Logic
   ============================================================ */

'use strict';

/* ── MapLibre Home Preview ── */
function initHomeMap() {
  if (typeof maplibregl === 'undefined') return;

  const map = new maplibregl.Map({
    container: 'home-map',
    style: {
      version: 8,
      sources: {
        'osm': {
          type: 'raster',
          tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
          tileSize: 256,
          attribution: '© OpenStreetMap contributors'
        }
      },
      layers: [{ id: 'osm', type: 'raster', source: 'osm' }]
    },
    center: [102.2095, 2.3849],  // Alor Gajah, Melaka
    zoom: 12,
    interactive: false,
    attributionControl: false
  });

  // Apply dark overlay tint via CSS after load
  map.on('load', () => {
    // Add incident markers
    const incidents = [
      { lng: 102.2095, lat: 2.3849, color: '#f05f7e', label: 'Critical' },
      { lng: 102.2200, lat: 2.3920, color: '#f5a623', label: 'Warning' },
      { lng: 102.1970, lat: 2.3780, color: '#30d158', label: 'Resolved' },
      { lng: 102.2150, lat: 2.3700, color: '#f05f7e', label: 'Critical' },
      { lng: 102.2050, lat: 2.4000, color: '#f5a623', label: 'Warning' },
    ];

    incidents.forEach(inc => {
      const el = document.createElement('div');
      el.className = 'home-marker';
      el.style.cssText = `
        width:14px; height:14px; border-radius:50%;
        background:${inc.color};
        border:2px solid white;
        box-shadow:0 0 10px ${inc.color};
      `;
      new maplibregl.Marker({ element: el })
        .setLngLat([inc.lng, inc.lat])
        .setPopup(new maplibregl.Popup({ offset: 20 }).setText(inc.label))
        .addTo(map);
    });
  });
}

/* ── Incident Chart ── */
function initChart() {
  const ctx = document.getElementById('incidentChart');
  if (!ctx) return;

  const labels = ['00:00','03:00','06:00','09:00','12:00','15:00','18:00','21:00'];
  const critical = [2, 1, 0, 4, 7, 5, 8, 6];
  const warning  = [5, 3, 2, 8, 12, 9, 15, 11];
  const resolved = [3, 2, 1, 5, 8, 10, 12, 9];

  const gradient1 = ctx.getContext('2d').createLinearGradient(0, 0, 0, 200);
  gradient1.addColorStop(0, 'rgba(240,95,126,0.8)');
  gradient1.addColorStop(1, 'rgba(240,95,126,0.1)');

  const gradient2 = ctx.getContext('2d').createLinearGradient(0, 0, 0, 200);
  gradient2.addColorStop(0, 'rgba(245,166,35,0.8)');
  gradient2.addColorStop(1, 'rgba(245,166,35,0.1)');

  const gradient3 = ctx.getContext('2d').createLinearGradient(0, 0, 0, 200);
  gradient3.addColorStop(0, 'rgba(48,209,88,0.8)');
  gradient3.addColorStop(1, 'rgba(48,209,88,0.1)');

  new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [
        {
          label: 'Critical',
          data: critical,
          backgroundColor: gradient1,
          borderColor: 'rgba(240,95,126,0.9)',
          borderWidth: 1,
          borderRadius: 6,
          borderSkipped: false
        },
        {
          label: 'Warning',
          data: warning,
          backgroundColor: gradient2,
          borderColor: 'rgba(245,166,35,0.9)',
          borderWidth: 1,
          borderRadius: 6,
          borderSkipped: false
        },
        {
          label: 'Resolved',
          data: resolved,
          backgroundColor: gradient3,
          borderColor: 'rgba(48,209,88,0.9)',
          borderWidth: 1,
          borderRadius: 6,
          borderSkipped: false
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: 'rgba(15,15,26,0.95)',
          borderColor: 'rgba(255,255,255,0.10)',
          borderWidth: 1,
          titleColor: 'rgba(255,255,255,0.80)',
          bodyColor: 'rgba(255,255,255,0.60)',
          padding: 12,
          cornerRadius: 10
        }
      },
      scales: {
        x: {
          grid: { color: 'rgba(255,255,255,0.04)' },
          ticks: { color: 'rgba(255,255,255,0.40)', font: { size: 10 } },
          border: { display: false }
        },
        y: {
          grid: { color: 'rgba(255,255,255,0.04)' },
          ticks: { color: 'rgba(255,255,255,0.40)', font: { size: 10 } },
          border: { display: false }
        }
      }
    }
  });

  // Build custom legend
  const legend = document.getElementById('chart-legend');
  if (legend) {
    const items = [
      { label: 'Critical', color: '#f05f7e' },
      { label: 'Warning',  color: '#f5a623' },
      { label: 'Resolved', color: '#30d158' }
    ];
    legend.innerHTML = items.map(i => `
      <div class="chart-legend-item">
        <div class="chart-legend-dot" style="background:${i.color}"></div>
        ${i.label}
      </div>
    `).join('');
  }
}

/* ── Recent Activity ── */
function initActivity() {
  const list = document.getElementById('activity-list');
  if (!list) return;

  const activities = [
    { icon: 'ph-siren',         color: '#f05f7e', bg: 'rgba(240,95,126,0.15)', title: 'Armed Threat Reported',          desc: 'Jalan Bukit Seguntang, Alor Gajah', time: '2m ago' },
    { icon: 'ph-fire',          color: '#f5a623', bg: 'rgba(245,166,35,0.15)',  title: 'Fire Incident — Sector 4A',      desc: 'Near Pekan Alor Gajah',             time: '8m ago' },
    { icon: 'ph-check-circle',  color: '#30d158', bg: 'rgba(48,209,88,0.15)',   title: 'Report #INC-0882 Resolved',      desc: 'Officer Unit 3 confirmed',          time: '15m ago' },
    { icon: 'ph-warning-circle',color: '#f5a623', bg: 'rgba(245,166,35,0.15)',  title: 'Crowd Surge Detected',           desc: 'Main Square North',                 time: '22m ago' },
    { icon: 'ph-ambulance',     color: '#5b8dee', bg: 'rgba(91,141,238,0.15)',  title: 'Medical Emergency',              desc: 'Taman Bahera residential block',    time: '35m ago' },
  ];

  list.innerHTML = activities.map(a => `
    <li class="activity-item" role="listitem">
      <div class="activity-icon-wrap" style="background:${a.bg}; color:${a.color}">
        <i class="ph ${a.icon}"></i>
      </div>
      <div class="activity-body">
        <p class="activity-title">${a.title}</p>
        <p class="activity-desc"><i class="ph ph-map-pin"></i> ${a.desc}</p>
      </div>
      <span class="activity-time">${a.time}</span>
    </li>
  `).join('');
}

/* ── Animated stat counters ── */
function animateCounter(el, target, duration = 1200) {
  let start = 0;
  const step = (timestamp) => {
    if (!start) start = timestamp;
    const progress = Math.min((timestamp - start) / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3);
    el.textContent = Math.floor(eased * target).toLocaleString();
    if (progress < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
}

function initCounters() {
  animateCounter(document.getElementById('val-total'),     1248);
  animateCounter(document.getElementById('val-emergency'),   24);
  animateCounter(document.getElementById('val-high'),        87);
}

/* ── Init ── */
document.addEventListener('DOMContentLoaded', () => {
  initChart();
  initActivity();
  initCounters();

  // Load MapLibre dynamically
  const script = document.createElement('script');
  script.src = 'https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.js';
  script.onload = initHomeMap;
  document.head.appendChild(script);

  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = 'https://unpkg.com/maplibre-gl@3.6.2/dist/maplibre-gl.css';
  document.head.appendChild(link);
});
