// Wasl Admin Dashboard - User Management & Real-Time Account Recovery & Blocking Engine
import { db, collection, onSnapshot, doc, updateDoc, deleteDoc } from './firebase-config.js';

export class UsersManager {
  constructor(appInstance) {
    this.app = appInstance;
    this.users = [];
    this.filteredUsers = [];
    this.unsubscribeListener = null;
    this.activeFilter = 'ALL';
    this.searchTerm = '';
    this.selectedUser = null;
    this.isPasswordVisible = false;
  }

  // Subscribe to real-time updates from Firestore 'customers' collection
  initUsersListener() {
    if (this.unsubscribeListener) {
      this.unsubscribeListener();
    }

    try {
      const q = collection(db, 'customers');
      this.unsubscribeListener = onSnapshot(q, (snapshot) => {
        this.users = snapshot.docs.map(docSnap => {
          const data = docSnap.data();
          let createdDate = 'غير محدد';
          if (data.createdAt && typeof data.createdAt.toDate === 'function') {
            createdDate = data.createdAt.toDate().toLocaleDateString('ar-SA', {
              year: 'numeric', month: 'short', day: 'numeric'
            });
          }

          // Strict boolean evaluation for isBlocked
          const isBlocked = (data.isBlocked === true || data.isBlocked === 'true');

          return {
            id: docSnap.id,
            username: data.username || 'بدون اسم مستخدم',
            fullName: data.fullName || 'عميل وصل',
            phone: data.phone || 'غير مسجل',
            email: data.email || 'غير مسجل',
            address: data.address || 'لم يحدد عنوان',
            password: data.password || '••••••••',
            isBlocked: isBlocked,
            createdAtStr: createdDate,
            rawCreatedAt: data.createdAt
          };
        });

        // Sort users descending by creation timestamp (newest first)
        this.users.sort((a, b) => {
          const timeA = a.rawCreatedAt && typeof a.rawCreatedAt.toDate === 'function' ? a.rawCreatedAt.toDate().getTime() : 0;
          const timeB = b.rawCreatedAt && typeof b.rawCreatedAt.toDate === 'function' ? b.rawCreatedAt.toDate().getTime() : 0;
          return timeB - timeA;
        });

        this.applyFilterAndSearch();
        this.renderRecentUsersDashboard();
        this.app.updateUserStats(this.users);
      }, (error) => {
        console.error('Error in real-time users listener:', error);
      });
    } catch (e) {
      console.error('Failed to init users listener:', e);
    }
  }

  // Filter and Search processor
  applyFilterAndSearch() {
    let result = [...this.users];

    // Filter by Blocked status
    if (this.activeFilter === 'ACTIVE') {
      result = result.filter(u => !u.isBlocked);
    } else if (this.activeFilter === 'BLOCKED') {
      result = result.filter(u => u.isBlocked);
    }

    // Search by Term
    const term = this.searchTerm.trim().toLowerCase();
    if (term) {
      result = result.filter(u => 
        u.phone.toLowerCase().includes(term) ||
        u.username.toLowerCase().includes(term) ||
        u.fullName.toLowerCase().includes(term) ||
        u.email.toLowerCase().includes(term) ||
        u.id.toLowerCase().includes(term)
      );
    }

    this.filteredUsers = result;
    this.renderUsersTable();
  }

  setFilter(filterType) {
    this.activeFilter = filterType;
    this.applyFilterAndSearch();
  }

  searchUsers(term) {
    this.searchTerm = term;
    this.applyFilterAndSearch();
  }

  // Render main users data table with bulletproof click handlers
  renderUsersTable() {
    const tbody = document.getElementById('users-table-body');
    if (!tbody) return;

    if (this.filteredUsers.length === 0) {
      tbody.innerHTML = `
        <tr>
          <td colspan="7" style="text-align: center; color: var(--text-muted); padding: 36px;">
            <i class="fa-solid fa-user-xmark" style="font-size: 36px; margin-bottom: 12px; display: block; color: var(--status-warning);"></i>
            لم يتم العثور على أي حسابات تطابق شروط البحث أو الفرز
          </td>
        </tr>
      `;
      return;
    }

    tbody.innerHTML = this.filteredUsers.map(u => {
      const safeId = u.id.replace(/'/g, "\\'");
      return `
        <tr style="${u.isBlocked ? 'background: rgba(239, 68, 68, 0.08);' : ''}">
          <td style="font-weight: 700;">${u.fullName}</td>
          <td>
            <span style="font-family: monospace; color: var(--accent-secondary); font-weight: 600;">
              <i class="fa-solid fa-phone" style="font-size: 11px; margin-left: 4px;"></i>${u.phone}
            </span>
          </td>
          <td>
            <span class="badge badge-username">
              <i class="fa-solid fa-user" style="font-size: 10px;"></i> ${u.username}
            </span>
          </td>
          <td style="font-size: 13px; color: var(--text-secondary);">${u.email}</td>
          <td>
            ${u.isBlocked 
              ? '<span class="badge badge-danger"><i class="fa-solid fa-ban"></i> محظور</span>'
              : '<span class="badge badge-success"><i class="fa-solid fa-circle-check"></i> نشط</span>'}
          </td>
          <td style="font-size: 12px; color: var(--text-muted);">${u.createdAtStr}</td>
          <td>
            <div style="display: flex; gap: 6px; justify-content: center; align-items: center;">
              <button class="btn btn-primary btn-icon" onclick="window.usersMgr.showAccountRecoveryModal('${safeId}')" title="عرض واسترجاع اسم المستخدم والاعتماد">
                <i class="fa-solid fa-key"></i>
              </button>
              
              <!-- Direct Action Block/Unblock Button -->
              <button class="btn ${u.isBlocked ? 'btn-primary' : 'btn-danger'}" 
                      style="padding: 6px 12px; font-size: 12px;" 
                      onclick="window.usersMgr.toggleBlockUser('${safeId}')" 
                      title="${u.isBlocked ? 'فك حظر الحساب' : 'حظر الحساب'}">
                <i class="fa-solid ${u.isBlocked ? 'fa-unlock' : 'fa-ban'}"></i>
                ${u.isBlocked ? 'فك الحظر' : 'حظر الحساب'}
              </button>

              <button class="btn btn-secondary btn-icon" onclick="window.usersMgr.openEditUserModal('${safeId}')" title="تعديل الحساب">
                <i class="fa-solid fa-pen-to-square"></i>
              </button>
              <button class="btn btn-danger btn-icon" onclick="window.usersMgr.deleteUser('${safeId}')" title="حذف الحساب نهائياً">
                <i class="fa-solid fa-trash"></i>
              </button>
            </div>
          </td>
        </tr>
      `;
    }).join('');
  }

  // Render recent users in dashboard overview
  renderRecentUsersDashboard() {
    const tbody = document.getElementById('dashboard-recent-users');
    if (!tbody) return;

    const recent = this.users.slice(0, 6);
    if (recent.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" style="text-align: center;">لا يوجد مستخدمين مسجلين بعد</td></tr>';
      return;
    }

    tbody.innerHTML = recent.map(u => {
      const safeId = u.id.replace(/'/g, "\\'");
      return `
        <tr>
          <td style="font-weight: 700;">${u.fullName}</td>
          <td>${u.phone}</td>
          <td><span class="badge badge-username">${u.username}</span></td>
          <td>
            ${u.isBlocked 
              ? '<span class="badge badge-danger">محظور</span>'
              : '<span class="badge badge-success">نشط</span>'}
          </td>
          <td>${u.createdAtStr}</td>
          <td>
            <div style="display: flex; gap: 6px;">
              <button class="btn btn-primary" style="padding: 6px 10px; font-size: 12px;" onclick="window.usersMgr.showAccountRecoveryModal('${safeId}')">
                <i class="fa-solid fa-key"></i> استرجاع
              </button>
              <button class="btn ${u.isBlocked ? 'btn-secondary' : 'btn-danger'}" style="padding: 6px 10px; font-size: 12px;" onclick="window.usersMgr.toggleBlockUser('${safeId}')">
                <i class="fa-solid ${u.isBlocked ? 'fa-unlock' : 'fa-ban'}"></i> ${u.isBlocked ? 'فك حظر' : 'حظر'}
              </button>
            </div>
          </td>
        </tr>
      `;
    }).join('');
  }

  // Show Account Recovery Details Modal
  showAccountRecoveryModal(userId) {
    const user = this.users.find(u => u.id === userId);
    if (!user) return;

    this.selectedUser = user;
    this.isPasswordVisible = false;

    document.getElementById('rec-username').innerText = user.username;
    document.getElementById('rec-password').innerText = '••••••••';
    document.getElementById('rec-phone').innerText = user.phone;
    document.getElementById('rec-email').innerText = user.email;
    document.getElementById('rec-fullname').innerText = user.fullName;
    document.getElementById('rec-address').innerText = user.address;
    document.getElementById('rec-date').innerText = user.createdAtStr;
    
    const statusSpan = document.getElementById('rec-status');
    statusSpan.innerHTML = user.isBlocked 
      ? '<span class="badge badge-danger"><i class="fa-solid fa-ban"></i> محظور من الدخول</span>'
      : '<span class="badge badge-success"><i class="fa-solid fa-circle-check"></i> نشط ومسوح</span>';

    // Copy Username Action
    const copyUserBtn = document.getElementById('copy-username-btn');
    copyUserBtn.onclick = () => {
      navigator.clipboard.writeText(user.username);
      this.app.showToast(`تم نسخ اسم المستخدم (${user.username}) بنجاح 👍`, 'success');
    };

    // Toggle Password Visibility Action
    const togglePassBtn = document.getElementById('toggle-password-btn');
    togglePassBtn.onclick = () => {
      this.isPasswordVisible = !this.isPasswordVisible;
      const passSpan = document.getElementById('rec-password');
      if (this.isPasswordVisible) {
        passSpan.innerText = user.password;
        togglePassBtn.innerHTML = '<i class="fa-regular fa-eye-slash"></i>';
      } else {
        passSpan.innerText = '••••••••';
        togglePassBtn.innerHTML = '<i class="fa-regular fa-eye"></i>';
      }
    };

    // Toggle Block button inside recovery modal
    const toggleBlockBtn = document.getElementById('rec-toggle-block-btn');
    toggleBlockBtn.className = user.isBlocked ? 'btn btn-primary' : 'btn btn-danger';
    toggleBlockBtn.innerHTML = user.isBlocked 
      ? '<i class="fa-solid fa-unlock"></i> فك حظر هذا الحساب الان'
      : '<i class="fa-solid fa-ban"></i> حظر هذا الحساب الان';
    
    toggleBlockBtn.onclick = () => {
      this.toggleBlockUser(user.id);
      this.app.closeModal('user-recovery-modal');
    };

    // View Customer Orders History button
    const viewOrdersBtn = document.getElementById('rec-view-orders-btn');
    viewOrdersBtn.onclick = () => {
      this.app.closeModal('user-recovery-modal');
      this.showCustomerOrderHistory(user);
    };

    // Edit User button
    document.getElementById('edit-user-from-rec-btn').onclick = () => {
      this.app.closeModal('user-recovery-modal');
      this.openEditUserModal(user.id);
    };

    this.app.openModal('user-recovery-modal');
  }

  // Guaranteed Account Block / Unblock function with direct Firestore update
  async toggleBlockUser(userId) {
    const user = this.users.find(u => u.id === userId);
    if (!user) {
      this.app.showToast('تعذر العثور على الحساب المربوط', 'error');
      return;
    }

    const currentBlocked = (user.isBlocked === true);
    const newBlockedState = !currentBlocked;
    const actionText = newBlockedState ? 'حظر' : 'فك حظر';

    try {
      // Direct Firestore document update
      const userRef = doc(db, 'customers', userId);
      await updateDoc(userRef, {
        isBlocked: newBlockedState
      });

      // Update local state instantly as fallback
      user.isBlocked = newBlockedState;
      this.applyFilterAndSearch();
      this.app.updateUserStats(this.users);

      this.app.showToast(`تم ${actionText} حساب العميل (${user.fullName}) بنجاح!`, 'success');
    } catch (error) {
      console.error('Error in toggleBlockUser:', error);
      this.app.showToast(`تعذر تنفيذ خطوة ${actionText} الحساب في الفايربيس: ${error.message || ''}`, 'error');
    }
  }

  // View Customer Order History
  showCustomerOrderHistory(user) {
    document.getElementById('uorder-cust-name').innerText = user.fullName;
    const container = document.getElementById('user-orders-modal-body');
    
    // Get orders belonging strictly to this customer by customerId (Firestore User Doc ID)
    const userOrders = this.app.ordersMgr.orders.filter(o => {
      // 1. Strict primary check: customerId MUST match user.id
      if (o.customerId && user.id) {
        return o.customerId === user.id;
      }
      // 2. Fallback ONLY for legacy orders missing customerId field, requiring valid phone >= 7 digits
      if (user.phone && user.phone.trim().length >= 7 && o.customerPhone) {
        return o.customerPhone.trim() === user.phone.trim();
      }
      return false;
    });

    if (userOrders.length === 0) {
      container.innerHTML = `
        <div style="text-align: center; padding: 40px; color: var(--text-muted);">
          <i class="fa-solid fa-box-open" style="font-size: 36px; margin-bottom: 12px; display: block;"></i>
          لا توجد طلبات سابقة مسجلة لهذا العميل
        </div>
      `;
    } else {
      container.innerHTML = `
        <div class="table-responsive">
          <table class="custom-table">
            <thead>
              <tr>
                <th>رقم الطلب</th>
                <th>المبلغ الإجمالي</th>
                <th>طريقة الدفع</th>
                <th>الحالة</th>
                <th>التاريخ</th>
              </tr>
            </thead>
            <tbody>
              ${userOrders.map(o => `
                <tr>
                  <td style="font-family: monospace; font-weight: 700; color: var(--accent-secondary);">#${o.orderNumber || o.id.substring(0, 8)}</td>
                  <td style="font-weight: 800; color: var(--status-success);">${o.totalAmount} ر.ي</td>
                  <td>${o.paymentMethod}</td>
                  <td>${this.app.ordersMgr.getStatusBadge(o.status)}</td>
                  <td style="font-size: 12px; color: var(--text-muted);">${o.dateStr}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      `;
    }

    this.app.openModal('user-orders-modal');
  }

  // Open Edit User Modal
  openEditUserModal(userId) {
    const user = this.users.find(u => u.id === userId);
    if (!user) return;

    this.selectedUser = user;
    document.getElementById('edit-user-id').value = user.id;
    document.getElementById('edit-fullname').value = user.fullName;
    document.getElementById('edit-username').value = user.username;
    document.getElementById('edit-phone').value = user.phone;
    document.getElementById('edit-email').value = user.email;
    document.getElementById('edit-password').value = '';

    this.app.openModal('edit-user-modal');
  }

  // Save Edit User Changes
  async saveUserEdit(e) {
    e.preventDefault();
    const id = document.getElementById('edit-user-id').value;
    const fullName = document.getElementById('edit-fullname').value.trim();
    const username = document.getElementById('edit-username').value.trim();
    const phone = document.getElementById('edit-phone').value.trim();
    const email = document.getElementById('edit-email').value.trim();
    const newPass = document.getElementById('edit-password').value.trim();

    if (!fullName || !username || !phone) {
      this.app.showToast('يرجى ملء جميع الحقول المطلوبة', 'error');
      return;
    }

    try {
      const updateData = {
        fullName,
        username,
        phone,
        email
      };

      if (newPass.length > 0) {
        updateData.password = newPass;
      }

      await updateDoc(doc(db, 'customers', id), updateData);
      this.app.showToast('تم تحديث بيانات الحساب بنجاح في الفايربيس', 'success');
      this.app.closeModal('edit-user-modal');
    } catch (error) {
      console.error('Error updating user:', error);
      this.app.showToast('حدث خطأ أثناء حفظ التعديلات', 'error');
    }
  }

  // Delete User Account
  async deleteUser(userId) {
    const user = this.users.find(u => u.id === userId);
    if (!user) return;

    if (!confirm(`⚠️ تحذير شديد: هل أنت تأكد من حذف حساب العميل (${user.fullName}) نهائياً؟`)) {
      return;
    }

    try {
      await deleteDoc(doc(db, 'customers', userId));
      this.app.showToast('تم حذف الحساب نهائياً من الفايربيس', 'success');
    } catch (error) {
      console.error('Error deleting user:', error);
      this.app.showToast('تعذر حذف الحساب', 'error');
    }
  }
}
