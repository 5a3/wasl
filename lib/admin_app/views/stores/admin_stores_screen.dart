import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/admin_permissions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/shimmer_loading_list.dart';
import '../../../shared/models/store_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/vendor_store_provider.dart';
import 'add_edit_store_screen.dart';

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VendorStoreProvider>(context, listen: false).listenToStores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddStore() {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.storesAdd)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية إضافة مطاعم/محلات جديدة 🔒');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditStoreScreen()),
    );
  }

  void _openEditStore(StoreModel store) {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.storesEdit)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية تعديل المحلات 🔒');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditStoreScreen(storeToEdit: store)),
    );
  }

  void _confirmDelete(StoreModel store) async {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.storesDelete)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية حذف المحلات 🔒');
      return;
    }

    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'حذف المطعم',
      message: 'هل أنت تأكد من حذف مطعم "${store.name}"؟',
      confirmColor: AppColors.danger,
    );

    if (confirm == true && mounted) {
      final ok = await Provider.of<VendorStoreProvider>(context, listen: false).deleteStore(store.id);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم حذف المطعم بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المطاعم والمتاجر', style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_admin_stores',
        backgroundColor: AppColors.primary,
        onPressed: _openAddStore,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة مطعم جديد',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'البحث عن مطعم...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<VendorStoreProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.stores.isEmpty) {
                  return const ShimmerLoadingList();
                }

                final query = _searchController.text.trim().toLowerCase();
                final filtered = provider.stores.where((s) {
                  final descMatch = s.description != null && s.description!.toLowerCase().contains(query);
                  return s.name.toLowerCase().contains(query) || descMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storefront, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          query.isNotEmpty ? 'لا توجد نتائج تطابق بحثك' : 'لا يوجد مطاعم مضافة حالياً',
                          style: AppFonts.cairoFont(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final store = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                                      ? CustomCachedImage(imageUrl: store.logoUrl!, width: 55, height: 55)
                                      : Container(
                                          width: 55,
                                          height: 55,
                                          color: AppColors.primary.withAlpha(25),
                                          child: const Icon(Icons.store, color: AppColors.primary, size: 28),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        store.name,
                                        style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (store.storeCategoryName != null && store.storeCategoryName!.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withAlpha(20),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'القسم: ${store.storeCategoryName!}',
                                                style: AppFonts.cairoFont(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          if (store.cityName != null && store.cityName!.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withAlpha(20),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'المدينة: ${store.cityName!}',
                                                style: AppFonts.cairoFont(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (store.phone != null && store.phone!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('هاتف: ${store.phone!}', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700)),
                            ],
                            if (store.address != null && store.address!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('العنوان: ${store.address!}', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700)),
                            ],
                            if (store.description != null && store.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                store.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                            const Divider(height: 16),
                            // Action Row (Switch status & edit/delete)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      store.isOpen ? 'المحل مفتوح 🟢' : 'المحل مغلق 🔴',
                                      style: AppFonts.cairoFont(
                                        fontSize: 12.5,
                                        color: store.isOpen ? Colors.green.shade700 : AppColors.danger,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                      Switch.adaptive(
                                        value: store.isOpen,
                                        activeColor: Colors.green,
                                        inactiveThumbColor: Colors.red.shade400,
                                        inactiveTrackColor: Colors.red.shade100,
                                        onChanged: (val) async {
                                          final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
                                          if (admin != null && !admin.hasPermission(AdminPermissions.storesToggleStatus)) {
                                            CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية تغيير حالة المحل 🔒');
                                            return;
                                          }
                                          final ok = await provider.toggleStoreStatus(store.id, val);
                                          if (ok && context.mounted) {
                                            CustomDialog.showSuccessSnackBar(
                                              context,
                                              val ? 'تم فتح مطعم "${store.name}" 🟢' : 'تم إغلاق مطعم "${store.name}" 🔴',
                                            );
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.primary),
                                      onPressed: () => _openEditStore(store),
                                      tooltip: 'تعديل المحل',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.danger),
                                      onPressed: () => _confirmDelete(store),
                                      tooltip: 'حذف المحل',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
