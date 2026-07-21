import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/storage_service.dart';
import '../../shared/models/admin_model.dart';

/// Provider for Admin authentication & permissions management
class AdminAuthProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminModel? _currentAdmin;
  bool _isLoading = false;
  String? _errorMessage;

  AdminModel? get currentAdmin => _currentAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentAdmin != null || StorageService.isAdminLoggedIn();

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
              .get(const GetOptions(source: Source.serverAndCache));
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
          .get();

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
      _errorMessage = 'حدث خطأ في الاتصال: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
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
          .get();

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

      await newDocRef.set(newAdmin.toMap());
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'تعذر إضافة المدير: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentAdmin = null;
    await StorageService.clearAdminSession();
    notifyListeners();
  }
}
