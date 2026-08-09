import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../admin_app/providers/category_provider.dart';
import '../../../admin_app/providers/product_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../home/product_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final ScrollController? scrollController;
  final bool isStandalone;

  const FavoritesScreen({
    super.key,
    this.scrollController,
    this.isStandalone = false,
  });

  @override
  Widget build(BuildContext context) {
    final favProvider = Provider.of<FavoriteProvider>(context);
    final prodProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    final favoriteProducts =
        prodProvider.products
            .where((p) => favProvider.isFavorite(p.id))
            .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar:
          isStandalone
              ? AppBar(
                title: Text(
                  'الأطباق المفضلة ❤️',
                  style: AppFonts.cairoFont(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black87,
                elevation: 0.5,
              )
              : null,
      body:
          favoriteProducts.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 64,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'قائمة المفضلة فارغة',
                        style: AppFonts.cairoFont(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على زر القلب عند أي وجبة شهية لإضافتها إلى قائمة المفضلة هنا.',
                        textAlign: TextAlign.center,
                        style: AppFonts.cairoFont(
                          fontSize: 13,
                          color:
                              isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(14),
                itemCount: favoriteProducts.length,
                itemBuilder: (ctx, index) {
                  final product = favoriteProducts[index];
                  return _buildListProductCard(
                    context,
                    product,
                    isDark,
                    favProvider,
                    cartProvider,
                  );
                },
              ),
    );
  }

  Widget _buildListProductCard(
    BuildContext context,
    ProductModel product,
    bool isDark,
    FavoriteProvider favProvider,
    CartProvider cartProvider,
  ) {
    final catProvider = Provider.of<CategoryProvider>(context);
    CategoryModel? category;
    try {
      category = catProvider.categories.firstWhere((c) => c.id == product.mainCategoryId);
    } catch (_) {}

    final hasDisc = product.hasEffectiveDiscount(category);
    final effectivePrice = product.getEffectivePrice(category);

    final isFav = favProvider.isFavorite(product.id);
    final cartItem = cartProvider.items[product.id];
    final isInCart = cartItem != null;
    final qty = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Product Image Stack
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(15),
                    ),
                    child: CustomCachedImage(
                      imageUrl:
                          product.images.isNotEmpty ? product.images.first : '',
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 110,
                        height: 110,
                        color: AppColors.primary.withAlpha(15),
                        child: const Icon(
                          Icons.fastfood,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  if (hasDisc)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🔥 ${product.getDiscountBadgeText(category)}',
                          style: AppFonts.cairoFont(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Unavailable Overlay
                  if (!product.isAvailable)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(15),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'غير متوفر',
                            style: AppFonts.cairoFont(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // 2. Product Details Column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header: Title & Favorite Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: AppFonts.cairoFont(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              favProvider.toggleFavorite(product.id);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color:
                                    isFav
                                        ? AppColors.danger
                                        : Colors.grey.shade400,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Description
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          product.description,
                          style: AppFonts.cairoFont(
                            fontSize: 11,
                            color:
                                isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Price & Add to Cart Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasDisc)
                                  Text(
                                    Formatters.formatCurrency(product.price),
                                    style: AppFonts.cairoFont(
                                      fontSize: 10.5,
                                      color: Colors.grey.shade500,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.grey.shade500,
                                    ),
                                    maxLines: 1,
                                  ),
                                Text(
                                  Formatters.formatCurrency(effectivePrice),
                                  style: AppFonts.cairoFont(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: hasDisc ? Colors.green.shade700 : AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Interactive Quantity Stepper / Add to Cart Button
                          if (isInCart && qty > 0)
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(50),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Decrement / Remove Button
                                  InkWell(
                                    onTap: () => cartProvider.decrementItem(product.id),
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                      child: Icon(
                                        qty == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Quantity Counter
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '$qty',
                                      style: AppFonts.cairoFont(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Increment Button
                                  InkWell(
                                    onTap: () {
                                      if (product.isAvailable) {
                                        cartProvider.addToCart(product, category: category);
                                      }
                                    },
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            InkWell(
                              onTap: () {
                                if (product.isAvailable) {
                                  cartProvider.addToCart(product, category: category);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: product.isAvailable
                                      ? AppColors.primary.withAlpha(20)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: product.isAvailable
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_shopping_cart,
                                      size: 14,
                                      color: product.isAvailable
                                          ? AppColors.primary
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'إضافة',
                                      style: AppFonts.cairoFont(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: product.isAvailable
                                            ? AppColors.primary
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
