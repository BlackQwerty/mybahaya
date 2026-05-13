/* ============================================================
   users.js — Users Page Logic
   ============================================================ */

'use strict';

const dummyUsers = [
  { id: 1, name: 'Ahmad Faizal', email: 'ahmad@mybahaya.gov.my', role: 'admin', roleText: 'Administrator', status: 'active', lastLogin: 'Just now' },
  { id: 2, name: 'Siti Nurhaliza', email: 'siti.n@mybahaya.gov.my', role: 'analyst', roleText: 'Data Analyst', status: 'active', lastLogin: '2h ago' },
  { id: 3, name: 'Officer Lim', email: 'lim.k@mybahaya.gov.my', role: 'officer', roleText: 'Field Officer', status: 'active', lastLogin: '1d ago' },
  { id: 4, name: 'Raju Subramaniam', email: 'raju.s@mybahaya.gov.my', role: 'officer', roleText: 'Field Officer', status: 'inactive', lastLogin: '5d ago' },
];

function getAvatarColor(name) {
  const colors = ['#7c6cf8', '#5b8dee', '#32d4b4', '#f05f7e', '#f5a623'];
  const hash = name.charCodeAt(0) % colors.length;
  return colors[hash];
}

function renderUsers(users) {
  const tbody = document.getElementById('user-table-body');
  
  if (users.length === 0) {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:30px;color:rgba(255,255,255,0.5)">No users found matching your criteria.</td></tr>`;
    return;
  }

  tbody.innerHTML = users.map(u => `
    <tr>
      <td>
        <div class="u-profile">
          <div class="u-avatar" style="background:${getAvatarColor(u.name)}">${u.name.charAt(0)}</div>
          <div class="u-info">
            <span class="u-name">${u.name}</span>
            <span class="u-email">${u.email}</span>
          </div>
        </div>
      </td>
      <td><span class="u-role-text">${u.roleText}</span></td>
      <td>
        <span class="status-${u.status}"><span class="dot-indicator"></span>${u.status === 'active' ? 'Active' : 'Inactive'}</span>
      </td>
      <td style="font-size:12px;color:rgba(255,255,255,0.5)">${u.lastLogin}</td>
      <td>
        <div class="table-actions">
          <button class="btn-action" title="Edit User"><i class="ph ph-pencil-simple"></i></button>
          <button class="btn-action delete" title="Suspend User"><i class="ph ph-trash"></i></button>
        </div>
      </td>
    </tr>
  `).join('');
}

function initUserFilters() {
  const searchInput = document.getElementById('user-search');
  const roleSelect = document.getElementById('user-role-filter');

  const filterUsers = () => {
    const q = searchInput.value.toLowerCase();
    const r = roleSelect.value;
    
    const filtered = dummyUsers.filter(u => {
      const matchSearch = u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q);
      const matchRole = r === 'all' || u.role === r;
      return matchSearch && matchRole;
    });
    renderUsers(filtered);
  };

  searchInput.addEventListener('input', filterUsers);
  roleSelect.addEventListener('change', filterUsers);

  // Initial
  renderUsers(dummyUsers);
}

function initUserModal() {
  const modal = document.getElementById('modal-user');
  const btnOpen = document.getElementById('btn-add-user');
  const btnClose = document.getElementById('modal-close-user');
  const btnCancel = document.getElementById('modal-cancel-user');
  const form = document.getElementById('user-form');

  const openModal = () => modal.classList.remove('hidden');
  const closeModal = () => modal.classList.add('hidden');

  btnOpen.addEventListener('click', openModal);
  btnClose.addEventListener('click', closeModal);
  btnCancel.addEventListener('click', closeModal);

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    alert('User created successfully! (Mock)');
    closeModal();
    form.reset();
  });
}

document.addEventListener('DOMContentLoaded', () => {
  initUserFilters();
  initUserModal();
});
