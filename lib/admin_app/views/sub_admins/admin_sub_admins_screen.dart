import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../providers/admin_auth_provider.dart';

class AdminSubAdminsScreen extends StatefulWidget {
  const AdminSubAdminsScreen({super.key});

  @override
  State<AdminSubAdminsScreen> createState() => _AdminSubAdminsScreenState();
}

class _AdminSubAdminsScreenState extends State<AdminSubAdminsScreen> {
  void _showAddSubAdminDialog() {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    bool canManageOrders = true;
    bool canManageProducts = false;
    bool canViewReports = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'إضافة مدير فرعي جديد',
                textAlign: TextAlign.center,
                style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: nameController,
                      labelText: 'الاسم الكامل',
                      hintText: 'مثال: أحمد علي (مشرف الطلبات)',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: usernameController,
                      labelText: 'اسم المستخدم',
                      hintText: 'اسم منحصر لتسجيل الدخول',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: passwordController,
                      labelText: 'كلمة المرور',
                      hintText: 'ادخل كلمة المرور عادي بدون تشفير',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'صلاحيات المدير الفرعي:',
                      style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: const Text('إدارة ومتابعة الطلبات'),
                      value: canManageOrders,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setStateDialog(() => canManageOrders = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('إضافة وإدارة المنتجات'),
                      value: canManageProducts,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setStateDialog(() => canManageProducts = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('مشاهدة التقارير والإحصائيات'),
                      value: canViewReports,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setStateDialog(() => canViewReports = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        usernameController.text.trim().isEmpty ||
                        passwordController.text.isEmpty) {
                      CustomDialog.showErrorSnackBar(context, 'يرجى إدخال كافة البيانات');
                      return;
                    }

                    final perms = <String>[];
                    if (canManageOrders) perms.add('manage_orders');
                    if (canManageProducts) perms.add('manage_products');
                    if (canViewReports) perms.add('view_reports');

                    final ok = await authProvider.addSubAdmin(
                      username: usernameController.text,
                      password: passwordController.text,
                      fullName: nameController.text,
                      permissions: perms,
                    );

                    if (ok && ctx.mounted) {
                      Navigator.of(ctx).pop();
                      CustomDialog.showSuccessSnackBar(context, 'تم إضافة المدير الفرعي بنجاح');
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAdmin = Provider.of<AdminAuthProvider>(context).currentAdmin;

    return Scaffold(
      floatingActionButton: currentAdmin?.isSuperAdmin == true
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: _showAddSubAdminDialog,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                'إضافة مدير فرعي',
                style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.primary.withAlpha(15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: AppColors.primary, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'حسابك الحالي: ${currentAdmin?.fullName ?? "مدير"}',
                            style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'الدور: ${currentAdmin?.isSuperAdmin == true ? "مدير عام النظام (Super Admin)" : "مدير فرعي (Sub Admin)"}',
                            style: AppFonts.cairoFont(fontSize: 13, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'إدارة المدراء والفرعيين وصلاحياتهم',
              style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'المدير العام لديه كافة الصلاحيات، بينما يمكنك منح المدراء الفرعيين صلاحيات محددة فقط لمنع العبث بالبيانات.',
              style: AppFonts.cairoFont(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
