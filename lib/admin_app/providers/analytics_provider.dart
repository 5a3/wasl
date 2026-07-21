import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';

/// Aggregated Analytics Report Model
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

/// Provider for Reports & Sales Analytics with Date Range filtering
class AnalyticsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;
  AnalyticsReport? _currentReport;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AnalyticsReport? get currentReport => _currentReport;

  /// Fetch aggregated stats for a date range (Daily, Weekly, Monthly, Custom)
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

      // Read aggregated report docs for each day in range (Maximum 31 reads for a full month report!)
      for (var key in dateKeys) {
        final doc = await _firestore
            .collection(FirebaseConstants.collectionDailyReports)
            .doc(key)
            .get(const GetOptions(source: Source.serverAndCache));

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          totalRev += (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
          totalOrd += (data['totalOrders'] as num?)?.toInt() ?? 0;
          deliveredOrd += (data['deliveredOrders'] as num?)?.toInt() ?? 0;
          canceledOrd += (data['canceledOrders'] as num?)?.toInt() ?? 0;

          if (data['productSales'] != null && data['productSales'] is Map) {
            final salesMap = Map<String, dynamic>.from(data['productSales']);
            salesMap.forEach((productId, qty) {
              final currentQty = productSales[productId] ?? 0;
              productSales[productId] = currentQty + ((qty as num).toInt());
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
      _errorMessage = 'تعذر حساب التقارير: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
