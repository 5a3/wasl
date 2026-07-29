import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../providers/customer_auth_provider.dart';
import '../auth/customer_login_screen.dart';

/// Customer Profile Screen (Only Address and Password are Editable with Pencil Icons)
class ProfileScreen extends StatelessWidget {
  final bool isStandalone;
  const ProfileScreen({super.key, this.isStandalone = false});

  /// Open Address Edit Bottom Sheet
  void _openEditAddressDialog(BuildContext context, String currentAddress) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditAddressBottomSheet(currentAddress: currentAddress),
    );
  }

  /// Open Password Edit Bottom Sheet (Requires Old Password)
  void _openEditPasswordDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _EditPasswordBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomerAuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final customer = authProvider.currentCustomer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: isStandalone
          ? AppBar(
              title: Text(
                'الملف الشخصي والحساب',
                style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              elevation: 0.5,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // Customer Avatar & Header Name
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.primary.withAlpha(30),
                    child: Text(
                      customer?.fullName.isNotEmpty == true ? customer!.fullName[0].toUpperCase() : 'ع',
                      style: AppFonts.cairoFont(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              customer?.fullName.isNotEmpty == true ? customer!.fullName : 'عميل وصل لي',
              style: AppFonts.cairoFont(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '@${customer?.username ?? "user"}',
              style: AppFonts.cairoFont(fontSize: 13, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            // Comprehensive Account Information Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 15 : 5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. Account ID (Read Only + Copy)
                  ListTile(
                    leading: const Icon(Icons.fingerprint, color: AppColors.primary),
                    title: Text('رقم الحساب / المعرف', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600)),
                    subtitle: Text(
                      customer?.id ?? 'غير متوفر',
                      style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                      tooltip: 'نسخ رقم الحساب',
                      onPressed: () {
                        if (customer?.id != null) {
                          Clipboard.setData(ClipboardData(text: customer!.id));
                          CustomDialog.showSuccessSnackBar(context, 'تم نسخ رقم الحساب بنجاح');
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),

                  // 2. Account Status (Read Only)
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined, color: Colors.green),
                    title: Text('حالة الحساب', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600)),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade700.withAlpha(60)),
                          ),
                          child: Text(
                            customer?.isBlocked == true ? 'محظور 🔴' : 'نشط ومعتمد 🟢',
                            style: AppFonts.cairoFont(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // 3. Full Name (Read Only)
                  ListTile(
                    leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
                    title: Text('الاسم الكامل', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600)),
                    subtitle: Text(
                      customer?.fullName.isNotEmpty == true ? customer!.fullName : 'غير مدخل',
                      style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),

                  // 4. Registered Address (EDITABLE via Pencil Icon ✏️)
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    title: Text('العنوان المسجل', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600)),
                    subtitle: Text(
                      customer?.address.isNotEmpty == true ? customer!.address : 'غير مدخل',
                      style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      ),
                      tooltip: 'تعديل العنوان',
                      onPressed: () => _openEditAddressDialog(context, customer?.address ?? ''),
                    ),
                  ),
                  const Divider(height: 1),

                  // 5. Password / Pin Code (EDITABLE via Pencil Icon ✏️ + requires Old Password)
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                    title: Text('الرمز السري / كلمة المرور', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600)),
                    subtitle: Text(
                      '••••••••',
                      style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      ),
                      tooltip: 'تغيير الرمز السري',
                      onPressed: () => _openEditPasswordDialog(context),
                    ),
                  ),
                  const Divider(height: 1),

                  // 6. Phone Number (Read Only)
                  ListTile(
                    leading: const Icon(Icons.phone_android_outlined, color: AppColors.primary),
                    title: Text('رقم الهاتف', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600)),
                    subtitle: Text(
                      customer?.phone.isNotEmpty == true ? customer!.phone : 'غير مدخل',
                      style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),

                  // 7. Username (Read Only)
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
                    title: Text('اسم المستخدم', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600)),
                    subtitle: Text(
                      customer?.username.isNotEmpty == true ? '@${customer!.username}' : 'غير مدخل',
                      style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),

                  // 8. Email Address (Read Only)
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                    title: Text('البريد الإلكتروني', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600)),
                    subtitle: Text(
                      customer?.email.isNotEmpty == true ? customer!.email : 'غير مدخل',
                      style: AppFonts.cairoFont(fontSize: 13),
                    ),
                  ),
                  const Divider(height: 1),

                  // 9. Join Date (Read Only)
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                    title: Text('تاريخ الانضمام', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600)),
                    subtitle: Text(
                      customer != null ? Formatters.formatDateTime(customer.createdAt) : 'غير متوفر',
                      style: AppFonts.cairoFont(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Settings & Preferences Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
              ),
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                title: Text('الوضع الليلي (Dark Mode)', style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.w600)),
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                'تسجيل الخروج من الحساب',
                style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet to edit Address only
class _EditAddressBottomSheet extends StatefulWidget {
  final String currentAddress;
  const _EditAddressBottomSheet({required this.currentAddress});

  @override
  State<_EditAddressBottomSheet> createState() => _EditAddressBottomSheetState();
}

class _EditAddressBottomSheetState extends State<_EditAddressBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.currentAddress);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final authProvider = Provider.of<CustomerAuthProvider>(context, listen: false);
    final success = await authProvider.updateCustomerAddress(_addressController.text);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      CustomDialog.showSuccessSnackBar(context, 'تم تحديث العنوان السكني بنجاح ✅');
    } else if (authProvider.errorMessage != null) {
      CustomDialog.showErrorSnackBar(context, authProvider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.edit_location_alt_outlined, color: AppColors.primary, size: 26),
                const SizedBox(width: 10),
                Text(
                  'تعديل العنوان السكني',
                  style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _addressController,
              labelText: 'العنوان السكني الجديد *',
              hintText: 'مثال: حريضه- الحاوي',
              prefixIcon: Icons.location_on_outlined,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'يرجى إدخال العنوان السكني';
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'حفظ العنوان الجديد 💾',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveAddress,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet to change Password (requires Old Password)
class _EditPasswordBottomSheet extends StatefulWidget {
  const _EditPasswordBottomSheet();

  @override
  State<_EditPasswordBottomSheet> createState() => _EditPasswordBottomSheetState();
}

class _EditPasswordBottomSheetState extends State<_EditPasswordBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _localError;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    setState(() => _localError = null);

    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      final msg = 'الرمز السري الجديد غير متطابق مع التأكيد';
      setState(() => _localError = msg);
      CustomDialog.showErrorSnackBar(context, msg);
      return;
    }

    setState(() => _isSaving = true);
    final authProvider = Provider.of<CustomerAuthProvider>(context, listen: false);
    final success = await authProvider.updateCustomerPassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      CustomDialog.showSuccessSnackBar(context, 'تم تغيير الرمز السري بنجاح 🔑');
    } else {
      final errorMsg = authProvider.errorMessage ?? 'الرمز السري القديم غير صحيح';
      setState(() => _localError = errorMsg);
      CustomDialog.showErrorSnackBar(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.lock_reset, color: AppColors.primary, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'تغيير الرمز السري',
                    style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Local Red Error Card Banner inside modal
              if (_localError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _localError!,
                          style: AppFonts.cairoFont(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),

              // 1. Old Password Field (Mandatory)
              CustomTextField(
                controller: _oldPasswordController,
                labelText: 'الرمز السري القديم (الحالي) *',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureOld,
                suffixIcon: IconButton(
                  icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'يرجى إدخال الرمز السري القديم أولاً';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. New Password Field
              CustomTextField(
                controller: _newPasswordController,
                labelText: 'الرمز السري الجديد *',
                hintText: '6 أرقام/أحرف على الأقل',
                prefixIcon: Icons.lock_reset,
                obscureText: _obscureNew,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 14),

              // 3. Confirm New Password Field
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: 'تأكيد الرمز السري الجديد *',
                prefixIcon: Icons.check_circle_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'يرجى تأكيد الرمز السري الجديد';
                  return null;
                },
              ),

              const SizedBox(height: 24),
              CustomButton(
                text: 'حفظ الرمز السري الجديد 🔐',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _savePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
