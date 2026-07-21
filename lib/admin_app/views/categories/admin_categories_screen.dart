import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/category_model.dart';
import '../../providers/category_provider.dart';
import 'add_edit_category_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCategory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditCategoryScreen()),
    );
  }

  void _openEditCategory(CategoryModel category) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditCategoryScreen(categoryToEdit: category)),
    );
  }

  void _confirmDelete(CategoryModel category) async {
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
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _openAddCategory,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة فئة جديدة',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, catProvider, _) {
          return Column(
            children: [
              // Search Bar Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    catProvider.setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم الفئة...',
                    prefixIcon: const Icon(Icons.search),
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
              ),
              Expanded(
                child: catProvider.isLoading
                    ? const LoadingIndicator(message: 'جاري جلب الفئات...')
                    : catProvider.categories.isEmpty
                        ? Center(
                            child: Text(
                              catProvider.searchQuery.isNotEmpty ? 'لا توجد نتائج مطابقة' : 'لا توجد فئات مضافة حالياً',
                              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: catProvider.categories.length,
                            itemBuilder: (ctx, index) {
                              final cat = catProvider.categories[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withAlpha(20),
                                    backgroundImage: cat.imageUrl.isNotEmpty ? NetworkImage(cat.imageUrl) : null,
                                    child: cat.imageUrl.isEmpty
                                        ? Text(
                                            cat.name.substring(0, 1),
                                            style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    cat.name,
                                    style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    cat.isMainCategory ? 'فئة رئيسية' : 'فئة فرعية',
                                    style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppColors.info),
                                        onPressed: () => _openEditCategory(cat),
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
