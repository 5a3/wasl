import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../providers/analytics_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalyticsProvider>(context, listen: false).fetchDailyReport(_selectedDate);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (mounted) {
        Provider.of<AnalyticsProvider>(context, listen: false).fetchDailyReport(picked);
      }
    }
  }

  Future<void> _exportPdfReport(AnalyticsProvider analytics) async {
    final pdf = pw.Document();

    final cairoRegular = await PdfGoogleFonts.cairoMedium();
    final cairoBold = await PdfGoogleFonts.cairoBold();

    final logoData = await rootBundle.load('assets/images/logoreport.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: cairoRegular,
          bold: cairoBold,
        ),
        build: (pw.Context pwContext) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('تقرير مبيعات واصل الوجبات السريعة', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, font: cairoBold)),
                          pw.Text('تاريخ التقرير: ${Formatters.formatDate(_selectedDate)}', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Container(
                        width: 50,
                        height: 50,
                        child: pw.Image(logoImage),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('إجمالي المبيعات والإيرادات: ${Formatters.formatCurrency(analytics.totalRevenue)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, font: cairoBold)),
                pw.Text('عدد الطلبات الإجمالي: ${analytics.totalOrdersCount} طلب', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('عدد الوجبات والمنتجات المباعة: ${analytics.totalItemsSold} قطعة', style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 20),
                pw.Text('الأصناف والوجبات الأكثر مبيعاً:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, font: cairoBold)),
                pw.Divider(thickness: 0.5),
                ...analytics.topProducts.map((p) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(p.productName, style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('الكمية المباعة: ${p.quantitySold} قطعة', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    )),
                pw.Spacer(),
                pw.Divider(thickness: 0.5),
                pw.Center(child: pw.Text('تم استخراج هذا التقرير تلقائياً من نظام واصل للمأكولات السريعة والعصائر', style: const pw.TextStyle(fontSize: 9))),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'تقرير_مبيعات_${Formatters.formatDate(_selectedDate)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AnalyticsProvider>(
        builder: (context, analytics, _) {
          if (analytics.isLoading) {
            return const LoadingIndicator(message: 'جاري احتساب التقارير والإحصائيات...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Picker Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تقرير يوم: ${Formatters.formatDate(_selectedDate)}',
                      style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                      label: Text(
                        'تغيير اليوم',
                        style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Cards Summary Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      'مجموع الإيرادات',
                      Formatters.formatCurrency(analytics.totalRevenue),
                      Icons.account_balance_wallet,
                      AppColors.success,
                    ),
                    _buildStatCard(
                      'عدد الطلبات',
                      '${analytics.totalOrdersCount} طلب',
                      Icons.shopping_bag,
                      AppColors.primary,
                    ),
                    _buildStatCard(
                      'أصناف مباعة',
                      '${analytics.totalItemsSold} قطعة',
                      Icons.fastfood,
                      AppColors.warning,
                    ),
                    _buildStatCard(
                      'متوسط الطلب',
                      Formatters.formatCurrency(analytics.totalOrdersCount > 0 ? analytics.totalRevenue / analytics.totalOrdersCount : 0),
                      Icons.trending_up,
                      AppColors.info,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Export PDF Button
                CustomButton(
                  text: 'تصدير وطباعة تقرير المبيعات PDF 📄',
                  onPressed: () => _exportPdfReport(analytics),
                ),

                const SizedBox(height: 28),

                Text(
                  'الوجبات والأصناف الأكثر مبيعاً 🏆',
                  style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                analytics.topProducts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'لا توجد مبيعات مسجلة في هذا اليوم',
                            style: AppFonts.cairoFont(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: analytics.topProducts.length,
                        itemBuilder: (ctx, idx) {
                          final item = analytics.topProducts[idx];
                          final maxQty = analytics.topProducts.first.quantitySold;
                          final progress = maxQty > 0 ? item.quantitySold / maxQty : 0.0;

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
                                        '#${idx + 1} - ${item.productName}',
                                        style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${item.quantitySold} قطعة (${Formatters.formatCurrency(item.totalRevenue)})',
                                        style: AppFonts.cairoFont(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(title, style: AppFonts.cairoFont(fontSize: 13, color: Colors.grey.shade800)),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
