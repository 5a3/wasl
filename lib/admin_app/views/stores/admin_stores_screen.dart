import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/shimmer_loading_list.dart';
import '../../../shared/models/store_model.dart';
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditStoreScreen()),
    );
  }

  void _openEditStore(StoreModel store) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditStoreScreen(storeToEdit: store)),
    );
  }

  void _confirmDelete(StoreModel store) async {
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                              ? CustomCachedImage(imageUrl: store.logoUrl!, width: 50, height: 50)
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: AppColors.primary.withAlpha(25),
                                  child: const Icon(Icons.store, color: AppColors.primary),
                                ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                store.name,
                                style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: store.isOpen ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                store.isOpen ? 'مفتوح' : 'مغلق',
                                style: AppFonts.cairoFont(
                                  fontSize: 12,
                                  color: store.isOpen ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (store.phone != null && store.phone!.isNotEmpty)
                              Text('هاتف: ${store.phone!}', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700)),
                            if (store.address != null && store.address!.isNotEmpty)
                              Text('العنوان: ${store.address!}', style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700)),
                            if (store.description != null && store.description!.isNotEmpty)
                              Text(
                                store.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () => _openEditStore(store),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.danger),
                              onPressed: () => _confirmDelete(store),
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
