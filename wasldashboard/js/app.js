// Wasl Admin Dashboard - Main Application Orchestrator
import { AuthManager } from './auth.js';
import { UsersManager } from './users.js';
import { OrdersManager } from './orders.js';
import { ComplaintsManager } from './complaints.js';

class App {
  constructor() {
    this.authMgr = new AuthManager();
    this.usersMgr = new UsersManager(this);
    this.ordersMgr = new OrdersManager(this);
    this.complaintsMgr = new ComplaintsManager(this);

    // Expose managers globally for inline HTML onclick handlers
    window.usersMgr = this.usersMgr;
    window.ordersMgr = this.ordersMgr;
    window.complaintsMgr = this.complaintsMgr;
    window.app = this;

    this.init();
  }

  init() {
    this.bindEvents();

    if (this.authMgr.initSession()) {
      this.showApp();
    } else {
      this.showLogin();
    }
  }

  bindEvents() {
    // Admin Login Form
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
      loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const username = document.getElementById('login-username').value;
        const pass = document.getElementById('login-password').value;

        const res = await this.authMgr.login(username, pass);
        if (res.success) {
          this.showToast('تم تسجيل الدخول بنجاح', 'success');
          this.showApp();
        } else {
          this.showToast(res.message, 'error');
        }
      });
    }

    // Logout Button
    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', () => this.authMgr.logout());
    }

    // Sidebar Navigation Tabs
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
      item.addEventListener('click', () => {
        const targetTab = item.getAttribute('data-tab');
        this.switchTab(targetTab);
      });
    });

    // Refresh Button
    const refreshBtn = document.getElementById('refresh-data-btn');
    if (refreshBtn) {
      refreshBtn.addEventListener('click', () => {
        this.showToast('جاري إعادة مزامنة البيانات...', 'info');
        this.initAllListeners();
      });
    }

    // User Status Filter Toggles (All, Active, Blocked)
    const filterBtns = document.querySelectorAll('.user-filter-btn');
    filterBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        filterBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const filterType = btn.getAttribute('data-filter');
        this.usersMgr.setFilter(filterType);
      });
    });

    // Quick Account Recovery Widget Search Button
    const quickSearchBtn = document.getElementById('quick-search-btn');
    const quickSearchInput = document.getElementById('quick-search-input');
    if (quickSearchBtn && quickSearchInput) {
      const handleQuickSearch = () => {
        const queryStr = quickSearchInput.value.trim();
        if (queryStr) {
          this.switchTab('tab-users');
          const usersSearchInput = document.getElementById('users-search-input');
          if (usersSearchInput) {
            usersSearchInput.value = queryStr;
            this.usersMgr.searchUsers(queryStr);
          }
        }
      };
      quickSearchBtn.addEventListener('click', handleQuickSearch);
      quickSearchInput.addEventListener('keyup', (e) => {
        if (e.key === 'Enter') handleQuickSearch();
      });
    }

    // Users Search Input Listener
    const usersSearchInput = document.getElementById('users-search-input');
    if (usersSearchInput) {
      usersSearchInput.addEventListener('input', (e) => {
        this.usersMgr.searchUsers(e.target.value);
      });
    }

    // Orders Filter Dropdown Listener
    const ordersFilter = document.getElementById('orders-filter-status');
    if (ordersFilter) {
      ordersFilter.addEventListener('change', (e) => {
        this.ordersMgr.filterOrders(e.target.value);
      });
    }

    // Edit User Form Listener
    const editUserForm = document.getElementById('edit-user-form');
    if (editUserForm) {
      editUserForm.addEventListener('submit', (e) => this.usersMgr.saveUserEdit(e));
    }
  }

  showLogin() {
    document.getElementById('login-screen').style.display = 'flex';
    document.getElementById('app-root').style.display = 'none';
  }

  showApp() {
    document.getElementById('login-screen').style.display = 'none';
    document.getElementById('app-root').style.display = 'flex';

    // Set Admin Profile Info in Sidebar
    const admin = this.authMgr.currentAdmin;
    if (admin) {
      document.getElementById('admin-display-name').innerText = admin.name || admin.username;
      document.getElementById('admin-display-role').innerText = admin.role || 'Super Admin';
      document.getElementById('admin-avatar-char').innerText = (admin.name || admin.username || 'A').charAt(0).toUpperCase();
    }

    // Launch real-time listeners
    this.initAllListeners();
  }

  initAllListeners() {
    this.usersMgr.initUsersListener();
    this.ordersMgr.initOrdersListener();
    this.complaintsMgr.initComplaintsListener();
  }

  switchTab(tabId) {
    document.querySelectorAll('.nav-item').forEach(el => {
      if (el.getAttribute('data-tab') === tabId) {
        el.classList.add('active');
        document.getElementById('current-tab-title').innerText = el.querySelector('span').innerText;
      } else {
        el.classList.remove('active');
      }
    });

    document.querySelectorAll('.tab-content').forEach(content => {
      if (content.id === tabId) {
        content.classList.add('active');
      } else {
        content.classList.remove('active');
      }
    });
  }

  updateUserStats(users) {
    const totalEl = document.getElementById('stat-total-users');
    const blockedEl = document.getElementById('stat-blocked-users');
    if (totalEl) totalEl.innerText = users.length;
    if (blockedEl) blockedEl.innerText = users.filter(u => u.isBlocked).length;
  }

  updateOrderStats(orders) {
    const activeEl = document.getElementById('stat-active-orders');
    const revenueEl = document.getElementById('stat-total-revenue');

    if (activeEl) {
      const activeCount = orders.filter(o => ['pending', 'preparing', 'delivering'].includes(o.status.toLowerCase())).length;
      activeEl.innerText = activeCount;
    }

    if (revenueEl) {
      const totalRev = orders
        .filter(o => o.status.toLowerCase() === 'delivered' || o.status.toLowerCase() === 'completed')
        .reduce((sum, o) => sum + (Number(o.totalAmount) || 0), 0);
      revenueEl.innerText = `${totalRev.toLocaleString('ar-SA')} ر.ي`;
    }
  }

  openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.add('active');
  }

  closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.remove('active');
  }

  showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    
    let icon = 'fa-circle-info';
    if (type === 'success') icon = 'fa-circle-check';
    if (type === 'error') icon = 'fa-circle-exclamation';

    toast.innerHTML = `<i class="fa-solid ${icon}"></i> <span>${message}</span>`;
    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateX(-20px)';
      setTimeout(() => toast.remove(), 300);
    }, 3500);
  }
}

// Global Modal Helper
window.closeModal = (id) => {
  if (window.app) window.app.closeModal(id);
};

// Global Tab Switcher Helper
window.switchTab = (tabId) => {
  if (window.app) window.app.switchTab(tabId);
};

// Launch Application
document.addEventListener('DOMContentLoaded', () => {
  new App();
});
