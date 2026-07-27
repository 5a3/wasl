import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pdf_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/product_model.dart';

class _ProductSalesStats {
  final String name;
  int qty = 0;
  double revenue = 0.0;
  _ProductSalesStats({required this.name});
}

class _CustomerStats {
  final String name;
  final String phone;
  int count = 0;
  double spent = 0.0;
  _CustomerStats({required this.name, required this.phone});
}

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _reportType = 'daily'; // 'daily', 'weekly', 'monthly', 'custom'
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _customDateRange;

  String? _selectedProductId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      _fetchReportData();
    });
  }

  DateTime get _startDate {
    switch (_reportType) {
      case 'daily':
        return _selectedDate;
      case 'weekly':
        return _selectedDate;
      case 'monthly':
        return DateTime(_selectedDate.year, _selectedDate.month, 1);
      case 'custom':
        return _customDateRange?.start ?? DateTime.now().subtract(const Duration(days: 7));
      default:
        return _selectedDate;
    }
  }

  DateTime get _endDate {
    switch (_reportType) {
      case 'daily':
        return _selectedDate;
      case 'weekly':
        return _selectedDate.add(const Duration(days: 6));
      case 'monthly':
        final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
        return nextMonth.subtract(const Duration(days: 1));
      case 'custom':
        return _customDateRange?.end ?? DateTime.now();
      default:
        return _selectedDate;
    }
  }

  void _fetchReportData() {
    Provider.of<AnalyticsProvider>(context, listen: false).fetchDetailedAnalyticsForRange(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchReportData();
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
      });
      _fetchReportData();
    }
  }

  String _getReportRangeText() {
    switch (_reportType) {
      case 'daily':
        return 'يوم: ${Formatters.formatDate(_selectedDate)}';
      case 'weekly':
        return 'أسبوع: من ${Formatters.formatDate(_startDate)} إلى ${Formatters.formatDate(_endDate)}';
      case 'monthly':
        return 'شهر: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
      case 'custom':
        return 'الفترة: من ${Formatters.formatDate(_startDate)} إلى ${Formatters.formatDate(_endDate)}';
      default:
        return '';
    }
  }

  Future<void> _exportPdfReport(
    AdminAuthProvider authProvider,
    ProductProvider productProvider,
    CategoryProvider categoryProvider,
    List<OrderModel> completedOrders,
    List<_ProductSalesStats> topProductsList,
    List<_CustomerStats> topCustomersList,
  ) async {
    final pdf = pw.Document();

    final amiriRegular = await PdfHelper.cairoRegular;
    final amiriBold = await PdfHelper.cairoBold;
    final logoSvg = await rootBundle.loadString('assets/images/logoreport.svg');

    final admin = authProvider.currentAdmin;
    final managerName = admin?.fullName ?? 'مدير النظام';
    final managerUsername = admin?.username ?? 'admin';

    String r(String text) => PdfHelper.reshapeArabic(text);

    String filterDesc = _getReportRangeText();
    String reportTitle = 'كشف مبيعات عام';
    if (_selectedProductId != null) {
      final pName = productProvider.products.firstWhere((p) => p.id == _selectedProductId).name;
      reportTitle = 'كشف مبيعات منتج: $pName';
    } else if (_selectedCategoryId != null) {
      final cName = categoryProvider.categories.firstWhere((c) => c.id == _selectedCategoryId).name;
      reportTitle = 'كشف مبيعات فئة: $cName';
    }

    double totalRev = completedOrders.fold(0.0, (sum, o) {
      double orderMatchingAmount = 0.0;
      for (var item in o.items) {
        if (_selectedProductId != null) {
          final target = productProvider.products.firstWhere((p) => p.id == _selectedProductId);
          if (item.productName == target.name) orderMatchingAmount += item.totalPrice;
        } else if (_selectedCategoryId != null) {
          final subCats = categoryProvider.getSubCategories(_selectedCategoryId!);
          final catIds = {_selectedCategoryId!, ...subCats.map((c) => c.id)};
          final catProds = productProvider.products.where((p) => catIds.contains(p.mainCategoryId) || catIds.contains(p.subCategoryId)).map((p) => p.name).toSet();
          if (catProds.contains(item.productName)) orderMatchingAmount += item.totalPrice;
        } else {
          orderMatchingAmount += item.totalPrice;
        }
      }
      return sum + orderMatchingAmount;
    });

    int totalQty = topProductsList.fold(0, (sum, item) => sum + item.qty);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: amiriRegular, bold: amiriBold),
        build: (pw.Context pwContext) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(r('اسم المدير: $managerName'), style: const pw.TextStyle(fontSize: 9)),
                        pw.Text(r('اسم المستخدم: $managerUsername'), style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Container(
                      width: 80,
                      height: 40,
                      child: pw.SvgImage(svg: logoSvg),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(r('نوع التصفية: $filterDesc'), style: const pw.TextStyle(fontSize: 9)),
                        pw.Text(r('تاريخ الطباعة: ${Formatters.formatDate(DateTime.now())}'), style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 8),

                pw.Center(
                  child: pw.Text(r(reportTitle), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: amiriBold)),
                ),
                pw.SizedBox(height: 16),

                // Mini stats row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(r('الدخل للفترة'), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text(r(Formatters.formatCurrency(totalRev)), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: amiriBold, color: PdfColors.green)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(r('القطع المباعة'), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text(r('$totalQty قطعة'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: amiriBold, color: PdfColors.orange)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(r('عدد العمليات'), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text(r('${completedOrders.length} فاتورة'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: amiriBold, color: PdfColors.blue)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Table content dynamically built depending on active filters
                pw.Expanded(
                  child: _selectedProductId != null
                      ? pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(r('جدول عمليات بيع المنتج الحالية:'), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: amiriBold)),
                            pw.SizedBox(height: 8),
                            pw.TableHelper.fromTextArray(
                              headers: [r('رقم الطلب'), r('العميل'), r('الهاتف'), r('التاريخ'), r('الكمية'), r('القيمة')],
                              data: completedOrders.where((o) => o.items.any((i) => i.productName == topProductsList.first.name)).map((o) {
                                final item = o.items.firstWhere((i) => i.productName == topProductsList.first.name);
                                return [
                                  r('#${o.orderNumber}'),
                                  r(o.customerName),
                                  r(o.customerPhone),
                                  r(Formatters.formatDateTime(o.createdAt)),
                                  r('${item.quantity} قطع'),
                                  r(Formatters.formatCurrency(item.totalPrice)),
                                ];
                              }).toList(),
                              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
                              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: amiriBold, fontSize: 8),
                              cellStyle: const pw.TextStyle(fontSize: 7),
                              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                            ),
                          ],
                        )
                      : _selectedCategoryId != null
                          ? pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(r('مبيعات أصناف الفئة المحددة:'), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: amiriBold)),
                                pw.SizedBox(height: 8),
                                pw.TableHelper.fromTextArray(
                                  headers: [r('المنتج'), r('الكمية المباعة'), r('إجمالي الإيرادات')],
                                  data: topProductsList.map((p) => [
                                    r(p.name),
                                    r('${p.qty} قطع'),
                                    r(Formatters.formatCurrency(p.revenue)),
                                  ]).toList(),
                                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
                                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: amiriBold, fontSize: 8),
                                  cellStyle: const pw.TextStyle(fontSize: 7),
                                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                                ),
                              ],
                            )
                          : pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(r('الأصناف الأكثر مبيعاً:'), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: amiriBold)),
                                pw.SizedBox(height: 6),
                                pw.TableHelper.fromTextArray(
                                  headers: [r('المنتج'), r('الكمية المباعة'), r('إجمالي الإيرادات')],
                                  data: topProductsList.take(8).map((p) => [
                                    r(p.name),
                                    r('${p.qty} قطع'),
                                    r(Formatters.formatCurrency(p.revenue)),
                                  ]).toList(),
                                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
                                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: amiriBold, fontSize: 8),
                                  cellStyle: const pw.TextStyle(fontSize: 7),
                                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                                ),
                                pw.SizedBox(height: 16),
                                pw.Text(r('العملاء الأكثر طلباً للفترة:'), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: amiriBold)),
                                pw.SizedBox(height: 6),
                                pw.TableHelper.fromTextArray(
                                  headers: [r('اسم العميل'), r('الهاتف'), r('الطلبات'), r('إجمالي المشتريات')],
                                  data: topCustomersList.take(6).map((c) => [
                                    r(c.name),
                                    r(c.phone),
                                    r('${c.count} طلبات'),
                                    r(Formatters.formatCurrency(c.spent)),
                                  ]).toList(),
                                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
                                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: amiriBold, fontSize: 8),
                                  cellStyle: const pw.TextStyle(fontSize: 7),
                                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                                ),
                              ],
                            ),
                ),

                pw.SizedBox(height: 10),
                pw.Divider(thickness: 0.5),
                pw.Center(
                  child: pw.Text(r('تم استخراج هذا التقرير تلقائياً من نظام وصل لي للمأكولات السريعة والعصائر'), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'كشف_مبيعات_${Formatters.formatDate(_startDate)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);
    final authProvider = Provider.of<AdminAuthProvider>(context);

    // 1. Get completed orders in range
    final completedOrders = analyticsProvider.detailedOrders
        .where((o) => o.status == AppConstants.statusDelivered)
        .toList();

    // 2. Identify the active category and sub-categories
    Set<String> activeCategoryIds = {};
    if (_selectedCategoryId != null) {
      activeCategoryIds.add(_selectedCategoryId!);
      final subCats = categoryProvider.getSubCategories(_selectedCategoryId!);
      activeCategoryIds.addAll(subCats.map((c) => c.id));
    }

    // 3. Filter products list by category
    List<ProductModel> filteredProductsList = productProvider.products;
    if (_selectedCategoryId != null) {
      filteredProductsList = productProvider.products
          .where((p) => activeCategoryIds.contains(p.mainCategoryId) || activeCategoryIds.contains(p.subCategoryId))
          .toList();
    }
    final Set<String> filteredProductNames = filteredProductsList.map((p) => p.name).toSet();

    // 4. Calculate stats based on filters in memory (optimized database queries)
    double calculatedRevenue = 0.0;
    int calculatedOrdersCount = 0;
    int calculatedItemsSold = 0;

    Map<String, _ProductSalesStats> productSalesStats = {};
    Map<String, _CustomerStats> customerStats = {};

    for (var order in completedOrders) {
      bool orderHasMatchingItems = false;
      double orderMatchingAmount = 0.0;
      int orderMatchingQty = 0;

      for (var item in order.items) {
        if (_selectedProductId != null) {
          final target = productProvider.products.firstWhere((p) => p.id == _selectedProductId, orElse: () => ProductModel(id: '', name: '', description: '', price: 0, mainCategoryId: '', subCategoryId: '', images: [], createdAt: DateTime.now()));
          if (item.productName != target.name) continue;
        } else if (_selectedCategoryId != null) {
          if (!filteredProductNames.contains(item.productName)) continue;
        }

        orderHasMatchingItems = true;
        orderMatchingAmount += item.totalPrice;
        orderMatchingQty += item.quantity;

        final pStats = productSalesStats.putIfAbsent(item.productName, () => _ProductSalesStats(name: item.productName));
        pStats.qty += item.quantity;
        pStats.revenue += item.totalPrice;
      }

      if (orderHasMatchingItems) {
        calculatedRevenue += orderMatchingAmount;
        calculatedOrdersCount++;
        calculatedItemsSold += orderMatchingQty;

        final key = '${order.customerName}_${order.customerPhone}';
        final cStats = customerStats.putIfAbsent(key, () => _CustomerStats(name: order.customerName, phone: order.customerPhone));
        cStats.count++;
        cStats.spent += orderMatchingAmount;
      }
    }

    final topProductsList = productSalesStats.values.toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));

    final topCustomersList = customerStats.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التقارير والإحصائيات 📊',
          style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        elevation: 1,
      ),
      body: analyticsProvider.isLoading
          ? const LoadingIndicator(message: 'جاري تحميل واحتساب التقارير التفصيلية...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interactive filter segment
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تحديد فترة التقرير:',
                            style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildFilterTypeButton('يومي', 'daily'),
                              const SizedBox(width: 8),
                              _buildFilterTypeButton('أسبوعي', 'weekly'),
                              const SizedBox(width: 8),
                              _buildFilterTypeButton('شهري', 'monthly'),
                              const SizedBox(width: 8),
                              _buildFilterTypeButton('مخصص', 'custom'),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _getReportRangeText(),
                                  style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                icon: const Icon(Icons.date_range, color: Colors.white, size: 16),
                                label: Text(
                                  _reportType == 'custom' ? 'تحديد الفترة' : 'تغيير التاريخ',
                                  style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                onPressed: _reportType == 'custom' ? _pickCustomRange : _pickDate,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Advanced product/category dropdown filters
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خيارات الفلترة والتصفية المتقدمة:',
                            style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Category filter
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategoryId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'الفئة',
                                    labelStyle: AppFonts.cairoFont(fontSize: 11),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('جميع الفئات', style: AppFonts.cairoFont(fontSize: 12)),
                                    ),
                                    ...categoryProvider.categories.map((c) => DropdownMenuItem<String>(
                                          value: c.id,
                                          child: Text(c.name, style: AppFonts.cairoFont(fontSize: 12)),
                                        )),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedCategoryId = val;
                                      _selectedProductId = null; // Reset product filter when category changes
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Product filter
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedProductId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'المنتج',
                                    labelStyle: AppFonts.cairoFont(fontSize: 11),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('جميع المنتجات', style: AppFonts.cairoFont(fontSize: 12)),
                                    ),
                                    ...filteredProductsList.map((p) => DropdownMenuItem<String>(
                                          value: p.id,
                                          child: Text(p.name, style: AppFonts.cairoFont(fontSize: 12)),
                                        )),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedProductId = val;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calculated Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        'إجمالي الإيرادات',
                        Formatters.formatCurrency(calculatedRevenue),
                        Icons.account_balance_wallet,
                        AppColors.success,
                      ),
                      _buildStatCard(
                        'عدد الطلبات',
                        '$calculatedOrdersCount طلب',
                        Icons.shopping_bag,
                        AppColors.primary,
                      ),
                      _buildStatCard(
                        'قطع مباعة',
                        '$calculatedItemsSold قطعة',
                        Icons.fastfood,
                        AppColors.warning,
                      ),
                      _buildStatCard(
                        'متوسط الطلب',
                        Formatters.formatCurrency(calculatedOrdersCount > 0 ? calculatedRevenue / calculatedOrdersCount : 0),
                        Icons.trending_up,
                        AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // PDF Export Button
                  CustomButton(
                    text: 'تصدير كشف حساب / تقرير PDF 📄',
                    onPressed: () => _exportPdfReport(
                      authProvider,
                      productProvider,
                      categoryProvider,
                      completedOrders,
                      topProductsList,
                      topCustomersList,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Data Display - Top Products & Customers
                  Text(
                    _selectedProductId != null
                        ? 'كشف بيع الصنف المالي 🏆'
                        : _selectedCategoryId != null
                            ? 'أكثر أصناف الفئة مبيعاً 🏆'
                            : 'الوجبات والأصناف الأكثر مبيعاً 🏆',
                    style: AppFonts.cairoFont(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  topProductsList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'لا توجد عمليات بيع مسجلة لهذه التصفية',
                              style: AppFonts.cairoFont(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topProductsList.length,
                          itemBuilder: (ctx, idx) {
                            final item = topProductsList[idx];
                            final maxQty = topProductsList.first.qty;
                            final progress = maxQty > 0 ? item.qty / maxQty : 0.0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '#${idx + 1} - ${item.name}',
                                          style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${item.qty} قطع (${Formatters.formatCurrency(item.revenue)})',
                                          style: AppFonts.cairoFont(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress.clamp(0.0, 1.0),
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  if (_selectedProductId == null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'أكثر العملاء طلباً وشراءً 👥',
                      style: AppFonts.cairoFont(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    topCustomersList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'لا توجد بيانات عملاء مسجلة',
                                style: AppFonts.cairoFont(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topCustomersList.take(10).length,
                            itemBuilder: (ctx, idx) {
                              final cust = topCustomersList[idx];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withAlpha(20),
                                    child: const Icon(Icons.person, color: AppColors.primary),
                                  ),
                                  title: Text(cust.name, style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold)),
                                  subtitle: Text('هاتف: ${cust.phone}', style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade600)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${cust.count} طلبات', style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      Text(Formatters.formatCurrency(cust.spent), style: AppFonts.cairoFont(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFilterTypeButton(String label, String type) {
    final isSelected = _reportType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _reportType = type;
            _selectedProductId = null;
            _selectedCategoryId = null;
          });
          _fetchReportData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppFonts.cairoFont(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade800)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppFonts.cairoFont(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
