import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pdf_helper.dart';
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
    // Apply custom Arabic reshaping to fix dots on final form of Yeh (ي)
    return PdfHelper.reshapeArabic(text.trim());
  }

  Future<void> _printReceipt(BuildContext context) async {
    final pdf = pw.Document();

    // Fetch Cairo font for clean Arabic PDF rendering from cached helper
    final cairoRegular = await PdfHelper.cairoRegular;
    final cairoBold = await PdfHelper.cairoBold;

    // Load SVG files as strings for rendering inside PDF
    final logoReportSvg = await rootBundle.loadString('assets/images/logoreport.svg');
    final logoSvg = await rootBundle.loadString('assets/images/logo.svg');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        theme: pw.ThemeData.withFont(
          base: cairoRegular,
          bold: cairoBold,
        ),
        build: (pw.Context pwContext) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Centered logo header
                pw.Center(
                  child: pw.Container(
                    width: 90,
                    height: 45,
                    child: pw.SvgImage(svg: logoReportSvg),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    cleanPdfText(AppConstants.appName),
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, font: cairoBold),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    cleanPdfText('فاتورة سند طلب - #${order.orderNumber}'),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Divider(thickness: 0.5),

                // Customer & Delivery Details - 2 columns per row
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: pw.Text(cleanPdfText('العميل: ${order.customerName}'), style: const pw.TextStyle(fontSize: 8))),
                    pw.SizedBox(width: 4),
                    pw.Expanded(child: pw.Text(cleanPdfText('هاتف: ${order.customerPhone}'), style: const pw.TextStyle(fontSize: 8))),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: pw.Text(cleanPdfText('المنطقة: ${order.deliveryZoneName}'), style: const pw.TextStyle(fontSize: 8))),
                    pw.SizedBox(width: 4),
                    pw.Expanded(child: pw.Text(cleanPdfText('العنوان: ${order.deliveryAddress}'), style: const pw.TextStyle(fontSize: 8))),
                  ],
                ),
                pw.SizedBox(height: 2),
                if (order.additionalPhone != null && order.additionalPhone!.trim().isNotEmpty) ...[
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          cleanPdfText('هاتف بديل: ${order.additionalPhone}'),
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, font: cairoBold),
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Expanded(child: pw.Text(cleanPdfText('التاريخ: ${Formatters.formatDateTime(order.createdAt)}'), style: const pw.TextStyle(fontSize: 8))),
                    ],
                  ),
                ] else ...[
                  pw.Text(cleanPdfText('التاريخ: ${Formatters.formatDateTime(order.createdAt)}'), style: const pw.TextStyle(fontSize: 8)),
                ],
                if (order.note != null && order.note!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(cleanPdfText('ملاحظات: ${order.note}'), style: const pw.TextStyle(fontSize: 8)),
                ],
                pw.Divider(thickness: 0.5),

                // Items - RTL rows: Name(xQty) on right | Price on left
                ...order.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          cleanPdfText('${item.productName} (x${item.quantity})'),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        cleanPdfText('${item.totalPrice} ر.ي'),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                )),

                pw.Divider(thickness: 0.5),

                // Pricing breakdown - label left, value right (RTL)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(cleanPdfText('مجموع الوجبات:'), style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(cleanPdfText('${order.subtotal} ر.ي'), style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(cleanPdfText('رسوم التوصيل:'), style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(cleanPdfText('${order.deliveryFee} ر.ي'), style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      cleanPdfText('الإجمالي المستحق:'),
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: cairoBold),
                    ),
                    pw.Text(
                      cleanPdfText('${order.totalAmount} ر.ي'),
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: cairoBold),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 6),

                // Footer - centered
                pw.Center(
                  child: pw.Text(cleanPdfText('شكراً لطلبكم من وصل لي!'), style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Container(
                    width: 36,
                    height: 36,
                    child: pw.SvgImage(svg: logoSvg),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.3),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    cleanPdfText('برمجة: م. احمد العطاس'),
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    '770985114',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
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
                _buildInfoRow(context, 'اسم العميل:', order.customerName),
                _buildInfoRow(context, 'هاتف التواصل الأساسي:', order.customerPhone),
                if (order.additionalPhone != null && order.additionalPhone!.trim().isNotEmpty)
                  _buildInfoRow(context, 'هاتف التواصل البديل:', order.additionalPhone!),
                _buildInfoRow(context, 'منطقة التوصيل:', order.deliveryZoneName),
                _buildInfoRow(context, 'عنوان التوصيل:', order.deliveryAddress),
                _buildInfoRow(context, 'تاريخ الطلب:', Formatters.formatDateTime(order.createdAt)),
                _buildInfoRow(context, 'حالة الطلب:', order.statusArabic),
                if (order.note != null && order.note!.trim().isNotEmpty)
                  _buildInfoRow(context, 'ملاحظات الطلب:', order.note!),

                const SizedBox(height: 16),
                Text(
                  'تفاصيل الوجبات والمأكولات:',
                  style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Items Table
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                    ),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppFonts.cairoFont(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppFonts.cairoFont(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
