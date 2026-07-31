// Wasl Admin Dashboard - Complete Orders Management Module
import { db, collection, onSnapshot, doc, updateDoc } from './firebase-config.js';

export class OrdersManager {
  constructor(appInstance) {
    this.app = appInstance;
    this.orders = [];
    this.filteredOrders = [];
    this.unsubscribeListener = null;
    this.statusFilter = 'ALL';
    this.previousOrderCount = -1;
  }

  // Subscribe to real-time updates from Firestore 'orders' collection
  initOrdersListener() {
    if (this.unsubscribeListener) {
      this.unsubscribeListener();
    }

    try {
      const q = collection(db, 'orders');
      this.unsubscribeListener = onSnapshot(q, (snapshot) => {
        const newOrders = snapshot.docs.map(docSnap => {
          const data = docSnap.data();
          let orderDate = 'غير محدد';
          if (data.createdAt && typeof data.createdAt.toDate === 'function') {
            orderDate = data.createdAt.toDate().toLocaleString('ar-SA', {
              month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
            });
          }

          // Complete extraction of all OrderModel fields
          return {
            id: docSnap.id,
            orderNumber: data.orderNumber || `#${docSnap.id.substring(0, 8)}`,
            customerId: data.customerId || '',
            customerName: data.customerName || data.userName || 'عميل وصل',
            customerPhone: data.customerPhone || data.phone || 'غير مسجل',
            additionalPhone: data.additionalPhone || '',
            deliveryAddress: data.deliveryAddress || data.address || 'العنوان غير محدد',
            deliveryZoneId: data.deliveryZoneId || '',
            deliveryZoneName: data.deliveryZoneName || 'منطقة عامة',
            deliveryFee: (Number(data.deliveryFee) || 0),
            subtotal: (Number(data.subtotal) || 0),
            totalAmount: (Number(data.totalAmount) || Number(data.totalPrice) || 0),
            status: (data.status || 'pending').toLowerCase(),
            items: (data.items || []).map(item => ({
              productId: item.productId || '',
              productName: item.productName || item.productTitle || item.name || 'منتج',
              price: (Number(item.price) || 0),
              quantity: (Number(item.quantity) || 1),
              imageUrl: item.imageUrl || ''
            })),
            note: data.note || '',
            paymentMethod: data.paymentMethod || 'نقداً عند الاستلام',
            dateStr: orderDate,
            rawCreatedAt: data.createdAt
          };
        });

        // Sort orders descending by creation timestamp (newest first)
        newOrders.sort((a, b) => {
          const timeA = a.rawCreatedAt && typeof a.rawCreatedAt.toDate === 'function' ? a.rawCreatedAt.toDate().getTime() : 0;
          const timeB = b.rawCreatedAt && typeof b.rawCreatedAt.toDate === 'function' ? b.rawCreatedAt.toDate().getTime() : 0;
          return timeB - timeA;
        });

        // Trigger alert toast if new order arrives
        if (this.previousOrderCount >= 0 && newOrders.length > this.previousOrderCount) {
          this.app.showToast('🔔 وصل طلب جديد الآن!', 'success');
        }
        this.previousOrderCount = newOrders.length;
        this.orders = newOrders;

        this.filterOrders();
        this.app.updateOrderStats(this.orders);
      }, (error) => {
        console.error('Error listening to orders:', error);
      });
    } catch (e) {
      console.error('Failed to initialize orders listener:', e);
    }
  }

  // Filter orders by status dropdown
  filterOrders(status = this.statusFilter) {
    this.statusFilter = status;
    if (status === 'ALL') {
      this.filteredOrders = [...this.orders];
    } else {
      this.filteredOrders = this.orders.filter(o => {
        const s = o.status.toLowerCase();
        const target = status.toLowerCase();
        if (target === 'preparing') return s === 'preparing' || s === 'accepted_preparing';
        if (target === 'cancelled') return s === 'cancelled' || s === 'canceled';
        return s === target;
      });
    }
    this.renderOrdersTable();
  }

  // Status Badge Builder
  getStatusBadge(status) {
    const s = status.toLowerCase();
    switch (s) {
      case 'pending':
        return '<span class="badge badge-warning"><i class="fa-solid fa-clock"></i> قيد الانتظار</span>';
      case 'preparing':
      case 'accepted_preparing':
        return '<span class="badge badge-info"><i class="fa-solid fa-fire"></i> قيد التجهيز</span>';
      case 'delivering':
        return '<span class="badge badge-info"><i class="fa-solid fa-truck"></i> جاري التوصيل</span>';
      case 'delivered':
      case 'completed':
        return '<span class="badge badge-success"><i class="fa-solid fa-circle-check"></i> مكتمل / تم التوصيل</span>';
      case 'cancelled':
      case 'canceled':
        return '<span class="badge badge-danger"><i class="fa-solid fa-circle-xmark"></i> ملغي</span>';
      default:
        return `<span class="badge badge-secondary">${status}</span>`;
    }
  }

  // Render main orders table
  renderOrdersTable() {
    const tbody = document.getElementById('orders-table-body');
    if (!tbody) return;

    if (this.filteredOrders.length === 0) {
      tbody.innerHTML = `
        <tr>
          <td colspan="7" style="text-align: center; color: var(--text-muted); padding: 36px;">
            <i class="fa-solid fa-box-open" style="font-size: 36px; margin-bottom: 12px; display: block; color: var(--status-warning);"></i>
            لا توجد طلبات تطابق شروط التصفية
          </td>
        </tr>
      `;
      return;
    }

    tbody.innerHTML = this.filteredOrders.map(o => `
      <tr>
        <td style="font-family: monospace; font-weight: 700; color: var(--accent-secondary);">
          ${o.orderNumber}
        </td>
        <td>
          <div style="font-weight: 700;">${o.customerName}</div>
          <div style="font-size: 11px; color: var(--text-muted); font-family: monospace;">
            ${o.customerPhone} ${o.additionalPhone ? `(إضافي: ${o.additionalPhone})` : ''}
          </div>
        </td>
        <td style="font-weight: 800; color: var(--status-success);">${o.totalAmount} ر.ي</td>
        <td style="font-size: 13px;">${o.paymentMethod}</td>
        <td>${this.getStatusBadge(o.status)}</td>
        <td style="font-size: 12px; color: var(--text-muted);">${o.dateStr}</td>
        <td>
          <div style="display: flex; gap: 6px; justify-content: center;">
            <button class="btn btn-primary btn-icon" onclick="window.ordersMgr.showOrderDetails('${o.id}')" title="عرض كافة بيانات تفاصيل الطلب والتحديث">
              <i class="fa-solid fa-eye"></i>
            </button>
            <button class="btn btn-secondary btn-icon" onclick="window.ordersMgr.printReceipt('${o.id}')" title="طباعة الإيصال الفاتورة الشاملة">
              <i class="fa-solid fa-print"></i>
            </button>
          </div>
        </td>
      </tr>
    `).join('');
  }

  // Show Order Details Modal reading ALL fields
  showOrderDetails(orderId) {
    const order = this.orders.find(o => o.id === orderId);
    if (!order) return;

    document.getElementById('ord-id-display').innerText = order.orderNumber;

    let itemsHtml = '';
    if (order.items && order.items.length > 0) {
      itemsHtml = order.items.map(item => `
        <div style="display: flex; justify-content: space-between; align-items: center; padding: 10px 0; border-bottom: 1px solid var(--border-color);">
          <div style="display: flex; align-items: center; gap: 10px;">
            ${item.imageUrl ? `<img src="${item.imageUrl}" style="width: 40px; height: 40px; border-radius: 6px; object-fit: cover;">` : ''}
            <div>
              <span style="font-weight: 700; color: var(--text-primary);">${item.productName}</span>
              <span style="font-size: 12px; color: var(--text-muted); display: block;">الكمية: ${item.quantity} × ${item.price} ر.ي</span>
            </div>
          </div>
          <div style="font-weight: 700; color: var(--accent-secondary);">
            ${item.quantity * item.price} ر.ي
          </div>
        </div>
      `).join('');
    } else {
      itemsHtml = '<p style="color: var(--text-muted); font-size: 13px;">لا توجد عناصر مسجلة تفصيلياً</p>';
    }

    const body = document.getElementById('order-modal-body');
    body.innerHTML = `
      <div style="margin-bottom: 20px;">
        <div style="background: var(--bg-glass); border-radius: var(--radius-md); padding: 16px; margin-bottom: 16px; border: 1px solid var(--border-color);">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
            <div>
              <strong style="color: var(--text-primary);">العميل:</strong> ${order.customerName}
            </div>
            <div>
              <strong>الحالة الحالية:</strong> ${this.getStatusBadge(order.status)}
            </div>
          </div>
          
          <div style="font-size: 13px; color: var(--text-secondary); margin-bottom: 6px;">
            <strong>رقم الهاتف الأساسي:</strong> <span style="font-family: monospace; color: var(--accent-secondary); font-weight: bold;">${order.customerPhone}</span>
            ${order.additionalPhone ? ` | <strong>رقم إضافي:</strong> <span style="font-family: monospace; color: var(--accent-secondary);">${order.additionalPhone}</span>` : ''}
          </div>

          <div style="font-size: 13px; color: var(--text-secondary); margin-bottom: 6px;">
            <strong>المنطقة / الحي:</strong> ${order.deliveryZoneName}
          </div>

          <div style="font-size: 13px; color: var(--text-secondary); margin-bottom: 6px;">
            <strong>العنوان التفصيلي للتوصيل:</strong> ${order.deliveryAddress}
          </div>

          <div style="font-size: 13px; color: var(--text-secondary);">
            <strong>طريقة الدفع:</strong> ${order.paymentMethod}
          </div>

          ${order.note ? `
            <div style="margin-top: 10px; padding: 10px; background: rgba(245, 158, 11, 0.1); border-right: 3px solid var(--status-warning); border-radius: 4px; font-size: 13px; color: var(--status-warning);">
              <strong>ملاحظات العميل للطلب:</strong> ${order.note}
            </div>
          ` : ''}
        </div>

        <div style="background: var(--bg-glass); border-radius: var(--radius-md); padding: 16px; margin-bottom: 20px; border: 1px solid var(--border-color);">
          <h4 style="font-size: 14px; margin-bottom: 12px; color: var(--accent-secondary); border-bottom: 1px solid var(--border-color); padding-bottom: 8px;">عناصر وقائمة الطلب</h4>
          ${itemsHtml}

          <div style="margin-top: 14px; padding-top: 10px; border-top: 1px solid var(--border-color);">
            <div style="display: flex; justify-content: space-between; font-size: 13px; color: var(--text-secondary); margin-bottom: 4px;">
              <span>المجموع الفرعي (المنتجات):</span>
              <span>${order.subtotal || (order.totalAmount - order.deliveryFee)} ر.ي</span>
            </div>
            <div style="display: flex; justify-content: space-between; font-size: 13px; color: var(--text-secondary); margin-bottom: 8px;">
              <span>رسوم التوصيل:</span>
              <span>${order.deliveryFee} ر.ي</span>
            </div>
            <div style="display: flex; justify-content: space-between; font-weight: 800; font-size: 17px; color: var(--status-success); border-top: 1px dashed var(--border-color); padding-top: 8px;">
              <span>المبلغ الإجمالي الكلي:</span>
              <span>${order.totalAmount} ر.ي</span>
            </div>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">تحديث حالة الطلب في الفايربيس</label>
          <div style="display: flex; gap: 10px;">
            <select id="update-order-status-select" class="form-control" style="flex: 1;">
              <option value="pending" ${['pending'].includes(order.status) ? 'selected' : ''}>قيد الانتظار ⏳</option>
              <option value="accepted_preparing" ${['accepted_preparing', 'preparing'].includes(order.status) ? 'selected' : ''}>قيد التجهيز 👨‍🍳</option>
              <option value="delivering" ${['delivering'].includes(order.status) ? 'selected' : ''}>جاري التوصيل 🚚</option>
              <option value="delivered" ${['delivered', 'completed'].includes(order.status) ? 'selected' : ''}>تم التوصيل / مكتمل ✅</option>
              <option value="canceled" ${['canceled', 'cancelled'].includes(order.status) ? 'selected' : ''}>إلغاء الطلب ❌</option>
            </select>
            <button class="btn btn-primary" onclick="window.ordersMgr.updateOrderStatus('${order.id}')">
              <i class="fa-solid fa-check"></i> حفظ الحالة
            </button>
            <button class="btn btn-secondary" onclick="window.ordersMgr.printReceipt('${order.id}')">
              <i class="fa-solid fa-print"></i> طباعة الفاتورة الشاملة
            </button>
          </div>
        </div>
      </div>
    `;

    this.app.openModal('order-modal');
  }

  // Update Order Status in Firestore
  async updateOrderStatus(orderId) {
    const select = document.getElementById('update-order-status-select');
    if (!select) return;

    const newStatus = select.value;
    try {
      await updateDoc(doc(db, 'orders', orderId), {
        status: newStatus
      });
      this.app.showToast('تم تحديث حالة الطلب بنجاح في الفايربيس', 'success');
      this.app.closeModal('order-modal');
    } catch (error) {
      console.error('Error updating order status:', error);
      this.app.showToast('فشل في تحديث حالة الطلب', 'error');
    }
  }

  // Printable Complete Invoice Receipt
  printReceipt(orderId) {
    const order = this.orders.find(o => o.id === orderId);
    if (!order) return;

    const printWin = window.open('', '_blank', 'width=650,height=750');
    printWin.document.write(`
      <html dir="rtl" lang="ar">
      <head>
        <title>فاتورة طلب شراء وصل ${order.orderNumber}</title>
        <style>
          body { font-family: 'Cairo', system-ui, sans-serif; padding: 24px; line-height: 1.6; color: #000; }
          .header { text-align: center; border-bottom: 2px solid #000; padding-bottom: 12px; margin-bottom: 20px; }
          .title { font-size: 26px; font-weight: bold; }
          .info-box { border: 1px solid #ccc; border-radius: 6px; padding: 14px; margin-bottom: 16px; background: #fafafa; }
          .info-row { display: flex; justify-content: space-between; margin-bottom: 6px; font-size: 14px; }
          table { width: 100%; border-collapse: collapse; margin-top: 15px; margin-bottom: 15px; }
          th, td { border: 1px solid #ddd; padding: 10px; text-align: right; font-size: 13px; }
          th { background: #f2f2f2; font-weight: bold; }
          .total-box { margin-top: 16px; border-top: 2px solid #000; padding-top: 10px; }
          .total-row { display: flex; justify-content: space-between; font-size: 15px; margin-bottom: 4px; }
          .grand-total { font-size: 19px; font-weight: bold; color: #000; }
          @media print {
            body { padding: 0; }
          }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="title">تطبيق وصل WASL</div>
          <div>فاتورة طلب شراء رقم: <strong>${order.orderNumber}</strong></div>
          <div>تاريخ ووقت الطلب: ${order.dateStr}</div>
        </div>

        <div class="info-box">
          <div class="info-row"><strong>اسم العميل:</strong> <span>${order.customerName}</span></div>
          <div class="info-row"><strong>رقم الهاتف:</strong> <span>${order.customerPhone} ${order.additionalPhone ? `(إضافي: ${order.additionalPhone})` : ''}</span></div>
          <div class="info-row"><strong>المنطقة / الحي:</strong> <span>${order.deliveryZoneName}</span></div>
          <div class="info-row"><strong>عنوان التوصيل:</strong> <span>${order.deliveryAddress}</span></div>
          <div class="info-row"><strong>طريقة الدفع:</strong> <span>${order.paymentMethod}</span></div>
          ${order.note ? `<div class="info-row" style="color: #d97706;"><strong>ملاحظة العميل:</strong> <span>${order.note}</span></div>` : ''}
        </div>

        <table>
          <thead>
            <tr>
              <th>المنتج</th>
              <th>الكمية</th>
              <th>سعر الوحدة</th>
              <th>الإجمالي</th>
            </tr>
          </thead>
          <tbody>
            ${(order.items || []).map(i => `
              <tr>
                <td>${i.productName}</td>
                <td>${i.quantity}</td>
                <td>${i.price} ر.ي</td>
                <td>${i.quantity * i.price} ر.ي</td>
              </tr>
            `).join('')}
          </tbody>
        </table>

        <div class="total-box">
          <div class="total-row"><span>المجموع الفرعي:</span> <span>${order.subtotal || (order.totalAmount - order.deliveryFee)} ر.ي</span></div>
          <div class="total-row"><span>رسوم التوصيل:</span> <span>${order.deliveryFee} ر.ي</span></div>
          <div class="total-row grand-total"><span>الإجمالي الكلي:</span> <span>${order.totalAmount} ر.ي</span></div>
        </div>

        <script>
          window.onload = function() { window.print(); }
        </script>
      </body>
      </html>
    `);
    printWin.document.close();
  }
}
