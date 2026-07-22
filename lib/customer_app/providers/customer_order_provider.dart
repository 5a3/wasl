import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/delivery_zone_model.dart';
import '../../shared/models/order_model.dart';
import '../../shared/models/user_model.dart';

/// Provider for Customer Order placement and order tracking
class CustomerOrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _myOrdersSubscription;

  List<OrderModel> _myActiveOrders = [];
  List<OrderModel> _myPastOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get myActiveOrders => _myActiveOrders;
  List<OrderModel> get myPastOrders => _myPastOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Listen to customer active orders in real-time using snapshots()
  void listenToCustomerOrders(String customerId) {
    _myOrdersSubscription?.cancel();
    _myOrdersSubscription = _firestore
        .collection(FirebaseConstants.collectionOrders)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .listen(
          (snapshot) {
            final allOrders = snapshot.docs
                .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                .toList();

            // Sort locally in memory to avoid requiring composite indexes on Firestore
            allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            _myActiveOrders = allOrders.where((o) =>
                o.status == AppConstants.statusPending ||
                o.status == AppConstants.statusAcceptedPreparing ||
                o.status == AppConstants.statusDelivering
            ).toList();

            _myPastOrders = allOrders.where((o) =>
                o.status == AppConstants.statusDelivered ||
                o.status == AppConstants.statusCanceled
            ).toList();

            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'خطأ في جلب الطلبات: ${e.toString()}';
            notifyListeners();
          },
        );
  }

  /// Place New Order
  Future<bool> placeOrder({
    required UserModel customer,
    required DeliveryZoneModel zone,
    required List<OrderItemModel> items,
    required double subtotal,
    required double totalAmount,
    required String deliveryAddress,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final docRef = _firestore.collection(FirebaseConstants.collectionOrders).doc();
      final orderNumber = 'W-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final newOrder = OrderModel(
        id: docRef.id,
        orderNumber: orderNumber,
        customerId: customer.id,
        customerName: customer.fullName,
        customerPhone: customer.phone,
        deliveryAddress: deliveryAddress.trim(),
        deliveryZoneId: zone.id,
        deliveryZoneName: zone.zoneName,
        deliveryFee: zone.deliveryFee,
        subtotal: subtotal,
        totalAmount: totalAmount,
        status: AppConstants.statusPending,
        items: items,
        note: note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newOrder.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إرسال الطلب: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _myOrdersSubscription?.cancel();
    super.dispose();
  }
}
