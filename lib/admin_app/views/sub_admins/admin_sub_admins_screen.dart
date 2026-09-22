import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/admin_permissions.dart';
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
  final Set<String> _visiblePasswordAdminIds = {};

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
    final currentAdmin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    final isEditing = adminToEdit != null;

    if (isEditing) {
      if (adminToEdit.isSuperAdmin && currentAdmin?.isSuperAdmin != true) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، لا يمكن لغير المدير العام الرئيسي تعديل حساب أو صلاحيات المدير العام 🔒');
        return;
      }
      if (currentAdmin != null && !currentAdmin.hasPermission(AdminPermissions.subAdminsEditPermissions)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية تعديل صلاحيات المدراء 🔒');
        return;
      }
    } else {
      if (currentAdmin != null && !currentAdmin.hasPermission(AdminPermissions.subAdminsAdd)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية إضافة مدراء فرعيين 🔒');
        return;
      }
    }

    final usernameController = TextEditingController(text: adminToEdit?.username ?? '');
    final passwordController = TextEditingController(text: adminToEdit?.password ?? '');
    final fullNameController = TextEditingController(text: adminToEdit?.fullName ?? '');

    // Default or existing permissions
    final Set<String> selectedPermissions = isEditing
        ? Set<String>.from(adminToEdit.effectivePermissions)
        : {
            AdminPermissions.productsView,
            AdminPermissions.productsToggleAvailability,
            AdminPermissions.ordersView,
            AdminPermissions.ordersViewDetails,
            AdminPermissions.ordersAcceptPrepare,
            AdminPermissions.ordersSendDelivery,
            AdminPermissions.ordersMarkCompleted,
          };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);

        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Modal Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'تعديل بيانات وصلاحيات المدير' : 'إضافة مدير فرعي جديد وتعيين الصلاحيات',
                          style: AppFonts.cairoFont(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Content Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Account Details Section
                          Text(
                            'بيانات حساب الدخول:',
                            style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: fullNameController,
                            labelText: 'الاسم الكامل للمدير',
                            hintText: 'مثال: محمد علي (مشرف الشيفت الصباحي)',
                            prefixIcon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: usernameController,
                            labelText: 'اسم المستخدم للدخول',
                            hintText: 'مثال: mohammed_shift1',
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: passwordController,
                            labelText: 'كلمة المرور',
                            hintText: 'ادخل كلمة المرور',
                            prefixIcon: Icons.lock_outline,
                          ),
                          const SizedBox(height: 24),

                          // 2. Permissions Section Header & Quick Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الصلاحيات المفصلة الممنوحة:',
                                      style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'محدد (${selectedPermissions.length} من ${AdminPermissions.allPermissionsCount} صلاحية)',
                                      style: AppFonts.cairoFont(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setStateModal(() {
                                        for (final g in AdminPermissions.allGroups) {
                                          for (final item in g.items) {
                                            selectedPermissions.add(item.key);
                                          }
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.select_all, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'تحديد الكل ✨',
                                            style: AppFonts.cairoFont(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      setStateModal(() {
                                        selectedPermissions.clear();
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.deselect, size: 14, color: AppColors.danger),
                                          const SizedBox(width: 4),
                                          Text(
                                            'تفريغ 🧹',
                                            style: AppFonts.cairoFont(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 3. The 10 Categorized Accordion Permission Cards
                          ...AdminPermissions.allGroups.map((group) {
                            final groupSelectedCount = group.items
                                .where((item) => selectedPermissions.contains(item.key))
                                .length;
                            final isAllGroupSelected = groupSelectedCount == group.items.length;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: groupSelectedCount > 0
                                      ? group.color.withAlpha(120)
                                      : Colors.grey.shade300,
                                  width: groupSelectedCount > 0 ? 1.5 : 0.8,
                                ),
                              ),
                              elevation: groupSelectedCount > 0 ? 2 : 0,
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: group.color.withAlpha(25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(group.icon, color: group.color, size: 20),
                                  ),
                                  title: Text(
                                    group.title,
                                    style: AppFonts.cairoFont(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'محدد ($groupSelectedCount من ${group.items.length})',
                                    style: AppFonts.cairoFont(
                                      fontSize: 11,
                                      color: groupSelectedCount > 0 ? group.color : Colors.grey,
                                      fontWeight: groupSelectedCount > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setStateModal(() {
                                            if (isAllGroupSelected) {
                                              for (final item in group.items) {
                                                selectedPermissions.remove(item.key);
                                              }
                                            } else {
                                              for (final item in group.items) {
                                                selectedPermissions.add(item.key);
                                              }
                                            }
                                          });
                                        },
                                        child: Text(
                                          isAllGroupSelected ? 'إلغاء القسم' : 'تحديد القسم',
                                          style: AppFonts.cairoFont(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isAllGroupSelected ? AppColors.danger : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.expand_more),
                                    ],
                                  ),
                                  children: group.items.map((item) {
                                    final isItemChecked = selectedPermissions.contains(item.key);

                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
                                          ),
                                        ),
                                      ),
                                      child: SwitchListTile(
                                        dense: true,
                                        activeColor: group.color,
                                        secondary: Icon(
                                          item.icon,
                                          size: 18,
                                          color: isItemChecked ? group.color : Colors.grey,
                                        ),
                                        title: Text(
                                          item.title,
                                          style: AppFonts.cairoFont(
                                            fontSize: 12,
                                            fontWeight: isItemChecked ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: Text(
                                          item.description,
                                          style: AppFonts.cairoFont(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        value: isItemChecked,
                                        onChanged: (val) {
                                          setStateModal(() {
                                            if (val) {
                                              selectedPermissions.add(item.key);
                                            } else {
                                              selectedPermissions.remove(item.key);
                                            }
                                          });
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Save Action Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceLight : Colors.grey.shade50,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: Text(
                          isEditing
                              ? 'حفظ الصلاحيات والتعديلات'
                              : 'إضافة المدير وتخصيص (${selectedPermissions.length}) صلاحية',
                          style: AppFonts.cairoFont(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () async {
                          final username = usernameController.text.trim();
                          final password = passwordController.text.trim();
                          final fullName = fullNameController.text.trim();

                          if (username.isEmpty || password.isEmpty || fullName.isEmpty) {
                            CustomDialog.showErrorSnackBar(context, 'يرجى إكمال جميع البيانات المطلوبة');
                            return;
                          }

                          final permList = selectedPermissions.toList();

                          bool ok = false;
                          if (isEditing) {
                            ok = await authProvider.editSubAdmin(
                              id: adminToEdit.id,
                              username: username,
                              password: password,
                              fullName: fullName,
                              permissions: permList,
                            );
                          } else {
                            ok = await authProvider.addSubAdmin(
                              username: username,
                              password: password,
                              fullName: fullName,
                              permissions: permList,
                            );
                          }

                          if (!ctx.mounted) return;

                          if (ok) {
                            Navigator.of(ctx).pop();
                            CustomDialog.showSuccessSnackBar(
                              ctx,
                              isEditing ? 'تم تعديل بيانات وصلاحيات المدير بنجاح' : 'تم إضافة المدير الفرعي بنجاح',
                            );
                          } else if (authProvider.errorMessage != null) {
                            CustomDialog.showErrorSnackBar(ctx, authProvider.errorMessage!);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(AdminModel admin) async {
    final currentAdmin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (currentAdmin != null && !currentAdmin.hasPermission(AdminPermissions.subAdminsDelete)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية حذف وسحب حسابات المدراء 🔒');
      return;
    }

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
    final currentAdmin = Provider.of<AdminAuthProvider>(context).currentAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة المدراء والصلاحيات الدقيقة',
          style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        elevation: 1,
      ),
      floatingActionButton: (currentAdmin != null && currentAdmin.hasPermission(AdminPermissions.subAdminsAdd))
          ? FloatingActionButton.extended(
              heroTag: 'fab_admin_sub_admins',
              backgroundColor: AppColors.primary,
              onPressed: () => _showAddOrEditAdminDialog(),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                'إضافة مدير فرعي',
                style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Consumer<AdminAuthProvider>(
        builder: (context, authProvider, _) {
          final loggedInAdmin = authProvider.currentAdmin;
          final visibleAdmins = authProvider.subAdmins.where((admin) {
            // Hide Super Admin accounts completely if the logged-in user is NOT a Super Admin
            if (loggedInAdmin == null || !loggedInAdmin.isSuperAdmin) {
              if (admin.isSuperAdmin) return false;
            }
            return true;
          }).toList();

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
                    : visibleAdmins.isEmpty
                        ? Center(
                            child: Text(
                              authProvider.searchQuery.isNotEmpty ? 'لا توجد نتائج مطابقة' : 'لا يوجد مدراء فرعيون مضافون حالياً',
                              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: visibleAdmins.length,
                            itemBuilder: (ctx, index) {
                              final admin = visibleAdmins[index];
                              final permCount = admin.effectivePermissions.length;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: admin.isSuperAdmin ? AppColors.accent : AppColors.primary.withAlpha(20),
                                            child: Icon(
                                              admin.isSuperAdmin ? Icons.stars : Icons.admin_panel_settings,
                                              color: admin.isSuperAdmin ? Colors.black : AppColors.primary,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        admin.fullName,
                                                        style: AppFonts.cairoFont(fontSize: 15, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: admin.isSuperAdmin
                                                            ? Colors.amber.shade100
                                                            : AppColors.primary.withAlpha(20),
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(
                                                          color: admin.isSuperAdmin
                                                              ? Colors.amber.shade300
                                                              : AppColors.primary.withAlpha(60),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        admin.isSuperAdmin
                                                            ? 'مدير عام 👑'
                                                            : '$permCount / 42 صلاحية 🔑',
                                                        style: AppFonts.cairoFont(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: admin.isSuperAdmin
                                                              ? Colors.amber.shade900
                                                              : AppColors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'اسم المستخدم: ${admin.username}  |  كلمة المرور: ${_visiblePasswordAdminIds.contains(admin.id) ? admin.password : '••••••••'}',
                                                        style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          if (_visiblePasswordAdminIds.contains(admin.id)) {
                                                            _visiblePasswordAdminIds.remove(admin.id);
                                                          } else {
                                                            _visiblePasswordAdminIds.add(admin.id);
                                                          }
                                                        });
                                                      },
                                                      borderRadius: BorderRadius.circular(20),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              _visiblePasswordAdminIds.contains(admin.id)
                                                                  ? Icons.visibility_off_outlined
                                                                  : Icons.visibility_outlined,
                                                              size: 16,
                                                              color: AppColors.primary,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              _visiblePasswordAdminIds.contains(admin.id) ? 'إخفاء' : 'كشف 👁️',
                                                              style: AppFonts.cairoFont(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(Icons.tune_outlined, color: AppColors.info, size: 18),
                                            label: Text('تعديل الصلاحيات', style: AppFonts.cairoFont(color: AppColors.info)),
                                            onPressed: () => _showAddOrEditAdminDialog(admin),
                                          ),
                                          if (!admin.isSuperAdmin) ...[
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                              label: Text('حذف الحساب', style: AppFonts.cairoFont(color: AppColors.danger)),
                                              onPressed: () => _confirmDelete(admin),
                                            ),
                                          ],
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
