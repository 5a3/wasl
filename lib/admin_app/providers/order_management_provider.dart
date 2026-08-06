import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/fcm_service.dart';
import '../../shared/models/order_model.dart';

/// Provider for Admin to manage and listen to all orders with optimized queries and pagination
class OrderManagementProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _activeOrdersSubscription;

  List<OrderModel> _activeOrders = [];
  List<OrderModel> _completedOrders = [];
  
  // Pagination variables for completed orders
  DocumentSnapshot? _lastCompletedDocument;
  bool _hasMoreCompleted = true;
  bool _isLoadingActive = false;
  bool _isLoadingCompleted = false;
  String? _errorMessage;

  // Search variables
  List<OrderModel> _searchResults = [];
  bool _isSearching = false;
  String _lastSearchQuery = '';

  List<OrderModel> get activeOrders => _activeOrders;
  List<OrderModel> get completedOrders => _completedOrders;
  bool get isLoadingActive => _isLoadingActive;
  bool get isLoadingCompleted => _isLoadingCompleted;
  bool get hasMoreCompleted => _hasMoreCompleted;
  String? get errorMessage => _errorMessage;

  // Search getters
  List<OrderModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get lastSearchQuery => _lastSearchQuery;

  /// Starts listening to active orders and fetches the first page of completed orders
  void listenToAllOrders() {
    listenToActiveOrders();
    refreshCompletedOrders();
  }

  /// Real-time live listener for ACTIVE orders only (Pending, Preparing, Delivering)
  /// This optimizes performance and Firestore reads by ignoring completed history.
  void listenToActiveOrders() {
    _isLoadingActive = true;
    notifyListeners();

    _activeOrdersSubscription?.cancel();
    _activeOrdersSubscription = _firestore
        .collection(FirebaseConstants.collectionOrders)
        .where('status', whereIn: [
          AppConstants.statusPending,
          AppConstants.statusAcceptedPreparing,
          AppConstants.statusDelivering
        ])
        .snapshots()
        .listen(
          (snapshot) {
            _activeOrders = snapshot.docs
                .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
                .toList();

            // Sort locally to avoid requiring composite indexes on Firestore
            _activeOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            _isLoadingActive = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (e) {
            _errorMessage = 'خطأ الاستماع للطلبات النشطة: ${e.toString()}';
            _isLoadingActive = false;
            notifyListeners();
          },
        );
  }

  /// Reset and reload completed orders from the beginning
  Future<void> refreshCompletedOrders() async {
    _completedOrders = [];
    _lastCompletedDocument = null;
    _hasMoreCompleted = true;
    _isLoadingCompleted = false;
    notifyListeners();
    await fetchNextCompletedPage();
  }

  /// Paginated fetch for completed/canceled orders (20 per page)
  Future<void> fetchNextCompletedPage() async {
    if (_isLoadingCompleted || !_hasMoreCompleted) return;

    _isLoadingCompleted = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(FirebaseConstants.collectionOrders)
          .orderBy('createdAt', descending: true);

      if (_lastCompletedDocument != null) {
        query = query.startAfterDocument(_lastCompletedDocument!);
      }

      const int limitVal = 20;
      query = query.limit(limitVal);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastCompletedDocument = snapshot.docs.last;

        final newOrders = snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList();

        // Filter to keep only completed / canceled orders
        final completedBatch = newOrders.where((o) =>
          o.status == AppConstants.statusDelivered ||
          o.status == AppConstants.statusCanceled
        ).toList();

        _completedOrders.addAll(completedBatch);

        if (snapshot.docs.length < limitVal) {
          _hasMoreCompleted = false;
        }

        // If this page had only active orders and we have more documents to fetch,
        // automatically trigger the next page load to prevent showing an empty screen.
        if (completedBatch.isEmpty && snapshot.docs.length == limitVal) {
          _isLoadingCompleted = false;
          await fetchNextCompletedPage();
          return;
        }
      } else {
        _hasMoreCompleted = false;
      }
    } catch (e) {
      _errorMessage = 'خطأ تحميل سجل الطلبات: ${e.toString()}';
    } finally {
      _isLoadingCompleted = false;
      notifyListeners();
    }
  }

  /// Firebase & Local high-performance multi-field search by order number, phone, customer name, or address
  Future<void> searchOrders(String queryText) async {
    final rawQuery = queryText.trim();
    _lastSearchQuery = rawQuery;
    if (rawQuery.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<OrderModel> results = [];
      final Set<String> foundIds = {};

      void addOrder(OrderModel order) {
        if (!foundIds.contains(order.id)) {
          foundIds.add(order.id);
          results.add(order);
        }
      }

      final String cleanQuery = rawQuery.toLowerCase().replaceAll('#', '');
      final String digitsOnly = rawQuery.replaceAll(RegExp(r'[^0-9]'), '');

      // 1. Search locally in active and completed loaded orders (Instant match!)
      final localOrders = [..._activeOrders, ..._completedOrders];
      for (var o in localOrders) {
        final oNumClean = o.orderNumber.toLowerCase();
        final pClean = o.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
        final addPhoneClean = (o.additionalPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');

        bool isMatch = false;
        // Match Order Number (e.g. W-12345 or 12345 or #12345)
        if (oNumClean.contains(cleanQuery) || 
            (digitsOnly.isNotEmpty && oNumClean.contains(digitsOnly))) {
          isMatch = true;
        }
        // Match Customer Phone or Additional Phone (e.g. 771234567, 0771234567, +967771234567)
        else if (o.customerPhone.contains(rawQuery) || 
                 (digitsOnly.length >= 3 && (pClean.contains(digitsOnly) || addPhoneClean.contains(digitsOnly)))) {
          isMatch = true;
        }
        // Match Customer Name, Address, or Zone
        else if (o.customerName.toLowerCase().contains(cleanQuery) ||
                 o.deliveryAddress.toLowerCase().contains(cleanQuery) ||
                 o.deliveryZoneName.toLowerCase().contains(cleanQuery)) {
          isMatch = true;
        }

        if (isMatch) {
          addOrder(o);
        }
      }

      // 2. Build variants for Firestore Query (for orders not loaded in memory)
      final List<String> orderNumVariants = [
        rawQuery,
        rawQuery.toUpperCase(),
        cleanQuery,
        cleanQuery.toUpperCase(),
        if (digitsOnly.isNotEmpty) ...[
          digitsOnly,
          'W-$digitsOnly',
          'w-$digitsOnly',
        ]
      ];

      for (var variant in orderNumVariants) {
        final numSnap = await _firestore
            .collection(FirebaseConstants.collectionOrders)
            .where('orderNumber', isEqualTo: variant)
            .get();
        for (var doc in numSnap.docs) {
          addOrder(OrderModel.fromMap(doc.data(), doc.id));
        }
      }

      // 3. Search Firestore by Phone variants
      final List<String> phoneVariants = [
        rawQuery,
        if (digitsOnly.isNotEmpty) ...[
          digitsOnly,
          '+967$digitsOnly',
          if (digitsOnly.startsWith('0')) digitsOnly.substring(1),
          if (digitsOnly.startsWith('0')) '+967${digitsOnly.substring(1)}',
          if (digitsOnly.startsWith('967')) '+$digitsOnly',
        ]
      ];

      for (var pVar in phoneVariants) {
        final phoneSnap = await _firestore
            .collection(FirebaseConstants.collectionOrders)
            .where('customerPhone', isEqualTo: pVar)
            .get();

        for (var doc in phoneSnap.docs) {
          addOrder(OrderModel.fromMap(doc.data(), doc.id));
        }
      }

      // Sort results by creation date (newest first)
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _searchResults = results;

    } catch (e) {
      _errorMessage = 'خطأ أثناء البحث: ${e.toString()}';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear current search query and results
  void clearSearch() {
    _lastSearchQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  /// Update Order Status & automatically aggregate daily stats when Delivered
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final orderRef = _firestore.collection(FirebaseConstants.collectionOrders).doc(orderId);
      final now = DateTime.now();

      // Find the active order model locally before the database update to avoid race conditions
      final activeIdx = _activeOrders.indexWhere((o) => o.id == orderId);
      OrderModel? localActiveOrder;
      if (activeIdx != -1) {
        localActiveOrder = _activeOrders[activeIdx];
      }

      await orderRef.update({
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update local state lists instantly for smooth UX transitions
      if (newStatus == AppConstants.statusDelivered || newStatus == AppConstants.statusCanceled) {
        if (localActiveOrder != null) {
          final updatedOrder = OrderModel(
            id: localActiveOrder.id,
            orderNumber: localActiveOrder.orderNumber,
            customerId: localActiveOrder.customerId,
            customerName: localActiveOrder.customerName,
            customerPhone: localActiveOrder.customerPhone,
            deliveryAddress: localActiveOrder.deliveryAddress,
            deliveryZoneId: localActiveOrder.deliveryZoneId,
            deliveryZoneName: localActiveOrder.deliveryZoneName,
            deliveryFee: localActiveOrder.deliveryFee,
            subtotal: localActiveOrder.subtotal,
            totalAmount: localActiveOrder.totalAmount,
            status: newStatus,
            items: localActiveOrder.items,
            note: localActiveOrder.note,
            createdAt: localActiveOrder.createdAt,
            updatedAt: now,
          );

          if (!_completedOrders.any((o) => o.id == orderId)) {
            _completedOrders.insert(0, updatedOrder);
          }
        }
      }

      // If status changed to Delivered, update daily aggregated report
      if (newStatus == AppConstants.statusDelivered) {
        final orderDoc = await orderRef.get();
        if (orderDoc.exists && orderDoc.data() != null) {
          final order = OrderModel.fromMap(orderDoc.data()!, orderDoc.id);
          await _updateDailyReport(order);
        }
      }

      // Trigger Push Notification exclusively to the specific Customer who placed the order (No Firestore doc creation)
      try {
        final orderDoc = await orderRef.get();
        if (orderDoc.exists && orderDoc.data() != null) {
          final order = OrderModel.fromMap(orderDoc.data()!, orderDoc.id);
          final targetCustomerId = order.customerId;
          final orderNumber = order.orderNumber;

          FcmService.sendCustomerOrderStatusNotification(
            orderNumber: orderNumber,
            status: newStatus,
            customerId: targetCustomerId,
          ).catchError((e) {
            debugPrint('Error sending customer order status push: $e');
            return false;
          });
        }
      } catch (e) {
        debugPrint('Error triggering customer order status push: $e');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل تعديل حالة الطلب: ${e.toString()}';
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

  /// Delete Order from Firestore & update local lists immediately
  Future<bool> deleteOrder(String orderId) async {
    try {
      await _firestore.collection(FirebaseConstants.collectionOrders).doc(orderId).delete();

      _activeOrders.removeWhere((o) => o.id == orderId);
      _completedOrders.removeWhere((o) => o.id == orderId);
      _searchResults.removeWhere((o) => o.id == orderId);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف الطلب: ${e.toString()}';
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
