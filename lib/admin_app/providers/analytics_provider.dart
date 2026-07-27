import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/order_model.dart';

class TopProductItem {
  final String productName;
  final int quantitySold;
  final double totalRevenue;

  TopProductItem({
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
  });
}

class AnalyticsReport {
  final double totalRevenue;
  final int totalOrders;
  final int deliveredOrders;
  final int canceledOrders;
  final Map<String, int> productSales;

  AnalyticsReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.deliveredOrders,
    required this.canceledOrders,
    required this.productSales,
  });
}

/// Provider for Reports & Sales Analytics
class AnalyticsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;
  AnalyticsReport? _currentReport;
  List<OrderModel> _detailedOrders = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AnalyticsReport? get currentReport => _currentReport;
  List<OrderModel> get detailedOrders => _detailedOrders;

  double get totalRevenue => _currentReport?.totalRevenue ?? 0.0;
  int get totalOrdersCount => _currentReport?.totalOrders ?? 0;
  int get totalItemsSold => _currentReport?.productSales.values.fold<int>(0, (previous, val) => previous + val) ?? 0;

  List<TopProductItem> get topProducts {
    if (_currentReport == null) return [];
    final list = _currentReport!.productSales.entries
        .map((e) => TopProductItem(
              productName: e.key,
              quantitySold: e.value,
              totalRevenue: 0.0, // Calculated proportionally
            ))
        .toList();
    list.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    return list;
  }

  Future<void> fetchDailyReport(DateTime date) async {
    await fetchAnalyticsForRange(startDate: date, endDate: date);
  }

  Future<void> fetchDetailedAnalyticsForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _detailedOrders = [];
    notifyListeners();

    try {
      final startTimestamp = Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0));
      final endTimestamp = Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59));

      final snapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .where('createdAt', isLessThanOrEqualTo: endTimestamp)
          .get(const GetOptions(source: Source.serverAndCache));

      _detailedOrders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();

      final completedOrders = _detailedOrders.where((o) => o.status == AppConstants.statusDelivered).toList();
      final canceledOrdersList = _detailedOrders.where((o) => o.status == AppConstants.statusCanceled).toList();

      double totalRev = completedOrders.fold(0.0, (total, o) => total + o.totalAmount);
      Map<String, int> productSales = {};

      for (var order in completedOrders) {
        for (var item in order.items) {
          productSales[item.productName] = (productSales[item.productName] ?? 0) + item.quantity;
        }
      }

      _currentReport = AnalyticsReport(
        totalRevenue: totalRev,
        totalOrders: _detailedOrders.length,
        deliveredOrders: completedOrders.length,
        canceledOrders: canceledOrdersList.length,
        productSales: productSales,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر جلب البيانات التفصيلية: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnalyticsForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      double totalRev = 0;
      int totalOrd = 0;
      int deliveredOrd = 0;
      int canceledOrd = 0;
      Map<String, int> productSales = {};

      DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
      final last = DateTime(endDate.year, endDate.month, endDate.day);

      List<String> dateKeys = [];
      while (!current.isAfter(last)) {
        final key = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        dateKeys.add(key);
        current = current.add(const Duration(days: 1));
      }

      for (String dateKey in dateKeys) {
        final doc = await _firestore
            .collection(FirebaseConstants.collectionDailyReports)
            .doc(dateKey)
            .get(const GetOptions(source: Source.serverAndCache));

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          totalRev += (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
          totalOrd += (data['totalOrders'] as num?)?.toInt() ?? 0;
          deliveredOrd += (data['deliveredOrders'] as num?)?.toInt() ?? 0;
          canceledOrd += (data['canceledOrders'] as num?)?.toInt() ?? 0;

          if (data['productSales'] is Map) {
            final Map salesMap = data['productSales'];
            salesMap.forEach((key, val) {
              final String prodName = key.toString();
              final int count = (val as num).toInt();
              productSales[prodName] = (productSales[prodName] ?? 0) + count;
            });
          }
        }
      }

      _currentReport = AnalyticsReport(
        totalRevenue: totalRev,
        totalOrders: totalOrd,
        deliveredOrders: deliveredOrd,
        canceledOrders: canceledOrd,
        productSales: productSales,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر جلب تقرير المبيعات: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
