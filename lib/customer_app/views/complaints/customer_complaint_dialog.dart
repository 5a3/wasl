import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/customer_auth_provider.dart';

/// Interactive Modal Dialog for Customers to submit Complaints & Suggestions (Max 2/day)
class CustomerComplaintDialog extends StatefulWidget {
  const CustomerComplaintDialog({super.key});

  @override
  State<CustomerComplaintDialog> createState() => _CustomerComplaintDialogState();
}

class _CustomerComplaintDialogState extends State<CustomerComplaintDialog> {
  final _messageController = TextEditingController();
  String _selectedType = 'شكوى'; // Default choice
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
        Navigator.of(context).pop();
        CustomDialog.showSuccessSnackBar(
          context,
          'تم إرسال رسالتك إلى إدارة التطبيق بنجاح! سيتم التواصل معك عند الحاجة 🕊️',
        );
      } else if (complaintProvider.errorMessage != null) {
        CustomDialog.showErrorSnackBar(context, complaintProvider.errorMessage!);
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

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                      child: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الشكاوى والمقترحات 📩',
                      style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'نحن نهتم بصوتك ورأيك لتطوير الخدمة بأعلى جودة',
                      style: AppFonts.cairoFont(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),

              if (_checkingCount) ...[
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
              ] else ...[
                // Rate Limit Notice Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLimitReached ? AppColors.danger.withAlpha(20) : AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isLimitReached
                              ? 'وصلت للحد الأقصى مسموح به اليوم (2/2) 🛑'
                              : 'استهلكت ($_todayCount من 2) محاولة إرسال مسموحة اليوم',
                          style: AppFonts.cairoFont(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isLimitReached ? AppColors.danger : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Type Selector Chips
                Text(
                  'نوع الرسالة:',
                  style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildTypeChip('شكوى ⚠️', 'شكوى'),
                    const SizedBox(width: 8),
                    _buildTypeChip('مقترح 💡', 'مقترح'),
                    const SizedBox(width: 8),
                    _buildTypeChip('استفسار ❓', 'استفسار'),
                  ],
                ),
                const SizedBox(height: 16),

                // Message Text Field
                Text(
                  'تفاصيل ومضمون الرسالة:',
                  style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  enabled: !isLimitReached,
                  style: AppFonts.cairoFont(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: isLimitReached
                        ? 'عفواً، لا يمكنك كتابة رسالة إضافية اليوم...'
                        : 'اكتب تفاصيل ملاحظتك أو الشكوى بالتفصيل ليتمكن الفريق من مساعدتك...',
                    hintStyle: AppFonts.cairoFont(fontSize: 11, color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? AppColors.darkBackground : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit & Cancel Action Buttons
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
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'إلغاء',
                      style: AppFonts.cairoFont(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
            ),
          ),
          child: Text(
            label,
            style: AppFonts.cairoFont(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }
}
