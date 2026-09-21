import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/payment_method_model.dart';

/// Provider for managing payment methods with Firestore CRUD & auto-seeding defaults
class PaymentMethodProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PaymentMethodModel> _paymentMethods = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  List<PaymentMethodModel> get activePaymentMethods =>
      _paymentMethods.where((m) => m.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPaymentMethods() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.collectionPaymentMethods)
          .orderBy('orderIndex')
          .get();

      if (snapshot.docs.isEmpty) {
        // Seed default payment methods if empty
        await _seedDefaultPaymentMethods();
        final seededSnapshot = await _firestore
            .collection(FirebaseConstants.collectionPaymentMethods)
            .orderBy('orderIndex')
            .get();
        _paymentMethods = seededSnapshot.docs
            .map((doc) => PaymentMethodModel.fromMap(doc.data(), doc.id))
            .toList();
      } else {
        _paymentMethods = snapshot.docs
            .map((doc) => PaymentMethodModel.fromMap(doc.data(), doc.id))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر جلب طرق الدفع: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _seedDefaultPaymentMethods() async {
    final defaults = [
      PaymentMethodModel(
        id: '',
        name: 'الدفع عند الاستلام 💵',
        description: 'الدفع نقداً فور وصول مندوب التوصيل وتسليم الطلب',
        accountNumber: '',
        isActive: true,
        orderIndex: 0,
        createdAt: DateTime.now(),
      ),
      PaymentMethodModel(
        id: '',
        name: 'حساب الكريمي إكسبرس 🏦',
        description: 'تحويل عبر تطبيق حاسب أو الكريمي إكسبرس مع إرسال رقم السند',
        accountNumber: '123456789 (باسم مطبخ وصل لي)',
        isActive: true,
        orderIndex: 1,
        createdAt: DateTime.now(),
      ),
      PaymentMethodModel(
        id: '',
        name: 'محفظة كاش / جوالي 📱',
        description: 'تحويل إلكتروني عبر محفظة كاش أو محفظة جوالي',
        accountNumber: '770000000',
        isActive: true,
        orderIndex: 2,
        createdAt: DateTime.now(),
      ),
    ];

    for (var m in defaults) {
      await _firestore
          .collection(FirebaseConstants.collectionPaymentMethods)
          .add(m.toMap());
    }
  }

  List<PaymentMethodModel> getPaymentMethodsByStore(String? storeId) {
    if (storeId == null || storeId.isEmpty) return paymentMethods;
    return paymentMethods.where((m) => m.isGlobal || m.storeId == storeId || m.storeId == null).toList();
  }

  Future<bool> addPaymentMethod({
    required String name,
    required String description,
    required String accountNumber,
    bool isActive = true,
    String? storeId,
    bool isGlobal = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newMethod = PaymentMethodModel(
        id: '',
        name: name,
        description: description,
        accountNumber: accountNumber,
        isActive: isActive,
        orderIndex: _paymentMethods.length,
        createdAt: DateTime.now(),
        storeId: storeId,
        isGlobal: isGlobal,
      );

      final docRef = await _firestore
          .collection(FirebaseConstants.collectionPaymentMethods)
          .add(newMethod.toMap());

      final addedModel = newMethod.copyWith(id: docRef.id);
      _paymentMethods.add(addedModel);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'تعذر إضافة طريقة الدفع: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> editPaymentMethod({
    required String id,
    required String name,
    required String description,
    required String accountNumber,
    required bool isActive,
    String? storeId,
    bool? isGlobal,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _paymentMethods.indexWhere((m) => m.id == id);
      final currentStoreId = index != -1 ? _paymentMethods[index].storeId : null;
      final currentIsGlobal = index != -1 ? _paymentMethods[index].isGlobal : true;

      final updatedStoreId = storeId ?? currentStoreId;
      final updatedIsGlobal = isGlobal ?? currentIsGlobal;

      await _firestore
          .collection(FirebaseConstants.collectionPaymentMethods)
          .doc(id)
          .update({
        'name': name,
        'description': description,
        'accountNumber': accountNumber,
        'isActive': isActive,
        'storeId': updatedStoreId,
        'isGlobal': updatedIsGlobal,
      });

      if (index != -1) {
        _paymentMethods[index] = _paymentMethods[index].copyWith(
          name: name,
          description: description,
          accountNumber: accountNumber,
          isActive: isActive,
          storeId: updatedStoreId,
          isGlobal: updatedIsGlobal,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'تعذر تعديل طريقة الدفع: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePaymentMethodStatus(String id, bool newStatus) async {
    try {
      await _firestore
          .collection(FirebaseConstants.collectionPaymentMethods)
          .doc(id)
          .update({'isActive': newStatus});

      final index = _paymentMethods.indexWhere((m) => m.id == id);
      if (index != -1) {
        _paymentMethods[index] = _paymentMethods[index].copyWith(isActive: newStatus);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'تعذر تغيير حالة طريقة الدفع: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePaymentMethod(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection(FirebaseConstants.collectionPaymentMethods)
          .doc(id)
          .delete();

      _paymentMethods.removeWhere((m) => m.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'تعذر حذف طريقة الدفع: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
