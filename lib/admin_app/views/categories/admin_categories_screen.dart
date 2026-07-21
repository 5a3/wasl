import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/category_model.dart';
import '../../providers/category_provider.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final imageController = TextEditingController();
    CategoryModel? selectedMainCategory;

    showDialog(
      context: context,
      builder: (ctx) {
        final catProvider = Provider.of<CategoryProvider>(context);
        final mainCats = catProvider.mainCategories;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'إضافة فئة جديدة',
                textAlign: TextAlign.center,
                style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: nameController,
                      labelText: 'اسم الفئة',
                      hintText: 'مثال: العصائر والمشروبات، وجبات سريعة...',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: imageController,
                      labelText: 'رابط صورة الفئة (URL)',
                      hintText: 'https://example.com/image.jpg',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CategoryModel?>(
                      value: selectedMainCategory,
                      decoration: const InputDecoration(
                        labelText: 'الفئة الرئيسية (اتركه فارغاً إذا كانت فئة رئيسية)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('فئة رئيسية أصلية'),
                        ),
                        ...mainCats.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat.name),
                            )),
                      ],
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedMainCategory = val;
                        });
                      },
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
                    if (nameController.text.trim().isEmpty) return;
                    final ok = await catProvider.addCategory(
                      name: nameController.text,
                      parentId: selectedMainCategory?.id,
                      imageUrl: imageController.text.trim(),
                    );
                    if (ok && ctx.mounted) {
                      Navigator.of(ctx).pop();
                      CustomDialog.showSuccessSnackBar(context, 'تم إضافة الفئة بنجاح');
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
    final catProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة فئة',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: catProvider.isLoading
          ? const LoadingIndicator(message: 'جاري جلب الفئات...')
          : catProvider.categories.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد فئات مضافة حالياً',
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
                          child: Text(
                            cat.name.substring(0, 1),
                            style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          cat.name,
                          style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          cat.isMainCategory ? 'فئة رئيسية' : 'فئة فرعية',
                          style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Switch(
                          value: cat.isActive,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            catProvider.toggleCategoryStatus(cat.id, val);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
