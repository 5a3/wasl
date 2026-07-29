import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../admin_app/providers/product_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';

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

    final favoriteProducts = prodProvider.products
        .where((p) => favProvider.isFavorite(p.id))
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: isStandalone
          ? AppBar(
              title: Text(
                'الأطباق المفضلة',
                style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              elevation: 0.5,
            )
          : null,
      body: favoriteProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 70, color: Colors.grey),
                  const SizedBox(height: 14),
                  Text(
                    'قائمة المفضلة فارغة حالياً',
                    style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اضغط على زر القلب عند أي وجبة لإضافتها هنا',
                    style: AppFonts.cairoFont(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: favoriteProducts.length,
              itemBuilder: (ctx, index) {
                final product = favoriteProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withAlpha(20),
                      child: const Icon(Icons.fastfood, color: AppColors.primary),
                    ),
                    title: Text(product.name, style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
                    subtitle: Text(Formatters.formatCurrency(product.price), style: AppFonts.cairoFont(color: AppColors.primary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                          onPressed: () {
                            cartProvider.addToCart(product);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: AppColors.danger),
                          onPressed: () {
                            favProvider.toggleFavorite(product.id);
                          },
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
