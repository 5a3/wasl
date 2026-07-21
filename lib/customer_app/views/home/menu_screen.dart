import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../admin_app/providers/category_provider.dart';
import '../../../admin_app/providers/product_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = Provider.of<CategoryProvider>(context);
    final prodProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final favProvider = Provider.of<FavoriteProvider>(context);

    final filteredProducts = _selectedCategoryId == null
        ? prodProvider.products
        : prodProvider.products.where((p) => p.mainCategoryId == _selectedCategoryId || p.subCategoryId == _selectedCategoryId).toList();

    return Scaffold(
      body: Column(
        children: [
          // Categories Filter Horizontal Bar
          if (catProvider.categories.isNotEmpty)
            Container(
              height: 55,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text('الكل', style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
                      selected: _selectedCategoryId == null,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedCategoryId == null ? Colors.white : Colors.black,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryId = null;
                        });
                      },
                    ),
                  ),
                  ...catProvider.categories.map((cat) {
                    final isSelected = _selectedCategoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(cat.name, style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategoryId = cat.id;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          Expanded(
            child: prodProvider.isLoading
                ? const LoadingIndicator(message: 'جاري تحميل قائمة الطعام المحدثة...')
                : filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد وجبات أو عصائر متوفرة في هذه الفئة',
                          style: AppFonts.cairoFont(fontSize: 15, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (ctx, index) {
                          final product = filteredProducts[index];
                          final isFav = favProvider.isFavorite(product.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 90,
                                      height: 90,
                                      color: Colors.grey.shade200,
                                      child: product.images.isNotEmpty
                                          ? Image.network(
                                              product.images.first,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                                            )
                                          : const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: AppFonts.cairoFont(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isFav ? Icons.favorite : Icons.favorite_border,
                                                color: isFav ? AppColors.danger : Colors.grey,
                                              ),
                                              onPressed: () {
                                                favProvider.toggleFavorite(product.id);
                                              },
                                            ),
                                          ],
                                        ),
                                        Text(
                                          product.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              Formatters.formatCurrency(product.price),
                                              style: AppFonts.cairoFont(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            if (product.isAvailable)
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.add_shopping_cart, size: 16, color: Colors.white),
                                                label: Text(
                                                  'إضافة للطلب',
                                                  style: AppFonts.cairoFont(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  cartProvider.addToCart(product);
                                                  CustomDialog.showSuccessSnackBar(
                                                    context,
                                                    'تم إضافة ${product.name} إلى السلة',
                                                  );
                                                },
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade300,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'غير متوفر حالياً',
                                                  style: AppFonts.cairoFont(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
