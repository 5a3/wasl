import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../admin_app/providers/category_provider.dart';
import '../../../admin_app/providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../utils/cart_helper.dart';

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
    final productProvider = Provider.of<ProductProvider>(context);

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

    // Query similar / recommended products strictly from the SAME STORE
    final allProducts = productProvider.products;
    final currentStoreId = widget.product.storeId;

    final similarProducts = allProducts.where((p) {
      if (p.id == widget.product.id) return false;

      // STRICT CHECK: Must belong to the exact same store!
      if (currentStoreId != null && currentStoreId.isNotEmpty) {
        if (p.storeId != currentStoreId) return false;
      }

      final sameCategory = p.mainCategoryId == widget.product.mainCategoryId || p.subCategoryId == widget.product.subCategoryId;
      final nameSimilarity = p.name.trim().toLowerCase().split(' ').any((word) => 
        word.length > 2 && widget.product.name.trim().toLowerCase().contains(word)
      );
      return sameCategory || nameSimilarity;
    }).toList();

    // Fallback if category recommendations are sparse (strictly from same store!)
    if (similarProducts.length < 3) {
      for (final item in allProducts) {
        if (item.id != widget.product.id && !similarProducts.contains(item)) {
          if (currentStoreId != null && currentStoreId.isNotEmpty) {
            if (item.storeId != currentStoreId) continue;
          }
          similarProducts.add(item);
        }
        if (similarProducts.length >= 6) break;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Elegant transparent Appbar with Product Hero Image Slider
          SliverAppBar(
            expandedHeight: 290,
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
                                width: _currentImageIndex == index ? 16 : 7,
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
                backgroundColor: Colors.black.withAlpha(110),
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
                  backgroundColor: Colors.black.withAlpha(110),
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

          // 2. Product Details Contents Card
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 100),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Availability Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: AppFonts.cairoFont(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.product.isAvailable ? AppColors.success.withAlpha(20) : AppColors.danger.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.product.isAvailable ? AppColors.success.withAlpha(50) : AppColors.danger.withAlpha(50),
                          ),
                        ),
                        child: Text(
                          widget.product.isAvailable ? 'متوفر حالياً 🟢' : 'غير متوفر 🔴',
                          style: AppFonts.cairoFont(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: widget.product.isAvailable ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Price Display with Discount Support
                  if (hasDisc) ...[
                    Row(
                      children: [
                        Text(
                          Formatters.formatCurrency(widget.product.price),
                          style: AppFonts.cairoFont(
                            fontSize: 15,
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
                            fontSize: 24,
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                  const Divider(height: 32),

                  // Description Header
                  Text(
                    'تفاصيل ومكونات الوجبة 📖',
                    style: AppFonts.cairoFont(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description text
                  Text(
                    widget.product.description.isNotEmpty
                        ? widget.product.description
                        : 'لم يتم إضافة تفاصيل إضافية لهذا الصنف من قبل الإدارة. الوجبة تحضر طازجة وبأعلى جودة.',
                    style: AppFonts.cairoFont(
                      fontSize: 13.5,
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3. Recommended Products Section ("وجبات قد تعجبك 🍽️")
                  if (similarProducts.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'وجبات قد تعجبك 🍽️',
                          style: AppFonts.cairoFont(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'مقترحة لك',
                          style: AppFonts.cairoFont(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 205,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: similarProducts.length,
                        itemBuilder: (ctx, index) {
                          final simProduct = similarProducts[index];
                          final simFav = favProvider.isFavorite(simProduct.id);

                          CategoryModel? simCat;
                          try {
                            simCat = catProvider.categories.firstWhere((c) => c.id == simProduct.mainCategoryId);
                          } catch (_) {}

                          final simHasDisc = simProduct.hasEffectiveDiscount(simCat);
                          final simEffectivePrice = simProduct.getEffectivePrice(simCat);

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailsScreen(product: simProduct),
                                ),
                              );
                            },
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(left: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail Image with Favorite Button & Discount Badge
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: CustomCachedImage(
                                          imageUrl: simProduct.images.isNotEmpty ? simProduct.images.first : '',
                                          width: double.infinity,
                                          height: 105,
                                          fit: BoxFit.cover,
                                          errorWidget: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 6,
                                        left: 6,
                                        child: GestureDetector(
                                          onTap: () => favProvider.toggleFavorite(simProduct.id),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withAlpha(100),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              simFav ? Icons.favorite : Icons.favorite_border,
                                              color: simFav ? AppColors.danger : Colors.white,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (simHasDisc)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.danger,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              simProduct.getDiscountBadgeText(simCat),
                                              style: AppFonts.cairoFont(
                                                fontSize: 9,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  // Product Info
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          simProduct.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFonts.cairoFont(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          simProduct.description.isNotEmpty 
                                              ? simProduct.description 
                                              : 'وجبة طازجة وبأعلى جودة...',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFonts.cairoFont(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (simHasDisc) ...[
                                          Row(
                                            children: [
                                              Text(
                                                Formatters.formatCurrency(simEffectivePrice),
                                                style: AppFonts.cairoFont(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  Formatters.formatCurrency(simProduct.price),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppFonts.cairoFont(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade500,
                                                    decoration: TextDecoration.lineThrough,
                                                    decorationColor: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else
                                          Text(
                                            Formatters.formatCurrency(simProduct.price),
                                            style: AppFonts.cairoFont(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
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
                ],
              ),
            ),
          ),
        ],
      ),

        // 4. Fixed Sticky Bottom Action Bar (Always visible without scrolling!)
        bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: widget.product.isAvailable
              ? (isInCart
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 24),
                        
                        // Increment button
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary.withAlpha(100)),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.primary.withAlpha(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: AppColors.primary),
                            onPressed: () {
                              CartHelper.checkAndAddToCart(
                                context: context,
                                product: widget.product,
                                category: category,
                                showSnackBarOnSuccess: false,
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 22),
                        label: Text(
                          'إضافة هذه الوجبة إلى الطلب 🛒',
                          style: AppFonts.cairoFont(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          CartHelper.checkAndAddToCart(
                            context: context,
                            product: widget.product,
                            category: category,
                            showSnackBarOnSuccess: true,
                          );
                        },
                      ),
                    ))
              : Container(
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
        ),
      ),
    );
  }
}
