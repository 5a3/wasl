import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/order_model.dart';

/// Interactive Printable Cafeteria Order Receipt Modal with Cairo PDF Font Support
class OrderReceiptDialog extends StatelessWidget {
  final OrderModel order;

  const OrderReceiptDialog({super.key, required this.order});

  /// Clean Arabic text for PDF to remove emojis and handle Arabic characters
  static String cleanPdfText(String text) {
    text = text.trim();
    if (text.isEmpty) return text;
    // Remove emojis that break TTF font rendering
    text = text.replaceAll(RegExp(r'[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '');
    // Normalize Persian Ya (ی) to Arabic Ya (ي)
    text = text.replaceAll('\u06CC', '\u064A');
    return text.trim();
  }

  Future<void> _printReceipt(BuildContext context) async {
    final pdf = pw.Document();

    // Fetch Cairo font for clean Arabic PDF rendering
    final cairoRegular = await PdfGoogleFonts.cairoMedium();
    final cairoBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt Roll Format
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
                pw.Center(
                  child: pw.Text(cleanPdfText(AppConstants.appName), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: cairoBold)),
                ),
                pw.Center(
                  child: pw.Text(cleanPdfText('فاتورة سند طلب - #${order.orderNumber}'), style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Divider(thickness: 0.5),
                pw.Text(cleanPdfText('العميل: ${order.customerName}'), style: const pw.TextStyle(fontSize: 9)),
                pw.Text(cleanPdfText('الهاتف: ${order.customerPhone}'), style: const pw.TextStyle(fontSize: 9)),
                pw.Text(cleanPdfText('منطقة التوصيل: ${order.deliveryZoneName}'), style: const pw.TextStyle(fontSize: 9)),
                pw.Text(cleanPdfText('العنوان: ${order.deliveryAddress}'), style: const pw.TextStyle(fontSize: 9)),
                pw.Text(cleanPdfText('التاريخ: ${Formatters.formatDateTime(order.createdAt)}'), style: const pw.TextStyle(fontSize: 8)),
                pw.Divider(thickness: 0.5),
                ...order.items.map((item) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(cleanPdfText('${item.productName} (x${item.quantity})'), style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Text(cleanPdfText('${item.totalPrice} ر.ي'), style: const pw.TextStyle(fontSize: 8)),
                      ],
                    )),
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(cleanPdfText('أجرة التوصيل:'), style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(cleanPdfText('${order.deliveryFee} ر.ي'), style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(cleanPdfText('الإجمالي المستحق:'), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: cairoBold)),
                    pw.Text(cleanPdfText('${order.totalAmount} ر.ي'), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: cairoBold)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(cleanPdfText('شكراً لطلبكم من واصل!'), style: const pw.TextStyle(fontSize: 9)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'فاتورة_طلب_${order.orderNumber}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.appName,
                        style: AppFonts.cairoFont(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'سند وفاتورة طلب #${order.orderNumber}',
                        style: AppFonts.cairoFont(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),

                // Customer & Delivery Metadata
                _buildInfoRow('اسم العميل:', order.customerName),
                _buildInfoRow('رقم الهاتف:', order.customerPhone),
                _buildInfoRow('منطقة التوصيل:', order.deliveryZoneName),
                _buildInfoRow('عنوان التوصيل:', order.deliveryAddress),
                _buildInfoRow('تاريخ الطلب:', Formatters.formatDateTime(order.createdAt)),
                _buildInfoRow('حالة الطلب:', order.statusArabic),

                const SizedBox(height: 16),
                Text(
                  'تفاصيل الوجبات والمأكولات:',
                  style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Items Table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = order.items[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName} (x${item.quantity})',
                                style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(item.totalPrice),
                              style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Totals Breakdown (Fixed overflow by using Expanded)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('مجموع المنتجات:', style: AppFonts.cairoFont(fontSize: 13)),
                          ),
                          Text(Formatters.formatCurrency(order.subtotal), style: AppFonts.cairoFont(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('أجرة التوصيل (${order.deliveryZoneName}):', style: AppFonts.cairoFont(fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text(Formatters.formatCurrency(order.deliveryFee), style: AppFonts.cairoFont(fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('الإجمالي النهائي المستحق:', style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            Formatters.formatCurrency(order.totalAmount),
                            style: AppFonts.cairoFont(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.print, color: AppColors.primary),
                        label: Text(
                          'طباعة/حفظ PDF',
                          style: AppFonts.cairoFont(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _printReceipt(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'إغلاق السند',
                          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppFonts.cairoFont(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
