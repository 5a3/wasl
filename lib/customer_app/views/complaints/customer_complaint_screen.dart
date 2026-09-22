import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/customer_auth_provider.dart';

/// Full Screen Page for Customers to submit Complaints & Suggestions and access Direct Admin Contacts
class CustomerComplaintScreen extends StatefulWidget {
  const CustomerComplaintScreen({super.key});

  @override
  State<CustomerComplaintScreen> createState() => _CustomerComplaintScreenState();
}

class _CustomerComplaintScreenState extends State<CustomerComplaintScreen> {
  final _messageController = TextEditingController();
  String _selectedType = 'شكوى';
  int _todayCount = 0;
  bool _checkingCount = true;

  @override
  void initState() {
    super.initState();
    _checkDailyLimit();
  }

  Future<void> _checkDailyLimit() async {
    final customer = Provider.of<CustomerAuthProvider>(context, listen: false).currentCustomer;
    if (customer != null) {
      final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
      final count = await complaintProvider.getTodayComplaintsCount(customer.id);
      if (mounted) {
        setState(() {
          _todayCount = count;
          _checkingCount = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _checkingCount = false;
        });
      }
    }
  }

  void _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      CustomDialog.showErrorSnackBar(context, 'يرجى كتابة تفاصيل الشكوى أو المقترح أولاً');
      return;
    }

    final authProvider = Provider.of<CustomerAuthProvider>(context, listen: false);
    final customer = authProvider.currentCustomer;
    if (customer == null) {
      CustomDialog.showErrorSnackBar(context, 'يرجى تسجيل الدخول أولاً لإرسال الشكاوى والمقترحات');
      return;
    }

    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    final success = await complaintProvider.submitComplaint(
      customer: customer,
      type: _selectedType,
      message: message,
    );

    if (mounted) {
      if (success) {
        _messageController.clear();
        await _checkDailyLimit();
        if (mounted) {
          CustomDialog.showSuccessSnackBar(
            context,
            'تم إرسال رسالتك إلى إدارة التطبيق بنجاح! سيتم التواصل معك عند الحاجة 🕊️',
          );
        }
      } else if (complaintProvider.errorMessage != null) {
        CustomDialog.showErrorSnackBar(context, complaintProvider.errorMessage!);
      }
    }
  }

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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final isLimitReached = _todayCount >= 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الشكاوى والمقترحات 📩',
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نحن نهتم برأيك وسماع صوتك! 🕊️',
                          style: AppFonts.cairoFont(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'أرسل ملاحظتك أو مقترحك مباشرة لتطوير الخدمة بأعلى جودة.',
                          style: AppFonts.cairoFont(fontSize: 11, color: Colors.white.withAlpha(230)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (_checkingCount) ...[
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            ] else ...[
              // Rate Limit Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isLimitReached ? AppColors.danger.withAlpha(20) : AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLimitReached ? AppColors.danger.withAlpha(80) : AppColors.primary.withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLimitReached ? Icons.block : Icons.info_outline,
                      color: isLimitReached ? AppColors.danger : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isLimitReached
                            ? 'وصلت للحد الأقصى المسموح به اليوم (2/2) 🛑'
                            : 'استهلكت ($_todayCount من 2) محاولة إرسال مسموحة اليوم',
                        style: AppFonts.cairoFont(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLimitReached ? AppColors.danger : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Message Type Selector
              Text(
                'اختر نوع الرسالة:',
                style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeChip('شكوى ⚠️', 'شكوى'),
                  const SizedBox(width: 10),
                  _buildTypeChip('مقترح 💡', 'مقترح'),
                  const SizedBox(width: 10),
                  _buildTypeChip('استفسار ❓', 'استفسار'),
                ],
              ),
              const SizedBox(height: 18),

              // Message Text Area
              Text(
                'تفاصيل الشكوى أو المقترح:',
                style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 5,
                enabled: !isLimitReached,
                style: AppFonts.cairoFont(fontSize: 13),
                decoration: InputDecoration(
                  hintText: isLimitReached
                      ? 'عفواً، لا يمكنك إرسال رسائل جديدة اليوم...'
                      : 'اكتب تفاصيل ملاحظتك أو الشكوى بالتفصيل ليتمكن فريق الإدارة من مساعدتك والتواصل معك...',
                  hintStyle: AppFonts.cairoFont(fontSize: 12, color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              if (isLimitReached) ...[
                CustomButton(
                  text: 'تم استهلاك محاولات اليوم (2/2) 🛑',
                  onPressed: null,
                  backgroundColor: Colors.grey.shade400,
                ),
              ] else ...[
                CustomButton(
                  text: 'إرسال الرسالة إلى الإدارة 🚀',
                  isLoading: complaintProvider.isLoading,
                  onPressed: _submit,
                ),
              ],
            ],

            const SizedBox(height: 30),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Direct Phone Contacts Section (If customer wants direct contact)
            Text(
              'أو التواصل المباشر مع أصحاب الإدارة 📞:',
              style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Contact 2: App Developer & Support
            _buildContactCard(
              title: 'الدعم الفني ومطور التطبيق 🛠️',
              subtitle: 'م. أحمد العطاس',
              phone: '770985114',
              isDark: isDark,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _selectedType == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppFonts.cairoFont(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String title,
    required String subtitle,
    required String phone,
    required bool isDark,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phone_in_talk, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$subtitle • $phone',
                        style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.green, size: 22),
                tooltip: 'اتصال هاتف مباشر',
                onPressed: () => _callPhone(phone),
              ),
              IconButton(
                icon: const Icon(Icons.chat_outlined, color: Colors.teal, size: 22),
                tooltip: 'مراسلة عبر واتساب',
                onPressed: () => _openWhatsApp(phone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
