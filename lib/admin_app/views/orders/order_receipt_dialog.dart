import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<pw.Document> _generatePdf() async {
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
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(
          base: cairoRegular,
          bold: cairoBold,
        ),
        build: (pw.Context pwContext) {
          return pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.all(12),
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Centered top logo header
                  pw.Center(
                    child: pw.Container(
                      width: 100,
                      height: 50,
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
                  pw.Center(
                    child: pw.Text(
                      cleanPdfText('المطعم / المتجر: ${order.storeName ?? "عام"}'),
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, font: cairoBold),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Divider(thickness: 0.5),
                  pw.SizedBox(height: 4),

                  // Customer & Delivery Details
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(child: pw.Text(cleanPdfText('العميل: ${order.customerName}'), style: const pw.TextStyle(fontSize: 8))),
                      pw.SizedBox(width: 4),
                      pw.Expanded(child: pw.Text(cleanPdfText('هاتف التواصل: ${order.customerPhone}'), style: const pw.TextStyle(fontSize: 8))),
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
                  pw.SizedBox(height: 2),
                  pw.Text(cleanPdfText('طريقة الدفع: ${order.paymentMethodName ?? "الدفع عند الاستلام"}'), style: const pw.TextStyle(fontSize: 8)),
                  if (order.paymentNote != null && order.paymentNote!.isNotEmpty) ...[
                    pw.SizedBox(height: 1),
                    pw.Text(cleanPdfText('تفاصيل الدفع: ${order.paymentNote}'), style: const pw.TextStyle(fontSize: 7)),
                  ],
                  pw.SizedBox(height: 4),
                  pw.Divider(thickness: 0.5),
                  pw.SizedBox(height: 4),

                  // Items
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

                  pw.SizedBox(height: 4),
                  pw.Divider(thickness: 0.5),
                  pw.SizedBox(height: 4),

                  // Pricing breakdown
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
                  pw.SizedBox(height: 2),
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

                  // Footer logo and developer credits
                  pw.Center(
                    child: pw.Text(
                      cleanPdfText('شكراً لطلبكم من وصل لي! ✨'),
                      style: pw.TextStyle(fontSize: 9, font: cairoBold),
                    ),
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
            ),
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _printReceipt(BuildContext context) async {
    final pdf = await _generatePdf();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'فاتورة_طلب_${order.orderNumber}',
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return Colors.orange;
      case AppConstants.statusAcceptedPreparing:
        return AppColors.primary;
      case AppConstants.statusDelivering:
        return Colors.blue;
      case AppConstants.statusDelivered:
        return Colors.green;
      case AppConstants.statusCanceled:
        return AppColors.danger;
      default:
        return Colors.grey;
    }
  }

  /// Share receipt page as a rendered image with white background & open WhatsApp to customer phone number
  Future<void> _shareReceiptImage(BuildContext context) async {
    try {
      final pdf = await _generatePdf();
      final pdfBytes = await pdf.save();

      String? filePath;
      // Render PDF page to PNG image with high DPI (300) and opaque white background
      await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
        final pngBytes = await page.toPng();

        final tempDir = await getTemporaryDirectory();
        filePath = '${tempDir.path}/receipt_${order.orderNumber}.png';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);
        break;
      }

      if (filePath == null) return;

      final cleanPhone = order.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final fullPhone = cleanPhone.startsWith('967') ? cleanPhone : '967$cleanPhone';
      final shareText = 'سند فاتورة طلب رقم #${order.orderNumber}\nالعميل: ${order.customerName}\nالهاتف: ${order.customerPhone}\nطريقة الدفع: ${order.paymentMethodName ?? "الدفع عند الاستلام"}\nالإجمالي: ${Formatters.formatCurrency(order.totalAmount)}\nشكراً لتعاملك معنا ✨';

      // 1. Share PNG image file via Share sheet (allowing selecting WhatsApp)
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(filePath)],
        text: shareText,
        subject: 'سند طلب #${order.orderNumber}',
      );

      // 2. Direct URI launch to customer WhatsApp chat phone number
      final whatsappUri = Uri.parse('whatsapp://send?phone=$fullPhone');
      try {
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalNonBrowserApplication);
        } else {
          final webUri = Uri.parse('https://wa.me/$fullPhone');
          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        debugPrint('Error launching WhatsApp URI: $e');
      }
    } catch (e) {
      debugPrint('Error sharing receipt image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('عذراً، حدث خطأ أثناء تجهيز أو مشاركة السند كصورة: $e', style: AppFonts.cairoFont(color: Colors.white)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'سند الفاتورة - #${order.orderNumber}',
                      style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content Receipt
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Status Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getStatusColor(order.status)),
                        ),
                        child: Text(
                          order.statusArabic,
                          style: AppFonts.cairoFont(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer Info Section
                    Text(
                      'بيانات العميل والتوصيل:',
                      style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, 'المطعم / المتجر:', order.storeName ?? 'عام (غير محدد)'),
                    _buildInfoRow(context, 'اسم العميل:', order.customerName),
                    _buildInfoRow(context, 'رقم الجوال:', order.customerPhone),
                    if (order.additionalPhone != null && order.additionalPhone!.trim().isNotEmpty)
                      _buildInfoRow(context, 'هاتف بديل:', order.additionalPhone!),
                    _buildInfoRow(context, 'المنطقة:', order.deliveryZoneName),
                    _buildInfoRow(context, 'العنوان التفصيلي:', order.deliveryAddress),
                    _buildInfoRow(context, 'تاريخ الطلب:', Formatters.formatDateTime(order.createdAt)),
                    if (order.note != null && order.note!.trim().isNotEmpty)
                      _buildInfoRow(context, 'ملاحظات العميل:', order.note!),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Order Items Table Header
                    Text(
                      'قائمة الوجبات والطلبات:',
                      style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text('الوجبة', style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('العدد', textAlign: TextAlign.center, style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('السعر', textAlign: TextAlign.start, style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('الإجمالي', textAlign: TextAlign.end, style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Items List
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.productName,
                                style: AppFonts.cairoFont(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'x${item.quantity}',
                                textAlign: TextAlign.center,
                                style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                Formatters.formatCurrency(item.price),
                                textAlign: TextAlign.start,
                                style: AppFonts.cairoFont(fontSize: 11),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                Formatters.formatCurrency(item.totalPrice),
                                textAlign: TextAlign.end,
                                style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Financial Summary Breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder.withAlpha(50) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('مجموع الوجبات:', style: AppFonts.cairoFont(fontSize: 13)),
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
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.print, color: AppColors.primary, size: 18),
                                label: Text(
                                  'طباعة/حفظ PDF',
                                  style: AppFonts.cairoFont(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                onPressed: () => _printReceipt(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.share, color: Colors.white, size: 18),
                                label: Text(
                                  'مشاركة كصورة 📸',
                                  style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                onPressed: () => _shareReceiptImage(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'إغلاق السند',
                              style: AppFonts.cairoFont(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
