import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../customer_app/providers/complaint_provider.dart';
import '../../../shared/models/complaint_model.dart';

/// Admin Screen for viewing, managing, calling customers, and deleting complaints & suggestions
class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  String _selectedFilter = 'الكل'; // 'الكل', 'شكوى', 'مقترح', 'استفسار'

  void _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          CustomDialog.showErrorSnackBar(context, 'تعذر إجراء الاتصال برقم $cleanPhone');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.showErrorSnackBar(context, 'خطأ في فتح تطبيق الهاتف: $e');
      }
    }
  }

  void _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullPhone = cleanPhone.startsWith('967') ? cleanPhone : '967$cleanPhone';
    final uri = Uri.parse('whatsapp://send?phone=$fullPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      } else {
        final webUri = Uri.parse('https://wa.me/$fullPhone');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            CustomDialog.showErrorSnackBar(context, 'تطبيق الواتساب غير مثبت على الجهاز');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.showErrorSnackBar(context, 'تعذر فتح الواتساب: $e');
      }
    }
  }

  void _confirmDelete(ComplaintModel complaint, ComplaintProvider provider) async {
    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'حذف الرسالة نهائياً',
      message: 'هل أنت متأكد من مسح رسالة ${complaint.customerName} نهائياً لتفريغ المساحة؟',
      confirmText: 'حذف الآن',
      confirmColor: AppColors.danger,
    );

    if (confirm == true) {
      final ok = await provider.deleteComplaint(complaint.id);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم حذف الرسالة بنجاح وتفريغ المساحة 🗑️');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allComplaints = complaintProvider.complaints;
    final filtered = _selectedFilter == 'الكل'
        ? allComplaints
        : allComplaints.where((c) => c.type == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'صندوق الشكاوى والمقترحات 📩',
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Filter Chips Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل (${allComplaints.length})', 'الكل'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'الشكاوى ⚠️ (${allComplaints.where((c) => c.type == 'شكوى').length})',
                    'شكوى',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'المقترحات 💡 (${allComplaints.where((c) => c.type == 'مقترح').length})',
                    'مقترح',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'الاستفسارات ❓ (${allComplaints.where((c) => c.type == 'استفسار').length})',
                    'استفسار',
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Main List View
          Expanded(
            child: complaintProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد رسائل أو شكاوى حالياً',
                              style: AppFonts.cairoFont(fontSize: 15, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final complaint = filtered[idx];
                          return _buildComplaintCard(complaint, complaintProvider, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label, style: AppFonts.cairoFont(fontSize: 11, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey.shade100,
      labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : Colors.black87)),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint, ComplaintProvider provider, bool isDark) {
    Color typeColor;
    switch (complaint.type) {
      case 'شكوى':
        typeColor = AppColors.danger;
        break;
      case 'مقترح':
        typeColor = Colors.orange.shade700;
        break;
      default:
        typeColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Customer Name & Type Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: typeColor.withAlpha(30),
                      child: Icon(Icons.person_outline, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.customerName.isEmpty ? 'عميل بدون اسم' : complaint.customerName,
                            style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'هاتف: ${complaint.customerPhone}${complaint.customerAddress.isNotEmpty ? " • العنوان: ${complaint.customerAddress}" : ""}',
                            style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: typeColor.withAlpha(80)),
                ),
                child: Text(
                  complaint.type,
                  style: AppFonts.cairoFont(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Message Body
          Text(
            complaint.message,
            style: AppFonts.cairoFont(
              fontSize: 13,
              color: isDark ? AppColors.darkTextPrimary : Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Footer: Timestamp & Action Buttons (Call, WhatsApp, Delete)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.formatDateTime(complaint.createdAt),
                style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone_enabled_outlined, color: Colors.green, size: 20),
                    tooltip: 'اتصال هاتفي بالعميل',
                    onPressed: () => _callPhone(complaint.customerPhone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_outlined, color: Colors.teal, size: 20),
                    tooltip: 'مراسلة عبر واتساب',
                    onPressed: () => _openWhatsApp(complaint.customerPhone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                    tooltip: 'حذف وتفريغ الرسالة',
                    onPressed: () => _confirmDelete(complaint, provider),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
