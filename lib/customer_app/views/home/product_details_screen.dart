import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../admin_app/providers/category_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final favProvider = Provider.of<FavoriteProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);
    final isFav = favProvider.isFavorite(widget.product.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    CategoryModel? category;
    try {
      category = catProvider.categories.firstWhere((c) => c.id == widget.product.mainCategoryId);
    } catch (_) {}

    final hasDisc = widget.product.hasEffectiveDiscount(category);
    final effectivePrice = widget.product.getEffectivePrice(category);
    final savings = widget.product.getSavingsAmount(category);

    final isInCart = cartProvider.items.containsKey(widget.product.id);
    final currentQty = isInCart ? cartProvider.items[widget.product.id]!.quantity : 0;
    
    final List<String> images = widget.product.images.isNotEmpty 
        ? widget.product.images 
        : [''];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Elegant transparent Appbar with Product Hero Image Slider
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: images.length <= 1
                  ? Hero(
                      tag: 'product_image_${widget.product.id}',
                      child: CustomCachedImage(
                        imageUrl: images.first,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(Icons.fastfood, size: 70, color: Colors.grey),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned.fill(
                          child: PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (ctx, idx) {
                              return CustomCachedImage(
                                imageUrl: images[idx],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: const Icon(Icons.fastfood, size: 70, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        // Dots Indicator overlaying the image
                        Positioned(
                          bottom: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 14 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index ? AppColors.primary : Colors.white70,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withAlpha(100),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withAlpha(100),
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.danger : Colors.white,
                    ),
                    onPressed: () {
                      favProvider.toggleFavorite(widget.product.id);
                    },
                  ),
                ),
              ),
            ],
          ),

          // Product Details Contents Card
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Availability
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: AppFonts.cairoFont(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.product.isAvailable ? AppColors.success.withAlpha(20) : AppColors.danger.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: widget.product.isAvailable ? AppColors.success.withAlpha(50) : AppColors.danger.withAlpha(50)),
                        ),
                        child: Text(
                          widget.product.isAvailable ? 'متوفر حالياً 🟢' : 'غير متوفر 🔴',
                          style: AppFonts.cairoFont(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.product.isAvailable ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price Display with Discount Support
                  if (hasDisc) ...[
                    Row(
                      children: [
                        Text(
                          Formatters.formatCurrency(widget.product.price),
                          style: AppFonts.cairoFont(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔥 ${widget.product.getDiscountBadgeText(category)}',
                            style: AppFonts.cairoFont(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          Formatters.formatCurrency(effectivePrice),
                          style: AppFonts.cairoFont(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '(وفرت ${Formatters.formatCurrency(savings)}! 🎉)',
                          style: AppFonts.cairoFont(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      Formatters.formatCurrency(widget.product.price),
                      style: AppFonts.cairoFont(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  const Divider(height: 30),

                  // Description Header
                  Text(
                    'تفاصيل ومكونات الوجبة 📖',
                    style: AppFonts.cairoFont(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description text
                  Text(
                    widget.product.description.isNotEmpty
                        ? widget.product.description
                        : 'لم يتم إضافة تفاصيل إضافية لهذا الصنف من قبل الإدارة. الوجبة تحضر طازجة وبأعلى جودة.',
                    style: AppFonts.cairoFont(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Cart controls
                  if (widget.product.isAvailable)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: isInCart
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Decrement button
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.danger.withAlpha(100)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.remove, color: AppColors.danger),
                                    onPressed: () {
                                      cartProvider.decrementItem(widget.product.id);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 24),
                                
                                // Quantity display
                                Text(
                                  '$currentQty',
                                  style: AppFonts.cairoFont(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                
                                // Increment button
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.primary.withAlpha(100)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add, color: AppColors.primary),
                                    onPressed: () {
                                      cartProvider.addToCart(widget.product, category: category);
                                    },
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                              label: Text(
                                'إضافة هذه الوجبة إلى الطلب 🛒',
                                style: AppFonts.cairoFont(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () {
                                cartProvider.addToCart(widget.product, category: category);
                                CustomDialog.showSuccessSnackBar(
                                  context,
                                  'تم إضافة ${widget.product.name} إلى السلة 🍔',
                                );
                              },
                            ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'الصنف غير متوفر للطلب حالياً',
                        textAlign: TextAlign.center,
                        style: AppFonts.cairoFont(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
