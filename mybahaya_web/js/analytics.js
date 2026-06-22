/* ============================================================
   analytics.js — Analytics Page  |  All data from Firestore
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
const DAYS_LABEL = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
const MONTHS     = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

function catMeta(cat) { return CAT_META[cat] || CAT_META.Other; }

function fmtDatetime(ts) {
  if (!ts) return '—';
  const d = ts.toDate ? ts.toDate() : new Date(ts);
  const hh = String(d.getHours()).padStart(2,'0');
  const mm = String(d.getMinutes()).padStart(2,'0');
  return `${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}, ${hh}:${mm}`;
}

function shortId(id) { return (id || '').slice(0,8).toUpperCase(); }

/* ── Animated counter ── */
function animateNum(el, target, decimals = 0) {
  if (!el) return;
  let start = null;
  const step = ts => {
    if (!start) start = ts;
    const p = Math.min((ts - start) / 700, 1);
    const v = (1 - Math.pow(1 - p, 3)) * target;
    el.textContent = decimals ? v.toFixed(decimals) : Math.floor(v).toLocaleString();
    if (p < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
}

/* Chart instances — destroyed before redraw */
const charts = {};
function destroyChart(key) { if (charts[key]) { charts[key].destroy(); charts[key] = null; } }

/* ── Shared chart theme ── */
const TOOLTIP = {
  backgroundColor: 'rgba(15,15,26,0.95)',
  borderColor: 'rgba(255,255,255,0.10)',
  borderWidth: 1,
  titleColor: 'rgba(255,255,255,0.80)',
  bodyColor:  'rgba(255,255,255,0.60)',
  padding: 12, cornerRadius: 10,
};
const AXIS_X = {
  grid:   { display: false },
  ticks:  { color: 'rgba(255,255,255,0.35)', font: { size: 10 } },
  border: { display: false },
};
const AXIS_Y = {
  grid:   { color: 'rgba(255,255,255,0.04)' },
  ticks:  { color: 'rgba(255,255,255,0.35)', font: { size: 10 }, precision: 0 },
  border: { display: false },
  beginAtZero: true,
};

/* ══════════════════════════════════════════════════════════
   STATE
   ══════════════════════════════════════════════════════════ */
let allReports = [];
let currentDays = 30;

function getFiltered() {
  if (!currentDays) return allReports;
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - currentDays);
  cutoff.setHours(0, 0, 0, 0);
  return allReports.filter(r => {
    const dt = r.createdAt?.toDate?.();
    return dt && dt >= cutoff;
  });
}

/* ══════════════════════════════════════════════════════════
   1. KPI CARDS
   ══════════════════════════════════════════════════════════ */
function renderKPIs(reports) {
  const today = new Date(); today.setHours(0,0,0,0);
  const todayN = reports.filter(r => {
    const dt = r.createdAt?.toDate?.();
    return dt && dt >= today;
  }).length;

  const days = currentDays || (() => {
    if (!reports.length) return 1;
    const dates = reports.map(r => r.createdAt?.toDate?.()?.getTime()).filter(Boolean);
    const span  = (Math.max(...dates) - Math.min(...dates)) / 86400000;
    return Math.max(span, 1);
  })();

  const avg  = reports.length / (currentDays || Math.max(days, 1));

  animateNum(document.getElementById('kpi-total'), reports.length);
  animateNum(document.getElementById('kpi-today'), todayN);
  animateNum(document.getElementById('kpi-avg'), avg, 1);

  const meta = document.getElementById('kpi-total-meta');
  if (meta) meta.textContent = currentDays ? `in last ${currentDays} days` : 'all time';

  /* Top category */
  const counts = {};
  reports.forEach(r => {
    const c = r.category in CAT_META ? r.category : 'Other';
    counts[c] = (counts[c] || 0) + 1;
  });
  const topCat = Object.entries(counts).sort((a,b) => b[1]-a[1])[0];
  const topEl  = document.getElementById('kpi-top-cat');
  const cntEl  = document.getElementById('kpi-top-cat-count');
  if (topEl) topEl.textContent = topCat ? topCat[0] : '—';
  if (cntEl) cntEl.textContent = topCat ? `${topCat[1]} reports` : 'no data';
}

/* ══════════════════════════════════════════════════════════
   2. DAILY TREND CHART
   ══════════════════════════════════════════════════════════ */
function renderTrend(reports) {
  const ctx = document.getElementById('trendChart');
  if (!ctx) return;
  destroyChart('trend');

  const numDays = currentDays || 30;
  const days    = [];
  const labels  = [];
  for (let i = numDays - 1; i >= 0; i--) {
    const d = new Date(); d.setHours(0,0,0,0); d.setDate(d.getDate() - i);
    days.push(d);
    labels.push(numDays <= 14
      ? `${d.getDate()} ${MONTHS[d.getMonth()]}`
      : (d.getDate() === 1 || i === numDays - 1 ? `${d.getDate()} ${MONTHS[d.getMonth()]}` : `${d.getDate()}`)
    );
  }

  /* Count per day per category */
  const catKeys = Object.keys(CAT_META);
  const series  = {};
  catKeys.forEach(cat => { series[cat] = new Array(numDays).fill(0); });
  reports.forEach(r => {
    const dt = r.createdAt?.toDate?.();
    if (!dt) return;
    const cat = r.category in series ? r.category : 'Other';
    for (let i = 0; i < numDays; i++) {
      const end = new Date(days[i]); end.setDate(end.getDate() + 1);
      if (dt >= days[i] && dt < end) { series[cat][i]++; break; }
    }
  });

  /* Stacked bar */
  const datasets = catKeys.map(cat => ({
    label: catMeta(cat).label,
    data: series[cat],
    backgroundColor: catMeta(cat).color + 'cc',
    borderRadius: 3,
    borderSkipped: false,
  }));

  charts.trend = new Chart(ctx, {
    type: 'bar',
    data: { labels, datasets },
    options: {
      responsive: true, maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
      plugins: {
        legend: { display: false },
        tooltip: { ...TOOLTIP },
      },
      scales: {
        x: { ...AXIS_X, stacked: true },
        y: { ...AXIS_Y, stacked: true },
      },
    },
  });

  /* Legend */
  const leg = document.getElementById('trend-legend');
  if (leg) {
    leg.innerHTML = catKeys.map(cat => {
      const m = catMeta(cat);
      return `<div class="chart-legend-item">
        <div class="chart-legend-dot" style="background:${m.color}"></div>${m.label}
      </div>`;
    }).join('');
  }

  const sub = document.getElementById('trend-sub');
  if (sub) sub.textContent = currentDays ? `Stacked by category · last ${currentDays} days` : 'All time (last 30 days shown)';
}

/* ══════════════════════════════════════════════════════════
   3. DONUT CHART
   ══════════════════════════════════════════════════════════ */
function renderDonut(reports) {
  const ctx = document.getElementById('donutChart');
  if (!ctx) return;
  destroyChart('donut');

  const counts = {};
  Object.keys(CAT_META).forEach(c => { counts[c] = 0; });
  reports.forEach(r => {
    const c = r.category in counts ? r.category : 'Other';
    counts[c]++;
  });

  const catKeys = Object.keys(CAT_META).filter(c => counts[c] > 0);
  const data    = catKeys.map(c => counts[c]);
  const colors  = catKeys.map(c => catMeta(c).color);

  charts.donut = new Chart(ctx, {
    type: 'doughnut',
    data: { labels: catKeys, datasets: [{ data, backgroundColor: colors, borderWidth: 2, borderColor: 'rgba(15,15,26,0.8)', hoverOffset: 6 }] },
    options: {
      responsive: true, maintainAspectRatio: true,
      cutout: '72%',
      plugins: {
        legend: { display: false },
        tooltip: { ...TOOLTIP, callbacks: {
          label: ctx => ` ${ctx.label}: ${ctx.parsed} (${((ctx.parsed/reports.length)*100).toFixed(1)}%)`
        }},
      },
    },
  });

  /* Center total */
  const tot = document.getElementById('donut-total');
  if (tot) animateNum(tot, reports.length);

  /* Legend */
  const leg = document.getElementById('donut-legend');
  if (leg) {
    const total = reports.length || 1;
    leg.innerHTML = Object.entries(counts).map(([cat, n]) => {
      if (!n) return '';
      const m   = catMeta(cat);
      const pct = ((n / total) * 100).toFixed(1);
      return `<div class="donut-legend-item">
        <div class="donut-legend-dot" style="background:${m.color}"></div>
        ${m.label}
        <span class="donut-legend-right">${n} <span style="font-weight:400;color:rgba(255,255,255,0.35)">(${pct}%)</span></span>
      </div>`;
    }).join('');
  }
}

/* ══════════════════════════════════════════════════════════
   4. HOURLY PATTERN CHART
   ══════════════════════════════════════════════════════════ */
function renderHourly(reports) {
  const ctx = document.getElementById('hourlyChart');
  if (!ctx) return;
  destroyChart('hourly');

  const hourly = new Array(24).fill(0);
  reports.forEach(r => {
    const dt = r.createdAt?.toDate?.();
    if (dt) hourly[dt.getHours()]++;
  });

  const maxH   = hourly.indexOf(Math.max(...hourly));
  const colors = hourly.map((_, i) => i === maxH ? 'rgba(124,108,248,0.90)' : 'rgba(124,108,248,0.28)');

  charts.hourly = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: Array.from({length:24}, (_,i) => `${String(i).padStart(2,'0')}:00`),
      datasets: [{ data: hourly, backgroundColor: colors, borderRadius: 3, borderSkipped: false }],
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: { ...TOOLTIP, callbacks: { title: t => `${t[0].label}–${String(parseInt(t[0].label)+1).padStart(2,'0')}:00` }},
      },
      scales: {
        x: { ...AXIS_X },
        y: { ...AXIS_Y },
      },
    },
  });

  const badge = document.getElementById('peak-hour-badge');
  if (badge) {
    badge.innerHTML = `<ion-icon name="time-outline"></ion-icon> Peak: ${String(maxH).padStart(2,'0')}:00–${String(maxH+1).padStart(2,'0')}:00 (${hourly[maxH]} reports)`;
  }
}

/* ══════════════════════════════════════════════════════════
   5. CATEGORY DISTRIBUTION BARS
   ══════════════════════════════════════════════════════════ */
function renderCatBars(reports) {
  const el = document.getElementById('cat-dist-bars');
  if (!el) return;

  const total  = reports.length || 1;
  const counts = {};
  Object.keys(CAT_META).forEach(c => { counts[c] = 0; });
  reports.forEach(r => {
    const c = r.category in counts ? r.category : 'Other';
    counts[c]++;
  });

  const sorted = Object.entries(counts).sort((a,b) => b[1]-a[1]);

  el.innerHTML = sorted.map(([cat, n]) => {
    const m   = catMeta(cat);
    const pct = ((n / total) * 100).toFixed(1);
    return `
      <div class="cat-dist-row">
        <div class="cat-dist-head">
          <span class="cat-dist-name">
            <ion-icon name="${m.icon}" class="cat-dist-icon" style="color:${m.color}"></ion-icon>
            ${m.label}
          </span>
          <span>
            <span class="cat-dist-count">${n} reports &nbsp;</span>
            <span class="cat-dist-pct">${pct}%</span>
          </span>
        </div>
        <div class="cat-dist-bar-bg">
          <div class="cat-dist-bar-fill" style="width:${pct}%;background:${m.color}"></div>
        </div>
      </div>`;
  }).join('');
}

/* ══════════════════════════════════════════════════════════
   6. DAY OF WEEK CHART
   ══════════════════════════════════════════════════════════ */
function renderDow(reports) {
  const ctx = document.getElementById('dowChart');
  if (!ctx) return;
  destroyChart('dow');

  const dow = new Array(7).fill(0);
  reports.forEach(r => {
    const dt = r.createdAt?.toDate?.();
    if (dt) dow[dt.getDay()]++;
  });

  /* Reorder Mon–Sun */
  const ordered = [1,2,3,4,5,6,0];
  const data    = ordered.map(d => dow[d]);
  const labels  = ordered.map(d => DAYS_LABEL[d]);
  const maxIdx  = data.indexOf(Math.max(...data));
  const colors  = data.map((_, i) => i === maxIdx ? 'rgba(255,107,53,0.90)' : 'rgba(255,107,53,0.28)');

  charts.dow = new Chart(ctx, {
    type: 'bar',
    data: {
      labels,
      datasets: [{ data, backgroundColor: colors, borderRadius: 4, borderSkipped: false }],
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false }, tooltip: { ...TOOLTIP } },
      scales: {
        x: { ...AXIS_X },
        y: { ...AXIS_Y },
      },
    },
  });
}

/* ══════════════════════════════════════════════════════════
   7. REPORTS TABLE
   ══════════════════════════════════════════════════════════ */
function renderTable(reports) {
  const tbody = document.getElementById('reports-tbody');
  if (!tbody) return;

  const sorted = [...reports]
    .filter(r => r.createdAt)
    .sort((a,b) => (b.createdAt?.toMillis?.() ?? 0) - (a.createdAt?.toMillis?.() ?? 0))
    .slice(0, 25);

  const sub = document.getElementById('table-sub');
  if (sub) sub.textContent = `Showing ${sorted.length} most recent · ${reports.length} total in period`;

  if (!sorted.length) {
    tbody.innerHTML = `<tr><td colspan="5" class="table-loading">No reports in this period</td></tr>`;
    return;
  }

  tbody.innerHTML = sorted.map(r => {
    const m   = catMeta(r.category);
    const lat = r.location?.latitude;
    const lng = r.location?.longitude;
    const loc = (lat != null && lng != null)
      ? `<span class="loc-text">${lat.toFixed(4)}, ${lng.toFixed(4)}</span>`
      : `<span class="no-loc-text">No location</span>`;

    const detail = r.details
      ? (r.details.length > 55 ? r.details.slice(0,55) + '…' : r.details)
      : '<span style="color:rgba(255,255,255,0.25);font-style:italic">—</span>';

    return `
      <tr>
        <td style="font-family:monospace;font-size:11px;font-weight:600">#${shortId(r.reportId||r.id)}</td>
        <td>
          <span class="cat-badge" style="color:${m.color};border-color:${m.border};background:${m.bg}">
            <ion-icon name="${m.icon}" style="font-size:12px"></ion-icon> ${m.label}
          </span>
        </td>
        <td style="font-size:12px;color:rgba(255,255,255,0.65);max-width:260px">${detail}</td>
        <td>${loc}</td>
        <td style="font-size:11px;color:rgba(255,255,255,0.45);white-space:nowrap">${fmtDatetime(r.createdAt)}</td>
      </tr>`;
  }).join('');
}

/* ══════════════════════════════════════════════════════════
   RENDER ALL
   ══════════════════════════════════════════════════════════ */
function renderAll() {
  const reports = getFiltered();
  renderKPIs(reports);
  renderTrend(reports);
  renderDonut(reports);
  renderHourly(reports);
  renderCatBars(reports);
  renderDow(reports);
  renderTable(reports);
}

/* ══════════════════════════════════════════════════════════
   CSV EXPORT
   ══════════════════════════════════════════════════════════ */
function exportCSV() {
  const reports = getFiltered();
  const rows = [
    ['ID','Category','Details','Latitude','Longitude','DateTime'],
    ...reports.map(r => [
      shortId(r.reportId || r.id),
      r.category || '',
      (r.details || '').replace(/,/g, ';'),
      r.location?.latitude ?? '',
      r.location?.longitude ?? '',
      fmtDatetime(r.createdAt),
    ])
  ];
  const csv  = rows.map(r => r.join(',')).join('\n');
  const blob = new Blob([csv], { type: 'text/csv' });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href = url;
  a.download = `mybahaya-reports-${new Date().toISOString().slice(0,10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

/* ══════════════════════════════════════════════════════════
   INIT
   ══════════════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', () => {

  document.getElementById('timeframe-select')?.addEventListener('change', e => {
    currentDays = parseInt(e.target.value) || 0;
    renderAll();
  });

  document.getElementById('export-btn')?.addEventListener('click', exportCSV);

  // Admins see all reports; org users see only reports assigned to their org.
  (window.authReady || Promise.resolve()).then(() => {
    let query = db.collection('reports');
    const org = window.currentUserOrg;
    if (org && !window.currentUserIsAdmin) {
      query = query.where('assignedOrgId', '==', org.id);
    }
    query.onSnapshot(snap => {
      allReports = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      renderAll();
    }, err => console.error('Analytics listener:', err));
  });

});
