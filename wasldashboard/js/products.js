// Wasl Admin Dashboard - Products & Inventory Module
import { db, collection, getDocs, doc, addDoc, updateDoc, deleteDoc, storage, ref, uploadBytes, getDownloadURL } from './firebase-config.js';

export class ProductsManager {
  constructor(appInstance) {
    this.app = appInstance;
    this.products = [];
    this.categories = [];
  }

  // Fetch products and categories from Firestore
  async loadProducts() {
    try {
      const prodSnapshot = await getDocs(collection(db, 'products'));
      this.products = prodSnapshot.docs.map(docSnap => ({
        id: docSnap.id,
        ...docSnap.data()
      }));

      const catSnapshot = await getDocs(collection(db, 'categories'));
      this.categories = catSnapshot.docs.map(docSnap => ({
        id: docSnap.id,
        ...docSnap.data()
      }));

      this.renderProductsGrid();
      this.app.updateProductStats(this.products);
    } catch (error) {
      console.error('Error fetching products:', error);
    }
  }

  // Render product grid
  renderProductsGrid() {
    const container = document.getElementById('products-grid-container');
    if (!container) return;

    if (this.products.length === 0) {
      container.innerHTML = `
        <div style="grid-column: 1 / -1; text-align: center; color: var(--text-muted); padding: 40px;">
          <i class="fa-solid fa-store-slash" style="font-size: 40px; margin-bottom: 12px; display: block;"></i>
          لا توجد منتجات مسجلة في قاعدة البيانات حالياً
        </div>
      `;
      return;
    }

    container.innerHTML = this.products.map(p => {
      const img = p.imageUrl || 'https://via.placeholder.com/150?text=Wasl';
      return `
        <div class="card-box" style="margin-bottom: 0; display: flex; flex-direction: column;">
          <div style="height: 140px; background: #000; overflow: hidden; position: relative;">
            <img src="${img}" style="width: 100%; height: 100%; object-fit: cover;" alt="${p.title || 'منتج'}">
            <span class="badge ${p.isAvailable !== false ? 'badge-success' : 'badge-danger'}" style="position: absolute; top: 10px; right: 10px;">
              ${p.isAvailable !== false ? 'متوفر' : 'غير متوفر'}
            </span>
          </div>
          <div style="padding: 16px; flex: 1; display: flex; flex-direction: column; justify-content: space-between;">
            <div>
              <h3 style="font-size: 15px; font-weight: 700; margin-bottom: 4px;">${p.title || 'بدون عنوان'}</h3>
              <p style="font-size: 12px; color: var(--text-muted); margin-bottom: 10px; line-clamp: 2; overflow: hidden;">${p.description || ''}</p>
            </div>
            <div>
              <div style="font-size: 18px; font-weight: 800; color: var(--accent-secondary); margin-bottom: 12px;">
                ${p.price || 0} ر.ي
              </div>
              <div style="display: flex; gap: 8px;">
                <button class="btn btn-secondary" style="flex: 1; padding: 6px; font-size: 12px;" onclick="window.productsMgr.deleteProduct('${p.id}')">
                  <i class="fa-solid fa-trash" style="color: var(--status-danger);"></i> حذف
                </button>
              </div>
            </div>
          </div>
        </div>
      `;
    }).join('');
  }

  // Delete product
  async deleteProduct(productId) {
    if (!confirm('هل أنت تأكد من رغبتك في حذف هذا المنتج؟')) return;

    try {
      await deleteDoc(doc(db, 'products', productId));
      this.app.showToast('تم حذف المنتج بنجاح', 'success');
      await this.loadProducts();
    } catch (e) {
      console.error('Error deleting product:', e);
      this.app.showToast('تعذر حذف المنتج', 'error');
    }
  }
}
