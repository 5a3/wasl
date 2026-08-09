import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../main.dart';
import '../../shared/models/user_model.dart';
import '../views/auth/customer_login_screen.dart';

/// Provider for Customer Registration & Authentication
class CustomerAuthProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _customerBanSubscription;

  UserModel? _currentCustomer;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentCustomer => _currentCustomer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentCustomer != null || StorageService.isCustomerLoggedIn();

  CustomerAuthProvider() {
    _initLocalCustomerSession();
    _loadSavedCustomerSession();
  }

  void _initLocalCustomerSession() {
    if (StorageService.isCustomerLoggedIn()) {
      final id = StorageService.getCustomerId();
      final name = StorageService.getCustomerName();
      final phone = StorageService.getCustomerPhone();
      final address = StorageService.getCustomerAddress();
      final username = StorageService.getCustomerUsername();

      if (id != null && id.isNotEmpty) {
        _currentCustomer = UserModel(
          id: id,
          fullName: name ?? 'العميل',
          phone: phone ?? '',
          address: address ?? '',
          username: username ?? '',
          email: '',
          password: '',
          createdAt: DateTime.now(),
        );
      }
    }
  }

  Future<void> _loadSavedCustomerSession() async {
    if (StorageService.isCustomerLoggedIn()) {
      final customerId = StorageService.getCustomerId();
      if (customerId != null) {
        try {
          final doc = await _firestore
              .collection(FirebaseConstants.collectionCustomers)
              .doc(customerId)
              .get(const GetOptions(source: Source.serverAndCache))
              .timeout(const Duration(seconds: 3));

          if (!doc.exists) {
            await _handleForcedLogout('حسابك لم يعد موجوداً في النظام، يرجى التواصل مع الدعم');
            return;
          }

          if (doc.data() != null) {
            final customer = UserModel.fromMap(doc.data()!, doc.id);

            // If account is blocked, trigger immediate force logout
            if (customer.isBlocked) {
              await _handleForcedLogout('تم حظر حسابك من قبل الإدارة، يرجى التواصل مع الدعم الفني');
              return;
            }

            _currentCustomer = customer;
            FcmService.subscribeToCustomerPersonalTopic(_currentCustomer!.id);
            notifyListeners();

            // Start real-time Firestore stream listener to catch ban status changes instantly
            _listenToCustomerBanStatus(_currentCustomer!.id);
          }
        } catch (_) {
          // If offline or request timed out, start listener anyway so snapshot stream fires when back online
          if (_currentCustomer != null) {
            _listenToCustomerBanStatus(_currentCustomer!.id);
          }
        }
      }
    }
  }

  /// Real-time Firestore Stream Listener targeting customer document for instant ban detection
  void _listenToCustomerBanStatus(String customerId) {
    _customerBanSubscription?.cancel();
    _customerBanSubscription = _firestore
        .collection(FirebaseConstants.collectionCustomers)
        .doc(customerId)
        .snapshots()
        .listen(
      (doc) async {
        if (!doc.exists) {
          await _handleForcedLogout('تم حذف حسابك من قبل الإدارة، يرجى التواصل مع الدعم الفني');
          return;
        }

        final data = doc.data();
        if (data != null) {
          final isBlocked = data['isBlocked'] == true;
          if (isBlocked) {
            await _handleForcedLogout('تم حظر حسابك من قبل الإدارة، يرجى التواصل مع الدعم الفني');
          } else {
            _currentCustomer = UserModel.fromMap(data, doc.id);
            notifyListeners();
          }
        }
      },
      onError: (e) {
        debugPrint('Customer ban status stream note: $e');
      },
    );
  }

  /// Handles automatic forced logout, clearing session, unsubscribing notifications & redirecting to Login screen
  Future<void> _handleForcedLogout(String reasonMessage) async {
    _errorMessage = reasonMessage;
    _customerBanSubscription?.cancel();
    _customerBanSubscription = null;

    if (_currentCustomer != null) {
      await FcmService.unsubscribeFromCustomerPersonalTopic(_currentCustomer!.id);
    }
    _currentCustomer = null;
    await StorageService.clearCustomerSession();
    notifyListeners();

    // Safely redirect to Customer Login screen and clear all routes
    final navState = navigatorKey.currentState;
    if (navState != null && navState.mounted) {
      navState.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
        (route) => false,
      );
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        CustomDialog.showErrorSnackBar(ctx, reasonMessage);
      }
    }
  }

  /// Create New Customer Account
  Future<bool> registerCustomer({
    required String username,
    required String fullName,
    required String phone,
    required String email,
    required String address,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if username already exists
      final usernameCheck = await _firestore
          .collection(FirebaseConstants.collectionCustomers)
          .where('username', isEqualTo: username.trim())
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        _errorMessage = 'اسم المستخدم مأخوذ بالفعل، اختر اسماً آخر';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if phone number already exists
      final phoneCheck = await _firestore
          .collection(FirebaseConstants.collectionCustomers)
          .where('phone', isEqualTo: phone.trim())
          .get();

      if (phoneCheck.docs.isNotEmpty) {
        _errorMessage = 'رقم الهاتف هذا مسجل مسبقاً بحساب آخر';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final docRef = _firestore.collection(FirebaseConstants.collectionCustomers).doc();
      final newCustomer = UserModel(
        id: docRef.id,
        username: username.trim(),
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: email.trim(),
        address: address.trim(),
        password: password, // Plain text password as requested
        isBlocked: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(newCustomer.toMap());
      FcmService.subscribeToCustomerPersonalTopic(newCustomer.id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إنشاء الحساب: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Customer Login via Username/Phone/Email + Password
  Future<bool> loginCustomer(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanId = identifier.trim();

      // Query by username
      var query = await _firestore
          .collection(FirebaseConstants.collectionCustomers)
          .where('username', isEqualTo: cleanId)
          .limit(1)
          .get();

      // If not found by username, try searching by phone number
      if (query.docs.isEmpty) {
        query = await _firestore
            .collection(FirebaseConstants.collectionCustomers)
            .where('phone', isEqualTo: cleanId)
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty) {
        _errorMessage = 'بيانات الدخول غير صحيحة';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final doc = query.docs.first;
      final customer = UserModel.fromMap(doc.data(), doc.id);

      if (customer.isBlocked) {
        _errorMessage = 'تم حظر حسابك، يرجى التواصل مع الإدارة';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (customer.password != password) {
        _errorMessage = 'كلمة المرور غير صحيحة';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentCustomer = customer;
      await StorageService.saveCustomerSession(
        customerId: customer.id,
        username: customer.username,
        name: customer.fullName,
        phone: customer.phone,
        address: customer.address,
      );

      // Subscribe device to customer personal FCM topic
      FcmService.subscribeToCustomerPersonalTopic(customer.id);

      // Start real-time Firestore stream listener to catch ban status changes instantly
      _listenToCustomerBanStatus(customer.id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تسجيل الدخول: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if user exists by username or phone for password reset (Optimized: Max 1 Read)
  Future<bool> checkUserExists(String identifier) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty) return false;

    try {
      // Determine primary field based on input format to execute only 1 query
      final isDigitsOnly = RegExp(r'^[0-9+]+$').hasMatch(cleanId);
      final primaryField = isDigitsOnly ? 'phone' : 'username';

      var query = await _firestore
          .collection(FirebaseConstants.collectionCustomers)
          .where(primaryField, isEqualTo: cleanId)
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache));

      if (query.docs.isEmpty) {
        final secondaryField = isDigitsOnly ? 'username' : 'phone';
        query = await _firestore
            .collection(FirebaseConstants.collectionCustomers)
            .where(secondaryField, isEqualTo: cleanId)
            .limit(1)
            .get(const GetOptions(source: Source.serverAndCache));
      }

      return query.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Update Customer Address Only
  Future<bool> updateCustomerAddress(String newAddress) async {
    if (_currentCustomer == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanAddress = newAddress.trim();
      await _firestore
          .collection(FirebaseConstants.collectionCustomers)
          .doc(_currentCustomer!.id)
          .update({
        'address': cleanAddress,
        'updatedAt': Timestamp.now(),
      });

      _currentCustomer = UserModel(
        id: _currentCustomer!.id,
        username: _currentCustomer!.username,
        fullName: _currentCustomer!.fullName,
        phone: _currentCustomer!.phone,
        email: _currentCustomer!.email,
        address: cleanAddress,
        password: _currentCustomer!.password,
        isBlocked: _currentCustomer!.isBlocked,
        createdAt: _currentCustomer!.createdAt,
      );

      await StorageService.saveCustomerSession(
        customerId: _currentCustomer!.id,
        username: _currentCustomer!.username,
        name: _currentCustomer!.fullName,
        phone: _currentCustomer!.phone,
        address: cleanAddress,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل تحديث العنوان: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update Customer Password with old password validation
  Future<bool> updateCustomerPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentCustomer == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_currentCustomer!.password != oldPassword) {
        _errorMessage = 'الرمز السري القديم غير صحيح';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _firestore
          .collection(FirebaseConstants.collectionCustomers)
          .doc(_currentCustomer!.id)
          .update({
        'password': newPassword,
        'updatedAt': Timestamp.now(),
      });

      _currentCustomer = UserModel(
        id: _currentCustomer!.id,
        username: _currentCustomer!.username,
        fullName: _currentCustomer!.fullName,
        phone: _currentCustomer!.phone,
        email: _currentCustomer!.email,
        address: _currentCustomer!.address,
        password: newPassword,
        isBlocked: _currentCustomer!.isBlocked,
        createdAt: _currentCustomer!.createdAt,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل تغيير الرمز السري: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _customerBanSubscription?.cancel();
    _customerBanSubscription = null;
    if (_currentCustomer != null) {
      await FcmService.unsubscribeFromCustomerPersonalTopic(_currentCustomer!.id);
    }
    _currentCustomer = null;
    await StorageService.clearCustomerSession();
    notifyListeners();
  }

  @override
  void dispose() {
    _customerBanSubscription?.cancel();
    super.dispose();
  }
}
