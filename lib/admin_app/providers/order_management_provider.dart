import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/order_model.dart';

/// Provider for Admin to manage and listen to all orders with real-time reactive lists
class OrderManagementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  List<OrderModel> _allOrders = [];
  List<OrderModel> _activeOrders = [];
  List<OrderModel> _completedOrders = [];
  bool _isLoadingActive = false;
  bool _isLoadingCompleted = false;
  String? _errorMessage;

  List<OrderModel> get activeOrders => _activeOrders;
  List<OrderModel> get completedOrders => _completedOrders;
  List<OrderModel> get allOrders => _allOrders;
  bool get isLoadingActive => _isLoadingActive;
  bool get isLoadingCompleted => _isLoadingCompleted;
  String? get errorMessage => _errorMessage;

  /// Real-time live listener for all orders
  /// Dynamically separates orders into Active (Pending, Preparing, Delivering) and Completed (Delivered, Canceled)
  void listenToActiveOrders() {
    listenToAllOrders();
  }

  void listenToAllOrders() {
    _isLoadingActive = true;
    _isLoadingCompleted = true;
    notifyListeners();

    _ordersSubscription?.cancel();
    _ordersSubscription = _firestore
        .collection(FirebaseConstants.collectionOrders)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _allOrders = snapshot.docs
                .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                .toList();

            // Separate into Active & Completed lists
            _activeOrders = _allOrders.where((o) =>
              o.status == AppConstants.statusPending ||
              o.status == AppConstants.statusAcceptedPreparing ||
              o.status == AppConstants.statusDelivering
            ).toList();

            _completedOrders = _allOrders.where((o) =>
              o.status == AppConstants.statusDelivered ||
              o.status == AppConstants.statusCanceled
            ).toList();

            _isLoadingActive = false;
            _isLoadingCompleted = false;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'خطأ الاستماع للطلبات: ${e.toString()}';
            _isLoadingActive = false;
            _isLoadingCompleted = false;
            notifyListeners();
          },
        );
  }

  Future<void> fetchCompletedOrders({bool isRefresh = false}) async {
    if (_ordersSubscription == null) {
      listenToAllOrders();
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

      // If status changed to Delivered, update daily aggregated report
      if (newStatus == AppConstants.statusDelivered) {
        final orderDoc = await orderRef.get();
        if (orderDoc.exists && orderDoc.data() != null) {
          final order = OrderModel.fromMap(orderDoc.data()!, orderDoc.id);
          await _updateDailyReport(order);
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل تحديل حالة الطلب: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> _updateDailyReport(OrderModel order) async {
    try {
      final dateKey = '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')}';
      final reportRef = _firestore.collection(FirebaseConstants.collectionDailyReports).doc(dateKey);

      final doc = await reportRef.get();

      Map<String, dynamic> productSalesMap = {};
      if (doc.exists && doc.data() != null && doc.data()!['productSales'] is Map) {
        productSalesMap = Map<String, dynamic>.from(doc.data()!['productSales']);
      }

      for (var item in order.items) {
        productSalesMap[item.productName] = (productSalesMap[item.productName] ?? 0) + item.quantity;
      }

      if (doc.exists) {
        await reportRef.update({
          'totalRevenue': FieldValue.increment(order.totalAmount),
          'totalOrders': FieldValue.increment(1),
          'deliveredOrders': FieldValue.increment(1),
          'productSales': productSalesMap,
        });
      } else {
        await reportRef.set({
          'date': dateKey,
          'totalRevenue': order.totalAmount,
          'totalOrders': 1,
          'deliveredOrders': 1,
          'canceledOrders': 0,
          'productSales': productSalesMap,
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
