import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../core/widgets/shimmer_loading_list.dart';
import '../../../shared/models/category_model.dart';
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
  String? _selectedCategoryId; // null means 'All'

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

  void _openAddProduct([String? categoryId]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(
          initialCategoryId: categoryId ?? _selectedCategoryId,
        ),
      ),
    );
  }

  void _openEditProduct(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(productToEdit: product),
      ),
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
      final ok = await Provider.of<ProductProvider>(context, listen: false)
          .deleteProduct(product.id);
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
        onPressed: () => _openAddProduct(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة منتج جديد',
          style: AppFonts.cairoFont(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer2<ProductProvider, CategoryProvider>(
        builder: (context, prodProvider, catProvider, _) {
          // Zero Extra Firebase Reads: local in-memory filtering
          final rawProducts = prodProvider.products;
          final categories = catProvider.mainCategories;

          final filteredProducts = rawProducts.where((product) {
            if (_selectedCategoryId == null) return true;
            return product.mainCategoryId == _selectedCategoryId ||
                product.subCategoryId == _selectedCategoryId;
          }).toList();

          CategoryModel? selectedCategory;
          if (_selectedCategoryId != null) {
            final idx = categories.indexWhere((c) => c.id == _selectedCategoryId);
            if (idx != -1) selectedCategory = categories[idx];
          }

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

              // Category Filter Chips Bar (In-Memory Filtering)
              if (!catProvider.isLoading && categories.isNotEmpty)
                _buildCategoryFilterBar(prodProvider, categories),

              // Active Category Badge / Counter Info
              if (_selectedCategoryId != null && selectedCategory != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withAlpha(80)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.category, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'عرض فئة: ${selectedCategory.name} (${filteredProducts.length})',
                              style: AppFonts.cairoFont(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = null;
                                });
                              },
                              child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'إجمالي الفئة: ${filteredProducts.length}',
                        style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),

              // Products List or Empty State
              Expanded(
                child: prodProvider.isLoading
                    ? const ShimmerLoadingList(itemCount: 8, height: 65)
                    : filteredProducts.isEmpty
                        ? _buildEmptyState(prodProvider, selectedCategory)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredProducts.length,
                            itemBuilder: (ctx, index) {
                              final product = filteredProducts[index];

                              // Find category name for display
                              final catIndex = categories.indexWhere(
                                (c) => c.id == product.mainCategoryId,
                              );
                              final catName = catIndex != -1
                                  ? categories[catIndex].name
                                  : null;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CustomCachedImage(
                                            imageUrl: product.images.isNotEmpty
                                                ? product.images.first
                                                : '',
                                            width: 70,
                                            height: 70,
                                            borderRadius: BorderRadius.circular(10),
                                            errorWidget: const Icon(
                                              Icons.fastfood,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        product.name,
                                                        style: AppFonts.cairoFont(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    if (catName != null)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey.shade100,
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(
                                                            color: Colors.grey.shade300,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          catName,
                                                          style: AppFonts.cairoFont(
                                                            fontSize: 10,
                                                            color: Colors.grey.shade800,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  product.description,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppFonts.cairoFont(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
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
                                          const SizedBox(width: 8),
                                          Column(
                                            children: [
                                              Text(
                                                product.isAvailable ? 'متوفر 🟢' : 'غير متوفر 🔴',
                                                style: AppFonts.cairoFont(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: product.isAvailable
                                                      ? AppColors.success
                                                      : AppColors.danger,
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
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: AppColors.info,
                                              size: 18,
                                            ),
                                            label: Text(
                                              'تعديل المنتج',
                                              style: AppFonts.cairoFont(color: AppColors.info),
                                            ),
                                            onPressed: () => _openEditProduct(product),
                                          ),
                                          const SizedBox(width: 12),
                                          TextButton.icon(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.danger,
                                              size: 18,
                                            ),
                                            label: Text(
                                              'حذف',
                                              style: AppFonts.cairoFont(color: AppColors.danger),
                                            ),
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

  /// Horizontal Scrollable Category Filter Chips
  Widget _buildCategoryFilterBar(ProductProvider prodProvider, List<CategoryModel> categories) {
    final totalCount = prodProvider.products.length;

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1, // +1 for 'All'
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedCategoryId == null;
            return Container(
              margin: const EdgeInsets.only(left: 8),
              child: FilterChip(
                selected: isSelected,
                showCheckmark: false,
                avatar: Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
                label: Text('الكل ($totalCount)'),
                labelStyle: AppFonts.cairoFont(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onSelected: (_) {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                },
              ),
            );
          }

          final cat = categories[index - 1];
          final isSelected = _selectedCategoryId == cat.id;

          // Count products for this category in memory
          final catProductCount = prodProvider.products.where(
            (p) => p.mainCategoryId == cat.id || p.subCategoryId == cat.id,
          ).length;

          return Container(
            margin: const EdgeInsets.only(left: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: cat.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CustomCachedImage(
                        imageUrl: cat.imageUrl,
                        width: 20,
                        height: 20,
                      ),
                    )
                  : Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
              label: Text('${cat.name} ($catProductCount)'),
              labelStyle: AppFonts.cairoFont(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onSelected: (_) {
                setState(() {
                  _selectedCategoryId = cat.id;
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// Empty state display with direct category product addition
  Widget _buildEmptyState(ProductProvider prodProvider, CategoryModel? selectedCategory) {
    if (selectedCategory != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fastfood_outlined,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد منتجات في فئة "${selectedCategory.name}"',
                style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'يمكنك إضافة أول منتج لهذه الفئة الآن مباشرة',
                style: AppFonts.cairoFont(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'إضافة منتج لفئة ${selectedCategory.name}',
                  style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _openAddProduct(selectedCategory.id),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Text(
        prodProvider.searchQuery.isNotEmpty
            ? 'لا توجد نتائج مطابقة لـ "${prodProvider.searchQuery}"'
            : 'لا توجد منتجات مضافة حالياً',
        style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}
