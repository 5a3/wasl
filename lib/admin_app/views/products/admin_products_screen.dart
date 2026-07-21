import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final img1Controller = TextEditingController();
    final img2Controller = TextEditingController();
    final img3Controller = TextEditingController();

    CategoryModel? selectedMainCat;
    CategoryModel? selectedSubCat;
    bool isAvailable = true;

    showDialog(
      context: context,
      builder: (ctx) {
        final catProvider = Provider.of<CategoryProvider>(context);
        final prodProvider = Provider.of<ProductProvider>(context);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final mainCats = catProvider.mainCategories;
            final subCats = selectedMainCat != null
                ? catProvider.getSubCategories(selectedMainCat!.id)
                : <CategoryModel>[];

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'إضافة منتج / وجبة جديدة',
                textAlign: TextAlign.center,
                style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: nameController,
                      labelText: 'اسم المنتج',
                      hintText: 'مثال: عصير مانجو طبيعي، برجر دجاج...',
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: descController,
                      labelText: 'وصف المنتج',
                      hintText: 'مثال: عصير طازج بدون سكر مضاف...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: priceController,
                      labelText: 'السعر (بالريال اليمني)',
                      hintText: 'مثال: 1500',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<CategoryModel>(
                      value: selectedMainCat,
                      decoration: const InputDecoration(labelText: 'الفئة الرئيسية'),
                      items: mainCats.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.name))).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedMainCat = val;
                          selectedSubCat = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<CategoryModel>(
                      value: selectedSubCat,
                      decoration: const InputDecoration(labelText: 'الفئة الفرعية'),
                      items: subCats.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.name))).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedSubCat = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: img1Controller,
                      labelText: 'صورة المنتج 1 (URL)',
                      hintText: 'https://...',
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: img2Controller,
                      labelText: 'صورة المنتج 2 اختياري (URL)',
                      hintText: 'https://...',
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: img3Controller,
                      labelText: 'صورة المنتج 3 اختياري (URL)',
                      hintText: 'https://...',
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: Text('هل المنتج متوفر الآن؟', style: AppFonts.cairoFont(fontSize: 14)),
                      value: isAvailable,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setStateDialog(() {
                          isAvailable = val;
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
                    if (nameController.text.trim().isEmpty ||
                        priceController.text.trim().isEmpty ||
                        selectedMainCat == null) {
                      CustomDialog.showErrorSnackBar(context, 'يرجى ملء كافة البيانات الأساسية');
                      return;
                    }

                    final images = <String>[];
                    if (img1Controller.text.trim().isNotEmpty) images.add(img1Controller.text.trim());
                    if (img2Controller.text.trim().isNotEmpty) images.add(img2Controller.text.trim());
                    if (img3Controller.text.trim().isNotEmpty) images.add(img3Controller.text.trim());

                    final ok = await prodProvider.addProduct(
                      name: nameController.text,
                      description: descController.text,
                      price: double.tryParse(priceController.text) ?? 0.0,
                      mainCategoryId: selectedMainCat!.id,
                      subCategoryId: selectedSubCat?.id ?? selectedMainCat!.id,
                      images: images,
                      isAvailable: isAvailable,
                    );

                    if (ok && ctx.mounted) {
                      Navigator.of(ctx).pop();
                      CustomDialog.showSuccessSnackBar(context, 'تم إضافة المنتج بنجاح');
                    }
                  },
                  child: const Text('حفظ المنتج'),
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
    final prodProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة منتج',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: prodProvider.isLoading
          ? const LoadingIndicator(message: 'جاري جلب المنتجات...')
          : prodProvider.products.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد منتجات مضافة حالياً',
                    style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prodProvider.products.length,
                  itemBuilder: (ctx, index) {
                    final product = prodProvider.products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                                image: product.images.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(product.images.first),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: product.images.isEmpty
                                  ? const Icon(Icons.fastfood, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: AppFonts.cairoFont(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    product.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatCurrency(product.price),
                                    style: AppFonts.cairoFont(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  product.isAvailable ? 'متوفر 🟢' : 'غير متوفر 🔴',
                                  style: AppFonts.cairoFont(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: product.isAvailable ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                                Switch(
                                  value: product.isAvailable,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    prodProvider.toggleAvailability(product.id, val);
                                  },
                                ),
                              ],
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
