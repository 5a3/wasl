import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/admin_model.dart';
import '../../providers/admin_auth_provider.dart';

class AdminSubAdminsScreen extends StatefulWidget {
  const AdminSubAdminsScreen({super.key});

  @override
  State<AdminSubAdminsScreen> createState() => _AdminSubAdminsScreenState();
}

class _AdminSubAdminsScreenState extends State<AdminSubAdminsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminAuthProvider>(context, listen: false).fetchSubAdmins();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrEditAdminDialog([AdminModel? adminToEdit]) {
    final isEditing = adminToEdit != null;
    final usernameController = TextEditingController(text: adminToEdit?.username ?? '');
    final passwordController = TextEditingController(text: adminToEdit?.password ?? '');
    final fullNameController = TextEditingController(text: adminToEdit?.fullName ?? '');

    final availablePermissions = [
      {'key': 'manage_products', 'label': 'إدارة المنتجات والقوائم'},
      {'key': 'manage_orders', 'label': 'إدارة الطلبات وتحديث حالتها'},
      {'key': 'view_reports', 'label': 'استعراض التقارير المالية'},
      {'key': 'manage_admins', 'label': 'إدارة وتعيين المدراء الفرعيين'},
    ];

    List<String> selectedPermissions = isEditing
        ? List<String>.from(adminToEdit.permissions)
        : ['manage_products', 'manage_orders'];

    showDialog(
      context: context,
      builder: (ctx) {
        final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'تعديل بيانات المدير' : 'إضافة مدير فرعي جديد',
                textAlign: TextAlign.center,
                style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: fullNameController,
                      labelText: 'الاسم الكامل للمدير',
                      hintText: 'مثال: محمد علي (مشرف الشيفت الصباحي)',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: usernameController,
                      labelText: 'اسم المستخدم للدخول',
                      hintText: 'مثال: mohammed',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: passwordController,
                      labelText: 'كلمة المرور',
                      hintText: '123456',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'الصلاحيات الممنوحة للمدير:',
                      style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ...availablePermissions.map((perm) {
                      final pKey = perm['key']!;
                      final pLabel = perm['label']!;
                      final isSelected = selectedPermissions.contains(pKey);

                      return CheckboxListTile(
                        dense: true,
                        title: Text(pLabel, style: AppFonts.cairoFont(fontSize: 12)),
                        value: isSelected,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setStateDialog(() {
                            if (val == true) {
                              selectedPermissions.add(pKey);
                            } else {
                              selectedPermissions.remove(pKey);
                            }
                          });
                        },
                      );
                    }),
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
                    final username = usernameController.text.trim();
                    final password = passwordController.text.trim();
                    final fullName = fullNameController.text.trim();

                    if (username.isEmpty || password.isEmpty || fullName.isEmpty) {
                      CustomDialog.showErrorSnackBar(context, 'يرجى إكمال جميع البيانات المطلوبة');
                      return;
                    }

                    bool ok = false;
                    if (isEditing) {
                      ok = await authProvider.editSubAdmin(
                        id: adminToEdit.id,
                        username: username,
                        password: password,
                        fullName: fullName,
                        permissions: selectedPermissions,
                      );
                    } else {
                      ok = await authProvider.addSubAdmin(
                        username: username,
                        password: password,
                        fullName: fullName,
                        permissions: selectedPermissions,
                      );
                    }

                    if (ok) {
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        CustomDialog.showSuccessSnackBar(
                          ctx,
                          isEditing ? 'تم تعديل بيانات المدير بنجاح' : 'تم إضافة المدير الفرعي بنجاح',
                        );
                      }
                    } else if (authProvider.errorMessage != null && ctx.mounted) {
                      CustomDialog.showErrorSnackBar(ctx, authProvider.errorMessage!);
                    }
                  },
                  child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة المدير'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(AdminModel admin) async {
    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'حذف حساب المدير',
      message: 'هل أنت تأكد من حذف حساب المدير "${admin.fullName}" (${admin.username})؟',
      confirmColor: AppColors.danger,
    );

    if (confirm == true && mounted) {
      final ok = await Provider.of<AdminAuthProvider>(context, listen: false).deleteSubAdmin(admin.id);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم حذف حساب المدير بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddOrEditAdminDialog(),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'إضافة مدير فرعي',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<AdminAuthProvider>(
        builder: (context, authProvider, _) {
          return Column(
            children: [
              // Search Bar Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    authProvider.setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم المدير أو اسم المستخدم...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: authProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              authProvider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: authProvider.isLoading
                    ? const LoadingIndicator(message: 'جاري جلب قائمة المدراء والمشرفين...')
                    : authProvider.subAdmins.isEmpty
                        ? Center(
                            child: Text(
                              authProvider.searchQuery.isNotEmpty ? 'لا توجد نتائج مطابقة' : 'لا يوجد مدراء فرعيون مضافون حالياً',
                              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: authProvider.subAdmins.length,
                            itemBuilder: (ctx, index) {
                              final admin = authProvider.subAdmins[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: admin.isSuperAdmin ? AppColors.accent : AppColors.primary.withAlpha(20),
                                        child: Icon(
                                          admin.isSuperAdmin ? Icons.star : Icons.person,
                                          color: admin.isSuperAdmin ? Colors.black : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              admin.fullName,
                                              style: AppFonts.cairoFont(fontSize: 15, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'اسم المستخدم: ${admin.username}  |  كلمة المرور: ${admin.password}',
                                              style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'الدور: ${admin.isSuperAdmin ? "مدير عام سوبر" : "مدير فرعي"}',
                                              style: AppFonts.cairoFont(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: admin.isSuperAdmin ? Colors.orange.shade800 : AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.info),
                                            onPressed: () => _showAddOrEditAdminDialog(admin),
                                          ),
                                          if (!admin.isSuperAdmin)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                              onPressed: () => _confirmDelete(admin),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
