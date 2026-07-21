import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../providers/analytics_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTodayReports();
    });
  }

  void _fetchTodayReports() {
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;
    Provider.of<AnalyticsProvider>(context, listen: false).fetchAnalyticsForRange(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _fetchWeeklyReports() {
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 7));
    _endDate = now;
    Provider.of<AnalyticsProvider>(context, listen: false).fetchAnalyticsForRange(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _fetchMonthlyReports() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    Provider.of<AnalyticsProvider>(context, listen: false).fetchAnalyticsForRange(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      if (mounted) {
        Provider.of<AnalyticsProvider>(context, listen: false).fetchAnalyticsForRange(
          startDate: _startDate,
          endDate: _endDate,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analytics = Provider.of<AnalyticsProvider>(context);
    final report = analytics.currentReport;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تصفية وتقارير المبيعات',
              style: AppFonts.cairoFont(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _fetchTodayReports,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('اليوم', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _fetchWeeklyReports,
                    child: const Text('هذا الأسبوع'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _fetchMonthlyReports,
                    child: const Text('هذا الشهر'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.date_range, color: AppColors.primary),
                    tooltip: 'فلترة من تاريخ إلى تاريخ',
                    onPressed: _pickCustomDateRange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الفترة: من ${Formatters.formatDate(_startDate)} إلى ${Formatters.formatDate(_endDate)}',
              style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            if (analytics.isLoading)
              const LoadingIndicator(message: 'جاري حساب التقارير وتوفير القراءات...')
            else if (report != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'إجمالي المبيعات',
                      value: Formatters.formatCurrency(report.totalRevenue),
                      color: AppColors.primary,
                      icon: Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'عدد الطلبات',
                      value: '${report.totalOrders} طلب',
                      color: AppColors.info,
                      icon: Icons.shopping_bag,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'الطلبات المكتملة',
                      value: '${report.deliveredOrders} طلب',
                      color: AppColors.success,
                      icon: Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'الطلبات الملغاة',
                      value: '${report.canceledOrders} طلب',
                      color: AppColors.danger,
                      icon: Icons.cancel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'تفاصيل مبيعات المنتجات في الفترة المحددة',
                style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (report.productSales.isEmpty)
                Text(
                  'لا توجد مبيعات منتجات مسجلة في هذه الفترة',
                  style: AppFonts.cairoFont(fontSize: 14, color: Colors.grey),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: report.productSales.length,
                  itemBuilder: (ctx, index) {
                    final prodId = report.productSales.keys.elementAt(index);
                    final qty = report.productSales[prodId];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.accent,
                          child: Icon(Icons.fastfood, color: Colors.black),
                        ),
                        title: Text('منتج المعرف: $prodId', style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          'تم بيع $qty قطعة',
                          style: AppFonts.cairoFont(fontWeight: FontWeight.bold, color: AppColors.primary),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
