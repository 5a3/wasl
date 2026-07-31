// Wasl Admin Dashboard - Complaints & Suggestions Module (complaints collection)
import { db, collection, onSnapshot, doc, updateDoc, deleteDoc } from './firebase-config.js';

export class ComplaintsManager {
  constructor(appInstance) {
    this.app = appInstance;
    this.complaints = [];
    this.unsubscribeListener = null;
  }

  // Subscribe to real-time updates from Firestore 'complaints' collection
  initComplaintsListener() {
    if (this.unsubscribeListener) {
      this.unsubscribeListener();
    }

    try {
      const q = collection(db, 'complaints');
      this.unsubscribeListener = onSnapshot(q, (snapshot) => {
        this.complaints = snapshot.docs.map(docSnap => {
          const data = docSnap.data();
          let cDate = 'غير محدد';
          if (data.createdAt && typeof data.createdAt.toDate === 'function') {
            cDate = data.createdAt.toDate().toLocaleString('ar-SA', {
              month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
            });
          }
          return {
            id: docSnap.id,
            customerId: data.customerId || '',
            customerName: data.customerName || data.userName || 'عميل وصل',
            customerPhone: data.customerPhone || data.phone || 'غير مسجل',
            customerAddress: data.customerAddress || data.address || '',
            deliveryZoneName: data.deliveryZoneName || '',
            type: data.type || 'شكوى',
            message: data.message || data.body || data.content || '',
            status: data.status || 'pending',
            dateStr: cDate,
            rawCreatedAt: data.createdAt
          };
        });

        // Sort complaints descending by creation timestamp (newest first)
        this.complaints.sort((a, b) => {
          const timeA = a.rawCreatedAt && typeof a.rawCreatedAt.toDate === 'function' ? a.rawCreatedAt.toDate().getTime() : 0;
          const timeB = b.rawCreatedAt && typeof b.rawCreatedAt.toDate === 'function' ? b.rawCreatedAt.toDate().getTime() : 0;
          return timeB - timeA;
        });

        this.renderComplaintsTable();
      }, (e) => {
        console.error('Error listening to complaints collection:', e);
      });
    } catch (e) {
      console.error('Failed to init complaints listener:', e);
    }
  }

  getTypeBadge(type) {
    switch (type) {
      case 'مقترح':
        return '<span class="badge badge-info"><i class="fa-solid fa-lightbulb"></i> مقترح</span>';
      case 'استفسار':
        return '<span class="badge badge-warning"><i class="fa-solid fa-circle-question"></i> استفسار</span>';
      default:
        return '<span class="badge badge-danger"><i class="fa-solid fa-triangle-exclamation"></i> شكوى</span>';
    }
  }

  // Render main complaints table
  renderComplaintsTable() {
    const tbody = document.getElementById('complaints-table-body');
    if (!tbody) return;

    if (this.complaints.length === 0) {
      tbody.innerHTML = `
        <tr>
          <td colspan="7" style="text-align: center; color: var(--text-muted); padding: 36px;">
            <i class="fa-solid fa-circle-check" style="font-size: 36px; margin-bottom: 12px; display: block; color: var(--status-success);"></i>
            لا توجد شكاوى أو مقترحات مسجلة في مجموعة complaints حالياً
          </td>
        </tr>
      `;
      return;
    }

    tbody.innerHTML = this.complaints.map(c => `
      <tr>
        <td style="font-weight: 700;">${c.customerName}</td>
        <td style="font-family: monospace; color: var(--accent-secondary); font-weight: 600;">
          <i class="fa-solid fa-phone" style="font-size: 11px; margin-left: 4px;"></i>${c.customerPhone}
        </td>
        <td>${this.getTypeBadge(c.type)}</td>
        <td style="font-size: 13px; color: var(--text-primary); max-width: 300px; line-height: 1.5;">${c.message}</td>
        <td>
          ${c.status === 'resolved' 
            ? '<span class="badge badge-success"><i class="fa-solid fa-check"></i> تم الحل</span>' 
            : '<span class="badge badge-warning"><i class="fa-solid fa-clock"></i> قيد المراجعة</span>'}
        </td>
        <td style="font-size: 12px; color: var(--text-muted);">${c.dateStr}</td>
        <td>
          <div style="display: flex; gap: 6px; justify-content: center;">
            <button class="btn btn-secondary btn-icon" onclick="window.complaintsMgr.toggleResolve('${c.id}')" title="تغيير الحالة (محلولة / قيد المراجعة)">
              <i class="fa-solid ${c.status === 'resolved' ? 'fa-rotate-left' : 'fa-check'}" style="color: var(--status-success);"></i>
            </button>
            <button class="btn btn-danger btn-icon" onclick="window.complaintsMgr.deleteComplaint('${c.id}')" title="حذف البلاغ">
              <i class="fa-solid fa-trash"></i>
            </button>
          </div>
        </td>
      </tr>
    `).join('');
  }

  // Toggle Resolution Status in complaints collection
  async toggleResolve(complaintId) {
    const item = this.complaints.find(c => c.id === complaintId);
    if (!item) return;

    const newStatus = item.status === 'resolved' ? 'pending' : 'resolved';
    try {
      await updateDoc(doc(db, 'complaints', complaintId), {
        status: newStatus
      });
      this.app.showToast(`تم تحديث حالة الشكوى إلى: ${newStatus === 'resolved' ? 'تم الحل' : 'قيد المراجعة'}`, 'success');
    } catch (e) {
      console.error('Error toggling resolve in complaints:', e);
      this.app.showToast('تعذر تغيير حالة الشكوى في الفايربيس', 'error');
    }
  }

  // Delete Complaint from complaints collection
  async deleteComplaint(complaintId) {
    if (!confirm('هل أنت تأكد من رغبتك في حذف هذا البلاغ؟')) return;

    try {
      await deleteDoc(doc(db, 'complaints', complaintId));
      this.app.showToast('تم حذف البلاغ بنجاح', 'success');
    } catch (e) {
      console.error('Error deleting complaint:', e);
      this.app.showToast('تعذر حذف البلاغ', 'error');
    }
  }
}
