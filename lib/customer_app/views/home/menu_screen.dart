import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../admin_app/providers/category_provider.dart';
import '../../../admin_app/providers/product_provider.dart';
import '../../../admin_app/providers/ad_provider.dart';
import '../../../shared/models/ad_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import 'product_details_screen.dart';

class MenuScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const MenuScreen({super.key, this.scrollController});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  int _currentAdPage = 0;
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  Future<void> _loadViewPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _isGridView = prefs.getBool('menu_is_grid_view') ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleViewMode(bool isGrid) async {
    setState(() {
      _isGridView = isGrid;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('menu_is_grid_view', isGrid);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = Provider.of<CategoryProvider>(context);
    final prodProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final favProvider = Provider.of<FavoriteProvider>(context);
    final adProvider = Provider.of<AdProvider>(context);

    // Dynamic search filtering
    final filteredProducts =
        prodProvider.products.where((product) {
          final matchesCategory =
              _selectedCategoryId == null ||
              product.mainCategoryId == _selectedCategoryId ||
              product.subCategoryId == _selectedCategoryId;

          final matchesSearch =
              _searchQuery.trim().isEmpty ||
              product.name.toLowerCase().contains(
                _searchQuery.trim().toLowerCase(),
              ) ||
              product.description.toLowerCase().contains(
                _searchQuery.trim().toLowerCase(),
              );

          return matchesCategory && matchesSearch;
        }).toList();

    return CustomScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Ads Carousel Slider (Scrolls off screen and disappears)
        SliverToBoxAdapter(child: _buildCarouselAds(adProvider)),

        // 2. Custom Store Promo Banner Card (Coming soon)
        SliverToBoxAdapter(child: _buildCustomStoreBanner(context)),

        // 2. Sticky Header (Search Bar + Categories + Section Title stay pinned)
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyMenuHeaderDelegate(
            height: 215.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchBar(),
                _buildCategoriesAvatars(catProvider),
                _buildSectionTitle(catProvider, filteredProducts.length),
              ],
            ),
          ),
        ),

        // 5. Memory-efficient Lazy Loading Products list
        if (prodProvider.isLoading)
          SliverToBoxAdapter(child: _buildShimmerProducts())
        else if (filteredProducts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'لا توجد نتائج تطابق البحث'
                      : 'لا توجد أصناف متوفرة في هذه الفئة',
                  style: AppFonts.cairoFont(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),
          )
        else if (_isGridView)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((ctx, index) {
                final product = filteredProducts[index];
                final isFav = favProvider.isFavorite(product.id);
                final isInCart = cartProvider.items.containsKey(product.id);
                final qty =
                    isInCart ? cartProvider.items[product.id]!.quantity : 0;
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return _buildGridProductCard(
                  product,
                  isFav,
                  isInCart,
                  qty,
                  isDark,
                  favProvider,
                  cartProvider,
                );
              }, childCount: filteredProducts.length),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, index) {
                final product = filteredProducts[index];
                final isFav = favProvider.isFavorite(product.id);
                final isInCart = cartProvider.items.containsKey(product.id);
                final qty =
                    isInCart ? cartProvider.items[product.id]!.quantity : 0;
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            isDark
                                ? AppColors.darkBorder
                                : Colors.grey.shade200,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 20 : 6),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image Card
                        Stack(
                          children: [
                            Hero(
                              tag: 'product_image_${product.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CustomCachedImage(
                                  imageUrl:
                                      product.images.isNotEmpty
                                          ? product.images.first
                                          : '',
                                  width: 95,
                                  height: 95,
                                  fit: BoxFit.cover,
                                  errorWidget: const Icon(
                                    Icons.fastfood,
                                    size: 36,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            if (!product.isAvailable)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(140),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'غير متوفر',
                                      style: AppFonts.cairoFont(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Product details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: AppFonts.cairoFont(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color:
                                          isFav
                                              ? AppColors.danger
                                              : Colors.grey.shade400,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      favProvider.toggleFavorite(product.id);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.description,
                                style: AppFonts.cairoFont(
                                  fontSize: 11,
                                  color:
                                      isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Formatters.formatCurrency(product.price),
                                    style: AppFonts.cairoFont(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),

                                  // Add to cart interactive controls
                                  if (product.isAvailable)
                                    Builder(
                                      builder: (ctx) {
                                        if (isInCart) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withAlpha(15),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.primary
                                                    .withAlpha(60),
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                InkWell(
                                                  onTap:
                                                      () => cartProvider
                                                          .decrementItem(
                                                            product.id,
                                                          ),
                                                  child: const Icon(
                                                    Icons.remove,
                                                    color: AppColors.danger,
                                                    size: 18,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  child: Text(
                                                    '$qty',
                                                    style: AppFonts.cairoFont(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap:
                                                      () => cartProvider
                                                          .addToCart(product),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: AppColors.primary,
                                                    size: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          return ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.add_shopping_cart,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            label: Text(
                                              'إضافة للطلب',
                                              style: AppFonts.cairoFont(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            onPressed: () {
                                              cartProvider.addToCart(product);
                                              CustomDialog.showSuccessSnackBar(
                                                context,
                                                'تم إضافة ${product.name} إلى السلة',
                                              );
                                            },
                                          );
                                        }
                                      },
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
              }, childCount: filteredProducts.length),
            ),
          ),
      ],
    );
  }

  /// Grid Product Card Item (2 Columns View)
  Widget _buildGridProductCard(
    ProductModel product,
    bool isFav,
    bool isInCart,
    int qty,
    bool isDark,
    FavoriteProvider favProvider,
    CartProvider cartProvider,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack with Favorite button overlay
            Stack(
              children: [
                Hero(
                  tag: 'product_image_${product.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17),
                    ),
                    child: CustomCachedImage(
                      imageUrl:
                          product.images.isNotEmpty ? product.images.first : '',
                      width: double.infinity,
                      height: 125,
                      fit: BoxFit.cover,
                      errorWidget: const Icon(
                        Icons.fastfood,
                        size: 36,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                // Favorite Button Overlay
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withAlpha(
                        190,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppColors.danger : Colors.grey.shade500,
                        size: 18,
                      ),
                      onPressed: () {
                        favProvider.toggleFavorite(product.id);
                      },
                    ),
                  ),
                ),
                // Unavailable Overlay
                if (!product.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(17),
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

            // Product Details (Title, Description, Price & Actions)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppFonts.cairoFont(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.description,
                          style: AppFonts.cairoFont(
                            fontSize: 10,
                            color:
                                isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Price & Cart Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            Formatters.formatCurrency(product.price),
                            style: AppFonts.cairoFont(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isAvailable)
                          Builder(
                            builder: (ctx) {
                              if (isInCart) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary.withAlpha(60),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap:
                                            () => cartProvider.decrementItem(
                                              product.id,
                                            ),
                                        child: const Icon(
                                          Icons.remove,
                                          color: AppColors.danger,
                                          size: 16,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          '$qty',
                                          style: AppFonts.cairoFont(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap:
                                            () =>
                                                cartProvider.addToCart(product),
                                        child: const Icon(
                                          Icons.add,
                                          color: AppColors.primary,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return InkWell(
                                  onTap: () {
                                    cartProvider.addToCart(product);
                                    CustomDialog.showSuccessSnackBar(
                                      context,
                                      'تم إضافة ${product.name} إلى السلة',
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add_shopping_cart,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }
                            },
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
    );
  }

  /// Display interactive full screen preview dialog when tapping an ad
  void _showAdFullPreview(BuildContext context, AdModel ad) {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                    maxWidth: MediaQuery.of(context).size.width * 0.95,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(230),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(100),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ad.title.trim().isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            ad.title,
                            style: AppFonts.cairoFont(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Flexible(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 3.5,
                            child: CustomCachedImage(
                              imageUrl: ad.imageUrl,
                              fit: BoxFit.contain,
                              errorWidget: const Icon(
                                Icons.broken_image,
                                size: 60,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withAlpha(180),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// Package based ads carousel (No Title display as requested)
  Widget _buildCarouselAds(AdProvider adProvider) {
    final activeAds = adProvider.activeAds;
    if (activeAds.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: activeAds.length,
            options: CarouselOptions(
              height: 150.0,
              autoPlay: true,
              autoPlayInterval: const Duration(milliseconds: 3600),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentAdPage = index;
                });
              },
            ),
            itemBuilder: (ctx, idx, realIdx) {
              final ad = activeAds[idx];
              return GestureDetector(
                onTap: () => _showAdFullPreview(context, ad),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 30 : 10),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomCachedImage(
                      imageUrl: ad.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (activeAds.length > 1) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                activeAds.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentAdPage == index ? 14 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color:
                        _currentAdPage == index
                            ? AppColors.primary
                            : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Modern search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'ابحث عن وجبتك المفضلة أو مشروبك... 🔍',
          prefixIcon: const Icon(Icons.search, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 16,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
        ),
      ),
    );
  }

  /// Circular Avatars displaying Category Images with Shimmer support
  Widget _buildCategoriesAvatars(CategoryProvider catProvider) {
    if (catProvider.isLoading && catProvider.categories.isEmpty) {
      return _buildShimmerCategories();
    }

    final mainCats = catProvider.mainCategories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 95,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "ALL" Option (الكل)
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryId = null;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color:
                          _selectedCategoryId == null
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkSurfaceLight
                                  : Colors.grey.shade100),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            _selectedCategoryId == null
                                ? AppColors.primary
                                : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow:
                          _selectedCategoryId == null
                              ? [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(50),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                              : [],
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: 24,
                      color:
                          _selectedCategoryId == null
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الكل',
                    style: AppFonts.cairoFont(
                      fontSize: 10,
                      fontWeight:
                          _selectedCategoryId == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          _selectedCategoryId == null
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkTextPrimary
                                  : Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories Circular List
          ...mainCats.map((cat) {
            final isSelected = _selectedCategoryId == cat.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryId = cat.id;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                          width: 2.0,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(50),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                : [],
                      ),
                      child: ClipOval(
                        child: CustomCachedImage(
                          imageUrl: cat.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(
                            Icons.fastfood,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.name,
                      style: AppFonts.cairoFont(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Shimmer placeholder loader for categories
  Widget _buildShimmerCategories() {
    return Container(
      height: 95,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder:
            (ctx, idx) => Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(width: 40, height: 10, color: Colors.white),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  /// Shimmer placeholder loader for products list
  Widget _buildShimmerProducts() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder:
          (ctx, idx) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Row(
                  children: [
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 150,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 60,
                                height: 16,
                                color: Colors.white,
                              ),
                              Container(
                                width: 80,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
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
            ),
          ),
    );
  }

  /// Section Title & Products Count Header
  Widget _buildSectionTitle(CategoryProvider catProvider, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedCategoryId == null
                            ? 'جميع الأطباق والوجبات'
                            : (catProvider.categories.any(
                                  (c) => c.id == _selectedCategoryId,
                                )
                                ? catProvider.categories
                                    .firstWhere(
                                      (c) => c.id == _selectedCategoryId,
                                    )
                                    .name
                                : 'الأصناف'),
                        style: AppFonts.cairoFont(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Products Count Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'الأصناف: $count',
                  style: AppFonts.cairoFont(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // View Mode Selector (List vs Grid Toggle Switch)
              Builder(
                builder: (ctx) {
                  final isDark = Theme.of(ctx).brightness == Brightness.dark;
                  return Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.darkSurfaceLight
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isDark
                                ? AppColors.darkBorder
                                : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // List View Button
                        InkWell(
                          onTap: () => _toggleViewMode(false),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(9),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  !_isGridView
                                      ? AppColors.primary
                                      : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(9),
                              ),
                            ),
                            child: Icon(
                              Icons.view_list_rounded,
                              size: 18,
                              color:
                                  !_isGridView
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600),
                            ),
                          ),
                        ),
                        // Grid View Button
                        InkWell(
                          onTap: () => _toggleViewMode(true),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(9),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _isGridView
                                      ? AppColors.primary
                                      : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(9),
                              ),
                            ),
                            child: Icon(
                              Icons.grid_view_rounded,
                              size: 18,
                              color:
                                  _isGridView
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Builder(
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Divider(
                height: 1,
                thickness: 1.2,
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
              ),
            );
          },
        ),
      ],
    );
  }

  /// Banner card promoting "Order from another store" feature
  Widget _buildCustomStoreBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => CustomDialog.showOrderFromAnotherStoreDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isDark
                        ? [
                          AppColors.primary.withAlpha(40),
                          AppColors.primary.withAlpha(15),
                        ]
                        : [
                          AppColors.primary.withAlpha(20),
                          AppColors.primary.withAlpha(5),
                        ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withAlpha(60),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'اطلب من أي محل آخر',
                            style: AppFonts.cairoFont(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'قريباً',
                              style: AppFonts.cairoFont(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'اشتري من اي محل اخر؟ نوصّله لك من أي مكان 🛵',
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Persistent Header Delegate to keep Search Bar, Categories & Section Title pinned on scroll
class _StickyMenuHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyMenuHeaderDelegate({required this.child, this.height = 215.0});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color:
          isDark
              ? AppColors.darkBackground
              : Theme.of(context).scaffoldBackgroundColor,
      height: height,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyMenuHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
