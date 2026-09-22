import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/admin_permissions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../core/widgets/shimmer_loading_list.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/store_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/vendor_store_provider.dart';
import 'add_edit_category_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      Provider.of<VendorStoreProvider>(context, listen: false).fetchStores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCategory() {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.categoriesAdd)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية إضافة فئات جديدة 🔒');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditCategoryScreen()),
    );
  }

  void _openEditCategory(CategoryModel category) {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.categoriesEdit)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية تعديل الفئات 🔒');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditCategoryScreen(categoryToEdit: category)),
    );
  }

  void _confirmDelete(CategoryModel category) async {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.categoriesDelete)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية حذف الفئات 🔒');
      return;
    }

    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'حذف الفئة',
      message: 'هل أنت تأكد من حذف فئة "${category.name}"؟',
      confirmColor: AppColors.danger,
    );

    if (confirm == true && mounted) {
      final ok = await Provider.of<CategoryProvider>(context, listen: false).deleteCategory(category.id);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم حذف الفئة بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminAuthProvider>(context).currentAdmin;

    return Scaffold(
      floatingActionButton: (admin != null && admin.hasPermission(AdminPermissions.categoriesAdd))
          ? FloatingActionButton.extended(
              heroTag: 'fab_admin_categories',
              backgroundColor: AppColors.primary,
              onPressed: _openAddCategory,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'إضافة فئة جديدة',
                style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Consumer2<CategoryProvider, VendorStoreProvider>(
        builder: (context, catProvider, storeProvider, _) {
          final allCategories = catProvider.categories;
          final stores = storeProvider.stores;

          // Filter by search query and store selection
          final filteredCategories = allCategories.where((cat) {
            if (_selectedStoreId != null && _selectedStoreId!.isNotEmpty) {
              return cat.storeId == _selectedStoreId;
            }
            return true;
          }).toList();

          // Group categories by storeId
          final Map<String?, List<CategoryModel>> groupedCategories = {};
          for (var cat in filteredCategories) {
            final key = cat.storeId;
            groupedCategories.putIfAbsent(key, () => []).add(cat);
          }

          return Column(
            children: [
              // Search Bar & Store Filter Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        catProvider.setSearchQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم الفئة...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: catProvider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  catProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Store Selection Dropdown Filter
                    DropdownButtonFormField<String?>(
                      value: stores.any((s) => s.id == _selectedStoreId) ? _selectedStoreId : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'فرز الفئات بحسب المطعم',
                        labelStyle: AppFonts.cairoFont(fontSize: 13),
                        prefixIcon: const Icon(Icons.storefront, color: AppColors.primary, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'عرض جميع المطاعم (${allCategories.length} قسم)',
                            style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...stores.map((s) {
                          final count = allCategories.where((c) => c.storeId == s.id).length;
                          return DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(
                              '${s.name} ($count قسم)',
                              style: AppFonts.cairoFont(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedStoreId = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: catProvider.isLoading
                    ? const ShimmerLoadingList(itemCount: 8, height: 55)
                    : filteredCategories.isEmpty
                        ? Center(
                            child: Text(
                              catProvider.searchQuery.isNotEmpty
                                  ? 'لا توجد نتائج مطابقة'
                                  : 'لا توجد أقسام منتجات مضافة لهذا المطعم',
                              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: groupedCategories.keys.length,
                            itemBuilder: (ctx, index) {
                              final storeId = groupedCategories.keys.elementAt(index);
                              final catsInGroup = groupedCategories[storeId]!;

                              // Find store model if available
                              StoreModel? store;
                              if (storeId != null) {
                                final storeMatches = stores.where((s) => s.id == storeId);
                                if (storeMatches.isNotEmpty) store = storeMatches.first;
                              }

                              final storeTitle = store != null
                                  ? store.name
                                  : (catsInGroup.first.storeName ?? 'أقسام عامة (جميع المطاعم)');

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppColors.primary.withAlpha(40)),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withAlpha(20),
                                    child: const Icon(Icons.storefront, color: AppColors.primary, size: 20),
                                  ),
                                  title: Text(
                                    storeTitle,
                                    style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  subtitle: Text(
                                    '${catsInGroup.length} فئات منتجات تابعة للمحل',
                                    style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  children: catsInGroup.map((cat) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: CustomCachedImage(
                                          imageUrl: cat.imageUrl,
                                          width: 44,
                                          height: 44,
                                          borderRadius: BorderRadius.circular(22),
                                          errorWidget: CircleAvatar(
                                            backgroundColor: AppColors.primary.withAlpha(20),
                                            child: Text(
                                              cat.name.isNotEmpty ? cat.name.substring(0, 1) : '?',
                                              style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          cat.name,
                                          style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          cat.hasDiscount
                                              ? 'خصم شامل: ${cat.discountType == 'percentage' ? '${cat.discountValue}%' : '${cat.discountValue} ر.ي'}'
                                              : (cat.isMainCategory ? 'فئة رئيسية' : 'فئة فرعية'),
                                          style: AppFonts.cairoFont(
                                            fontSize: 12,
                                            color: cat.hasDiscount ? AppColors.danger : Colors.grey,
                                            fontWeight: cat.hasDiscount ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (admin != null && admin.hasPermission(AdminPermissions.categoriesEdit))
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                                                onPressed: () => _openEditCategory(cat),
                                              ),
                                            if (admin != null && admin.hasPermission(AdminPermissions.categoriesDelete))
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                                onPressed: () => _confirmDelete(cat),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
