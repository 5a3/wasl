import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/order_model.dart';

/// Provider for Admin to manage and listen to live active orders smartly
class OrderManagementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _activeOrdersSubscription;

  List<OrderModel> _activeOrders = [];
  List<OrderModel> _completedOrders = [];
  bool _isLoadingActive = false;
  bool _isLoadingCompleted = false;
  String? _errorMessage;

  List<OrderModel> get activeOrders => _activeOrders;
  List<OrderModel> get completedOrders => _completedOrders;
  bool get isLoadingActive => _isLoadingActive;
  bool get isLoadingCompleted => _isLoadingCompleted;
  String? get errorMessage => _errorMessage;

  /// Start smart stream listener for ACTIVE ongoing orders ONLY
  /// (status IN ['pending', 'accepted_preparing', 'delivering'])
  /// Read optimization: Charges 1 initial read per active doc, then ONLY 1 read per modified/added order!
  void listenToActiveOrders() {
    _isLoadingActive = true;
    notifyListeners();

    _activeOrdersSubscription?.cancel();
    _activeOrdersSubscription = _firestore
        .collection(FirebaseConstants.collectionOrders)
        .where('status', whereIn: [
          AppConstants.statusPending,
          AppConstants.statusAcceptedPreparing,
          AppConstants.statusDelivering,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _activeOrders = snapshot.docs
                .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                .toList();
            _isLoadingActive = false;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'خطأ في الاستماع للطلبات النشطة: ${e.toString()}';
            _isLoadingActive = false;
            notifyListeners();
          },
        );
  }

  /// Fetch finished / completed historical orders once via pagination
  Future<void> fetchCompletedOrders({bool isRefresh = false}) async {
    _isLoadingCompleted = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.collectionOrders)
          .where('status', whereIn: [
            AppConstants.statusDelivered,
            AppConstants.statusCanceled,
          ])
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      _completedOrders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoadingCompleted = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر جلب سجل الطلبات القديمة: ${e.toString()}';
      _isLoadingCompleted = false;
      notifyListeners();
    }
  }

  /// Update Order Status & automatically aggregate daily stats when Delivered
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final orderRef = _firestore.collection(FirebaseConstants.collectionOrders).doc(orderId);
      final now = DateTime.now();

      await orderRef.update({
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(now),
      });

      // If status changed to Delivered, increment aggregated daily report
      if (newStatus == AppConstants.statusDelivered) {
        final orderDoc = await orderRef.get();
        if (orderDoc.exists && orderDoc.data() != null) {
          final order = OrderModel.fromMap(orderDoc.data()!, orderDoc.id);
          final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          final reportRef = _firestore.collection(FirebaseConstants.collectionDailyReports).doc(dateKey);

          final Map<String, dynamic> productIncrements = {};
          for (var item in order.items) {
            productIncrements['productSales.${item.productId}'] = FieldValue.increment(item.quantity);
          }

          await reportRef.set({
            'totalRevenue': FieldValue.increment(order.totalAmount),
            'totalOrders': FieldValue.increment(1),
            'deliveredOrders': FieldValue.increment(1),
            ...productIncrements,
          }, SetOptions(merge: true));
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل تحديث حالة الطلب: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _activeOrdersSubscription?.cancel();
    super.dispose();
  }
}
