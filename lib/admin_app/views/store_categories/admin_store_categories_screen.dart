import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/store_category_model.dart';
import '../../providers/store_category_provider.dart';

class AdminStoreCategoriesScreen extends StatefulWidget {
  const AdminStoreCategoriesScreen({super.key});

  @override
  State<AdminStoreCategoriesScreen> createState() => _AdminStoreCategoriesScreenState();
}

class _AdminStoreCategoriesScreenState extends State<AdminStoreCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoreCategoryProvider>(context, listen: false).fetchStoreCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrEditCategoryDialog([StoreCategoryModel? categoryToEdit]) {
    final isEditing = categoryToEdit != null;
    final categoryController = TextEditingController(text: categoryToEdit?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final provider = Provider.of<StoreCategoryProvider>(context, listen: false);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'تعديل اسم قسم المحل' : 'إضافة قسم جديد للمحلات',
            textAlign: TextAlign.center,
            style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: categoryController,
                labelText: 'اسم القسم / الفئة *',
                hintText: 'مثال: مطعم، كفتيريا، خضروات وفواكه...',
                prefixIcon: Icons.category,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = categoryController.text.trim();
                if (name.isEmpty) {
                  CustomDialog.showErrorSnackBar(ctx, 'يرجى كتابة اسم القسم');
                  return;
                }

                bool ok = false;
                if (isEditing) {
                  ok = await provider.editStoreCategory(categoryToEdit.id, name);
                } else {
                  ok = await provider.addStoreCategory(name);
                }

                if (ok) {
                  if (ctx.mounted) {
                    CustomDialog.showSuccessSnackBar(
                      ctx,
                      isEditing ? 'تم تعديل اسم القسم بنجاح' : 'تم إضافة قسم المحلات بنجاح',
                    );
                    Navigator.of(ctx).pop();
                  }
                } else {
                  if (ctx.mounted) {
                    CustomDialog.showErrorSnackBar(
                      ctx,
                      provider.errorMessage ?? 'حدث خطأ أثناء الحفظ',
                    );
                  }
                }
              },
              child: Text(
                isEditing ? 'تعديل' : 'إضافة',
                style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(StoreCategoryModel category) async {
    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'حذف قسم المحل',
      message: 'هل أنت تأكد من حذف قسم "${category.name}"؟',
      confirmColor: AppColors.danger,
    );

    if (confirm == true && mounted) {
      final ok = await Provider.of<StoreCategoryProvider>(context, listen: false).deleteStoreCategory(category.id);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم حذف القسم بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة أقسام المحلات 🏷️',
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_admin_store_categories',
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddOrEditCategoryDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة قسم جديد',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<StoreCategoryProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    provider.setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم قسم المحل...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const LoadingIndicator(message: 'جاري جلب قائمة أقسام المحلات...')
                    : provider.storeCategories.isEmpty
                        ? Center(
                            child: Text(
                              provider.searchQuery.isNotEmpty
                                  ? 'لا توجد نتائج مطابقة'
                                  : 'لا توجد أقسام مضافة حالياً. قم بإضافة أول قسم!',
                              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: provider.storeCategories.length,
                            itemBuilder: (ctx, index) {
                              final cat = provider.storeCategories[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Icon(Icons.category, color: Colors.white),
                                  ),
                                  title: Text(
                                    cat.name,
                                    style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppColors.info),
                                        onPressed: () => _showAddOrEditCategoryDialog(cat),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                        onPressed: () => _confirmDelete(cat),
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
