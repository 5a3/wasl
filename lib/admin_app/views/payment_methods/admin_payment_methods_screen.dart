import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/admin_permissions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../shared/models/payment_method_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/payment_method_provider.dart';
import '../../providers/vendor_store_provider.dart';

class AdminPaymentMethodsScreen extends StatefulWidget {
  const AdminPaymentMethodsScreen({super.key});

  @override
  State<AdminPaymentMethodsScreen> createState() =>
      _AdminPaymentMethodsScreenState();
}

class _AdminPaymentMethodsScreenState extends State<AdminPaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<PaymentMethodProvider>(context, listen: false).fetchPaymentMethods();
        Provider.of<VendorStoreProvider>(context, listen: false).fetchStores();
      }
    });
  }

  void _showAddEditDialog([PaymentMethodModel? method]) {
    final isEditing = method != null;
    final nameController = TextEditingController(text: method?.name ?? '');
    final descController =
        TextEditingController(text: method?.description ?? '');
    final accountController =
        TextEditingController(text: method?.accountNumber ?? '');
    bool isActive = method?.isActive ?? true;
    bool isGlobal = method?.isGlobal ?? true;
    String? selectedStoreId = method?.storeId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit_note : Icons.add_card,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'تعديل طريقة الدفع' : 'إضافة طريقة دفع جديدة',
                  style: AppFonts.cairoFont(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم طريقة الدفع *',
                      hintText: 'مثال: حساب الكريمي / الدفع نقداً',
                      prefixIcon: Icon(Icons.payment),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(
                      'طريقة دفع عامة لجميع المطاعم',
                      style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isGlobal ? 'متاحة لجميع المطاعم (مثل الدفع نقداً عند الاستلام)' : 'خاصة بمطعم محدد',
                      style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey),
                    ),
                    value: isGlobal,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        isGlobal = val;
                      });
                    },
                  ),
                  if (!isGlobal) ...[
                    const SizedBox(height: 10),
                    Consumer<VendorStoreProvider>(
                      builder: (context, storeProv, _) {
                        final stores = storeProv.stores;
                        return DropdownButtonFormField<String?>(
                          value: stores.any((s) => s.id == selectedStoreId) ? selectedStoreId : null,
                          decoration: InputDecoration(
                            labelText: 'اختيار المطعم المربوطة به طريقة الدفع',
                            prefixIcon: const Icon(Icons.storefront),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: stores.map((s) => DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(s.name),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedStoreId = val;
                            });
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: accountController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الحساب / المحفظة (إن وجد)',
                      hintText: 'مثال: 12345678 أو 770000000',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'الوصف أو التعليمات للعميل',
                      hintText: 'مثال: الدفع نقداً فور وصول المندوب وتسليم الطلب',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(
                      'تفعيل طريقة الدفع للعملاء',
                      style: AppFonts.cairoFont(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: isActive,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => isActive = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'إلغاء',
                  style: AppFonts.cairoFont(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    CustomDialog.showErrorSnackBar(ctx, 'يرجى إدخال اسم طريقة الدفع');
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(ctx).pop();
                  final provider = Provider.of<PaymentMethodProvider>(
                    context,
                    listen: false,
                  );

                  bool ok = false;
                  if (isEditing) {
                    ok = await provider.editPaymentMethod(
                      id: method.id,
                      name: name,
                      description: descController.text.trim(),
                      accountNumber: accountController.text.trim(),
                      isActive: isActive,
                      storeId: isGlobal ? null : selectedStoreId,
                      isGlobal: isGlobal,
                    );
                  } else {
                    ok = await provider.addPaymentMethod(
                      name: name,
                      description: descController.text.trim(),
                      accountNumber: accountController.text.trim(),
                      isActive: isActive,
                      storeId: isGlobal ? null : selectedStoreId,
                      isGlobal: isGlobal,
                    );
                  }

                  if (ok) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'تم تعديل طريقة الدفع بنجاح'
                              : 'تم إضافة طريقة الدفع بنجاح',
                          style: AppFonts.cairoFont(),
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: Text(
                  isEditing ? 'حفظ التعديلات' : 'إضافة',
                  style: AppFonts.cairoFont(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<PaymentMethodProvider>(context);
    final admin = Provider.of<AdminAuthProvider>(context).currentAdmin;

    final canAdd = admin != null && admin.hasPermission(AdminPermissions.paymentMethodsAdd);
    final canEdit = admin != null && admin.hasPermission(AdminPermissions.paymentMethodsEdit);
    final canDelete = admin != null && admin.hasPermission(AdminPermissions.paymentMethodsDelete);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة طرق ووسائط الدفع 💳',
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'إضافة طريقة دفع',
                style: AppFonts.cairoFont(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.paymentMethods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد طرق دفع مضافة حالياً',
                        style: AppFonts.cairoFont(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: provider.paymentMethods.length,
                  itemBuilder: (ctx, index) {
                    final method = provider.paymentMethods[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 20 : 6),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: method.isActive
                              ? AppColors.primary.withAlpha(20)
                              : Colors.grey.withAlpha(30),
                          child: Icon(
                            method.accountNumber.isNotEmpty
                                ? Icons.account_balance_wallet
                                : Icons.payments,
                            color: method.isActive
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                method.name,
                                style: AppFonts.cairoFont(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: method.isActive
                                    ? Colors.green.withAlpha(30)
                                    : Colors.red.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                method.isActive ? 'مفعلة 🟢' : 'معطلة 🔴',
                                style: AppFonts.cairoFont(
                                  fontSize: 11,
                                  color: method.isActive
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (method.accountNumber.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'رقم الحساب / المحفظة: ${method.accountNumber}',
                                style: AppFonts.cairoFont(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                            if (method.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                method.description,
                                style: AppFonts.cairoFont(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canEdit)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showAddEditDialog(method),
                              ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('حذف طريقة الدفع'),
                                      content: Text('هل أنت تأكد من حذف "${method.name}"؟'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('إلغاء'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final ok = await provider.deletePaymentMethod(method.id);
                                    if (ok) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('تم حذف طريقة الدفع بنجاح', style: AppFonts.cairoFont()),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
