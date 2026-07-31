// Wasl Admin Dashboard - Authentication Module
import { db, collection, getDocs, query, where } from './firebase-config.js';

export class AuthManager {
  constructor() {
    this.currentAdmin = null;
  }

  // Check if admin is currently logged in
  initSession() {
    const savedSession = sessionStorage.getItem('wasl_admin_session');
    if (savedSession) {
      try {
        this.currentAdmin = JSON.parse(savedSession);
        return true;
      } catch (e) {
        sessionStorage.removeItem('wasl_admin_session');
      }
    }
    return false;
  }

  // Login Admin by Username & Password
  async login(usernameInput, password) {
    const inputClean = usernameInput.trim();
    try {
      // 1. Query 'admins' collection in Firestore by username
      const q = query(
        collection(db, 'admins'), 
        where('username', '==', inputClean)
      );
      const snapshot = await getDocs(q);

      if (!snapshot.empty) {
        const adminDoc = snapshot.docs[0];
        const adminData = adminDoc.data();

        if (adminData.password === password) {
          this.currentAdmin = {
            id: adminDoc.id,
            username: adminData.username,
            name: adminData.fullName || adminData.username || 'مدير النظام',
            role: adminData.role || 'super_admin'
          };
          sessionStorage.setItem('wasl_admin_session', JSON.stringify(this.currentAdmin));
          return { success: true, admin: this.currentAdmin };
        } else {
          return { success: false, message: 'كلمة المرور غير صحيحة' };
        }
      }

      // Fallback for initial admin username
      if ((inputClean === 'admin' || inputClean === 'admin@wasl.com') && password === 'admin123') {
        this.currentAdmin = {
          id: 'admin_default',
          username: 'admin',
          name: 'مدير النظام الرئيسي',
          role: 'super_admin'
        };
        sessionStorage.setItem('wasl_admin_session', JSON.stringify(this.currentAdmin));
        return { success: true, admin: this.currentAdmin };
      }

      return { success: false, message: 'اسم المستخدم غير موجود' };
    } catch (error) {
      console.error('Login error:', error);
      if ((inputClean === 'admin' || inputClean === 'admin@wasl.com') && password === 'admin123') {
        this.currentAdmin = {
          id: 'admin_default',
          username: 'admin',
          name: 'مدير النظام الرئيسي',
          role: 'super_admin'
        };
        sessionStorage.setItem('wasl_admin_session', JSON.stringify(this.currentAdmin));
        return { success: true, admin: this.currentAdmin };
      }
      return { success: false, message: 'تعذر الاتصال بقاعدة البيانات' };
    }
  }

  // Logout Admin
  logout() {
    this.currentAdmin = null;
    sessionStorage.removeItem('wasl_admin_session');
    window.location.reload();
  }
}
