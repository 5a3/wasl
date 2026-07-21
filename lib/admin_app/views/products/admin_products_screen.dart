import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../core/widgets/shimmer_loading_list.dart';
import '../../../shared/models/product_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import 'add_edit_product_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
    );
  }

  void _openEditProduct(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditProductScreen(productToEdit: product)),
    );
  }

  void _confirmDelete(ProductModel product) async {
    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'حذف المنتج',
      message: 'هل أنت تأكد من حذف منتج "${product.name}"؟',
      confirmColor: AppColors.danger,
    );

    if (confirm == true && mounted) {
      final ok = await Provider.of<ProductProvider>(context, listen: false).deleteProduct(product.id);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم حذف المنتج بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_admin_products',
        backgroundColor: AppColors.primary,
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة منتج جديد',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, prodProvider, _) {
          return Column(
            children: [
              // Search Bar Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    prodProvider.setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم المنتج أو الوصف...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: prodProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              prodProvider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: prodProvider.isLoading
                    ? const ShimmerLoadingList(itemCount: 8, height: 65)
                    : prodProvider.products.isEmpty
                        ? Center(
                            child: Text(
                              prodProvider.searchQuery.isNotEmpty ? 'لا توجد نتائج مطابقة' : 'لا توجد منتجات مضافة حالياً',
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
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          CustomCachedImage(
                                            imageUrl: product.images.isNotEmpty ? product.images.first : '',
                                            width: 65,
                                            height: 65,
                                            borderRadius: BorderRadius.circular(10),
                                            errorWidget: const Icon(Icons.fastfood, color: Colors.grey),
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
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 18),
                                            label: Text('تعديل المنتج', style: AppFonts.cairoFont(color: AppColors.info)),
                                            onPressed: () => _openEditProduct(product),
                                          ),
                                          const SizedBox(width: 12),
                                          TextButton.icon(
                                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                            label: Text('حذف', style: AppFonts.cairoFont(color: AppColors.danger)),
                                            onPressed: () => _confirmDelete(product),
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
