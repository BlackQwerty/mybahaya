/* ============================================================
   report.js — Report Page Logic
   ============================================================ */

'use strict';

const dummyReports = [
  { id: 'INC-1042', type: 'Armed Threat', loc: 'Alor Gajah, Melaka', desc: 'Group of armed individuals spotted targeting people nearby. Require immediate police backup.', severity: 'critical', status: 'active', time: '10m ago' },
  { id: 'INC-1041', type: 'Fire', loc: 'Taman Melaka Perdana', desc: 'Large smoke pillar observed from residential area. Fire truck requested.', severity: 'critical', status: 'active', time: '25m ago' },
  { id: 'INC-1040', type: 'Suspicious Activity', loc: 'UiTM Lendu Campus', desc: 'Unidentified vehicle circling parking lot C multiple times.', severity: 'warning', status: 'pending', time: '1h ago' },
  { id: 'INC-1039', type: 'Traffic Accident', loc: 'Lebuh AMJ KM 21', desc: 'Two car collision blocking left lane. No visible injuries, but traffic is building up.', severity: 'warning', status: 'active', time: '2h ago' },
  { id: 'INC-1038', type: 'Medical Emergency', loc: 'Hospital Alor Gajah', desc: 'Patient requires urgent transfer. Ambulance dispatched.', severity: 'resolved', status: 'resolved', time: '5h ago' },
  { id: 'INC-1037', type: 'Flooding', loc: 'Kampung Paya Datuk', desc: 'Water level rising rapidly near the river bank. Evacuation warning issued.', severity: 'critical', status: 'active', time: '1d ago' },
];

function getBadge(severity, status) {
  if (status === 'resolved') return '<span class="badge badge-success"><ion-icon name="checkmark-circle"></ion-icon> Resolved</span>';
  if (severity === 'critical') return '<span class="badge badge-critical"><ion-icon name="warning"></ion-icon> Critical</span>';
  if (severity === 'warning') return '<span class="badge badge-warning"><ion-icon name="alert-circle"></ion-icon> Warning</span>';
  return '<span class="badge badge-info"><ion-icon name="information-circle"></ion-icon> Pending</span>';
}

function renderReports(reports) {
  const grid = document.getElementById('reports-grid');
  const empty = document.getElementById('empty-state');
  
  if (reports.length === 0) {
    grid.innerHTML = '';
    empty.classList.remove('hidden');
    return;
  }
  
  empty.classList.add('hidden');
  grid.innerHTML = reports.map((r, i) => `
    <div class="glass-card report-card fade-in" style="animation-delay: ${i * 0.05}s">
      <div class="rc-header">
        <div>
          <span class="rc-id">${r.id}</span>
          <h3 class="rc-title">${r.type}</h3>
        </div>
        ${getBadge(r.severity, r.status)}
      </div>
      <div class="rc-meta">
        <span><ion-icon name="location-outline"></ion-icon> ${r.loc}</span>
        <span><ion-icon name="time-outline"></ion-icon> ${r.time}</span>
      </div>
      <p class="rc-body"><strong>Details:</strong><br/>${r.desc}</p>
      <div class="rc-footer">
        <button class="btn btn-glass" style="font-size:var(--fs-xs); padding:6px 12px">View Details</button>
      </div>
    </div>
  `).join('');
}

function initFilters() {
  const searchInput = document.getElementById('report-search');
  const chips = document.querySelectorAll('.chip');
  const sortSelect = document.getElementById('report-sort');
  const btnClear = document.getElementById('btn-clear-filter');

  let currentFilter = 'all';
  let currentSearch = '';

  const filterData = () => {
    let filtered = dummyReports.filter(r => {
      const matchSearch = r.type.toLowerCase().includes(currentSearch) || 
                          r.loc.toLowerCase().includes(currentSearch) || 
                          r.id.toLowerCase().includes(currentSearch) ||
                          r.desc.toLowerCase().includes(currentSearch);
      
      let matchFilter = true;
      if (currentFilter === 'critical') matchFilter = r.severity === 'critical' && r.status !== 'resolved';
      else if (currentFilter === 'warning') matchFilter = r.severity === 'warning' && r.status !== 'resolved';
      else if (currentFilter === 'resolved') matchFilter = r.status === 'resolved';
      else if (currentFilter === 'pending') matchFilter = r.status === 'pending';

      return matchSearch && matchFilter;
    });

    // Dummy sort logic
    if (sortSelect.value === 'oldest') {
      filtered = filtered.reverse();
    } else if (sortSelect.value === 'severity') {
      const sevMap = { 'critical': 3, 'warning': 2, 'low': 1, 'resolved': 0 };
      filtered.sort((a, b) => sevMap[b.severity] - sevMap[a.severity]);
    }

    renderReports(filtered);
  };

  searchInput.addEventListener('input', (e) => {
    currentSearch = e.target.value.toLowerCase();
    filterData();
  });

  chips.forEach(chip => {
    chip.addEventListener('click', (e) => {
      chips.forEach(c => c.classList.remove('active'));
      e.target.classList.add('active');
      currentFilter = e.target.dataset.filter;
      filterData();
    });
  });

  sortSelect.addEventListener('change', filterData);

  btnClear.addEventListener('click', () => {
    searchInput.value = '';
    currentSearch = '';
    chips.forEach(c => c.classList.remove('active'));
    document.querySelector('.chip[data-filter="all"]').classList.add('active');
    currentFilter = 'all';
    sortSelect.value = 'newest';
    filterData();
  });

  // Initial render
  filterData();
}

function initModal() {
  const modal = document.getElementById('modal-overlay');
  const btnOpen = document.getElementById('btn-new-report');
  const btnClose = document.getElementById('modal-close');
  const btnCancel = document.getElementById('modal-cancel');
  const form = document.getElementById('report-form');

  const openModal = () => modal.classList.remove('hidden');
  const closeModal = () => modal.classList.add('hidden');

  btnOpen.addEventListener('click', openModal);
  btnClose.addEventListener('click', closeModal);
  btnCancel.addEventListener('click', closeModal);

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    alert('Report submitted successfully! (Mock)');
    closeModal();
    form.reset();
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initFilters();
  initModal();
});
