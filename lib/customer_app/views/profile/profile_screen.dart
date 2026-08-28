import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
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

/// Institutional & Formal Customer Profile Screen
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

    final customerName =
        customer?.fullName.isNotEmpty == true ? customer!.fullName : 'عميل وصل لي';
    final customerInitial =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : 'ع';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: isStandalone
          ? AppBar(
              title: Text(
                'الملف الشخصي والحساب',
                style: AppFonts.cairoFont(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  height: 1,
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // Official Account Header Card (بطاقة الحساب المعتمد)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Profile Avatar Initial Container
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        customerInitial,
                        style: AppFonts.cairoFont(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name & Account Status Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: AppFonts.cairoFont(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${customer?.username ?? "user"}',
                          style: AppFonts.cairoFont(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Account Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: customer?.isBlocked == true
                                ? AppColors.danger.withValues(alpha: 0.12)
                                : Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: customer?.isBlocked == true
                                  ? AppColors.danger.withValues(alpha: 0.3)
                                  : Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                customer?.isBlocked == true
                                    ? Icons.error_outline_rounded
                                    : Icons.verified_user_rounded,
                                size: 12,
                                color: customer?.isBlocked == true
                                    ? AppColors.danger
                                    : Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer?.isBlocked == true
                                    ? 'حساب محظور'
                                    : 'حساب معتمد ونشط',
                                style: AppFonts.cairoFont(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: customer?.isBlocked == true
                                      ? AppColors.danger
                                      : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Copy Account ID Button
                  IconButton(
                    icon: Icon(
                      Icons.content_copy_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    tooltip: 'نسخ معرف الحساب',
                    onPressed: () {
                      if (customer?.id != null) {
                        Clipboard.setData(ClipboardData(text: customer!.id));
                        CustomDialog.showSuccessSnackBar(
                          context,
                          'تم نسخ معرف الحساب بنجاح ✅',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Basic Account Information
            _buildSectionLabel(context, 'بيانات الحساب الأساسية', isDark),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildCorporateInfoTile(
                    context,
                    title: 'الاسم الكامل',
                    value: customerName,
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildCorporateInfoTile(
                    context,
                    title: 'اسم المستخدم',
                    value: customer?.username.isNotEmpty == true
                        ? '@${customer!.username}'
                        : 'غير مدخل',
                    icon: Icons.alternate_email_rounded,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildCorporateInfoTile(
                    context,
                    title: 'رقم الهاتف المسجل',
                    value: customer?.phone.isNotEmpty == true
                        ? customer!.phone
                        : 'غير مدخل',
                    icon: Icons.phone_android_rounded,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildCorporateInfoTile(
                    context,
                    title: 'البريد الإلكتروني',
                    value: customer?.email.isNotEmpty == true
                        ? customer!.email
                        : 'غير مدخل',
                    icon: Icons.email_outlined,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildCorporateInfoTile(
                    context,
                    title: 'تاريخ إنشاء الحساب',
                    value: customer != null
                        ? Formatters.formatDateTime(customer.createdAt)
                        : 'غير متوفر',
                    icon: Icons.calendar_today_rounded,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Delivery Location & Address (Editable)
            _buildSectionLabel(context, 'عنوان التوصيل المعتمد', isDark),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'العنوان الحالي المسجل',
                  style: AppFonts.cairoFont(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: Text(
                  customer?.address.isNotEmpty == true
                      ? customer!.address
                      : 'لم يتم إدخال العنوان السكني بعد',
                  style: AppFonts.cairoFont(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                trailing: InkWell(
                  onTap: () => _openEditAddressDialog(
                    context,
                    customer?.address ?? '',
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'تعديل',
                          style: AppFonts.cairoFont(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Security & Preferences
            _buildSectionLabel(context, 'الأمان وإعدادات المظهر', isDark),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  // Change Password Tile
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'الرمز السري / كلمة المرور',
                      style: AppFonts.cairoFont(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '••••••••',
                      style: AppFonts.cairoFont(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: InkWell(
                      onTap: () => _openEditPasswordDialog(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'تغيير',
                              style: AppFonts.cairoFont(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildDivider(isDark),

                  // Dark Mode Switch Tile
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'الوضع الداكن (Dark Mode)',
                      style: AppFonts.cairoFont(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (val) => themeProvider.toggleTheme(val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout Action Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger, width: 1.2),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(
                'تسجيل الخروج من الحساب',
                style: AppFonts.cairoFont(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final confirm = await CustomDialog.showConfirmDialog(
                  context: context,
                  title: 'تسجيل الخروج 🚪',
                  message: 'هل أنت تأكد من أنك تريد تسجيل الخروج من تطبيق وصل لي؟',
                  confirmText: 'تسجيل الخروج',
                  cancelText: 'إلغاء',
                  confirmColor: AppColors.danger,
                );
                if (confirm == true) {
                  await authProvider.logout();
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const CustomerLoginScreen(),
                    ),
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

  Widget _buildSectionLabel(BuildContext context, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: AppFonts.cairoFont(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }

  Widget _buildCorporateInfoTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: AppFonts.cairoFont(
          fontSize: 12,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
      subtitle: Text(
        value,
        style: AppFonts.cairoFont(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
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
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
