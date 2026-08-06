import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/fcm_service.dart';
import '../../shared/models/admin_model.dart';

/// Provider for Admin authentication & sub-admin list management with full CRUD & Search
class AdminAuthProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminModel? _currentAdmin;
  List<AdminModel> _subAdmins = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  AdminModel? get currentAdmin => _currentAdmin;
  List<AdminModel> get subAdmins {
    if (_searchQuery.trim().isEmpty) return _subAdmins;
    final query = _searchQuery.trim().toLowerCase();
    return _subAdmins.where((a) =>
      a.fullName.toLowerCase().contains(query) ||
      a.username.toLowerCase().contains(query)
    ).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentAdmin != null || StorageService.isAdminLoggedIn();
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  AdminAuthProvider() {
    _loadSavedAdminSession();
  }

  Future<void> _loadSavedAdminSession() async {
    if (StorageService.isAdminLoggedIn()) {
      final adminId = StorageService.getAdminId();
      if (adminId != null) {
        try {
          final doc = await _firestore
              .collection(FirebaseConstants.collectionAdmins)
              .doc(adminId)
              .get(const GetOptions(source: Source.serverAndCache))
              .timeout(const Duration(seconds: 5));
          if (doc.exists && doc.data() != null) {
            _currentAdmin = AdminModel.fromMap(doc.data()!, doc.id);
            notifyListeners();
          }
        } catch (_) {}
      }
    }
  }

  /// Admin Login via Username & Password (unencrypted)
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final query = await _firestore
          .collection(FirebaseConstants.collectionAdmins)
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw 'انتهت مهلة الاتصال! يرجى التأكد من تشغيل الشبكة وموقع Firestore.',
          );

      if (query.docs.isEmpty) {
        _errorMessage = 'اسم المستخدم غير موجود';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final doc = query.docs.first;
      final admin = AdminModel.fromMap(doc.data(), doc.id);

      if (admin.password != password) {
        _errorMessage = 'كلمة المرور غير صحيحة';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentAdmin = admin;
      await StorageService.saveAdminSession(
        adminId: admin.id,
        username: admin.username,
        role: admin.role,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'تعذر الاتصال: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch all registered admins / sub-admins reactively
  Future<void> fetchSubAdmins() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.collectionAdmins)
          .get(const GetOptions(source: Source.serverAndCache));

      _subAdmins = snapshot.docs
          .map((doc) => AdminModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'فشل جلب قائمة المدراء: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a sub-admin (Manager with lower permissions)
  Future<bool> addSubAdmin({
    required String username,
    required String password,
    required String fullName,
    required List<String> permissions,
  }) async {
    try {
      final existing = await _firestore
          .collection(FirebaseConstants.collectionAdmins)
          .where('username', isEqualTo: username.trim())
          .get()
          .timeout(const Duration(seconds: 8));

      if (existing.docs.isNotEmpty) {
        _errorMessage = 'اسم المستخدم مستخدم بالفعل';
        notifyListeners();
        return false;
      }

      final newDocRef = _firestore.collection(FirebaseConstants.collectionAdmins).doc();
      final newAdmin = AdminModel(
        id: newDocRef.id,
        username: username.trim(),
        password: password,
        fullName: fullName.trim(),
        role: FirebaseConstants.roleSubAdmin,
        permissions: permissions,
        createdAt: DateTime.now(),
      );

      await newDocRef.set(newAdmin.toMap()).timeout(const Duration(seconds: 8));
      _subAdmins.add(newAdmin);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'تعذر إضافة المدير: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Edit Sub-Admin
  Future<bool> editSubAdmin({
    required String id,
    required String username,
    required String password,
    required String fullName,
    required List<String> permissions,
  }) async {
    try {
      final index = _subAdmins.indexWhere((a) => a.id == id);
      if (index != -1) {
        final old = _subAdmins[index];

        // Safety lock: Only Super Admin can edit Super Admin credentials
        if (old.isSuperAdmin && _currentAdmin?.isSuperAdmin != true) {
          _errorMessage = 'عذراً، لا يمكن تعديل بيانات أو صلاحيات المدير العام الرئيسي إلا بواسطة المدير العام نفسه 🔒';
          notifyListeners();
          return false;
        }

        final updated = AdminModel(
          id: id,
          username: username.trim(),
          password: password,
          fullName: fullName.trim(),
          role: old.role,
          permissions: permissions,
          createdAt: old.createdAt,
        );

        await _firestore
            .collection(FirebaseConstants.collectionAdmins)
            .doc(id)
            .update(updated.toMap());

        _subAdmins[index] = updated;
        if (_currentAdmin?.id == id) {
          _currentAdmin = updated;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'فشل تعديل المدير: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delete Sub-Admin
  Future<bool> deleteSubAdmin(String id) async {
    try {
      final index = _subAdmins.indexWhere((a) => a.id == id);
      if (index != -1 && _subAdmins[index].isSuperAdmin) {
        _errorMessage = 'عذراً، لا يمكن حذف حساب المدير العام الرئيسي 🔒';
        notifyListeners();
        return false;
      }

      await _firestore
          .collection(FirebaseConstants.collectionAdmins)
          .doc(id)
          .delete();

      _subAdmins.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف المدير: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }


  Future<void> logout() async {
    _currentAdmin = null;
    await StorageService.clearAdminSession();
    await FcmService.unsubscribeFromAdminTopic();
    notifyListeners();
  }
}
