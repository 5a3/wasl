import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../admin_app/providers/category_provider.dart';
import '../../../admin_app/providers/product_provider.dart';
import '../../../admin_app/providers/ad_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import 'product_details_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  int _currentAdPage = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
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
    final filteredProducts = prodProvider.products.where((product) {
      final matchesCategory = _selectedCategoryId == null ||
          product.mainCategoryId == _selectedCategoryId ||
          product.subCategoryId == _selectedCategoryId;

      final matchesSearch = _searchQuery.trim().isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.trim().toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.trim().toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ads Carousel Slider (using carousel_slider package)
          _buildCarouselAds(adProvider),

          // 2. Search Text Field
          _buildSearchBar(),

          // 3. Categories Circular Avatars List (shimmer and full cached image)
          _buildCategoriesAvatars(catProvider),

          // 4. Section Title & Product Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategoryId == null
                      ? 'جميع الأطباق والوجبات 🍔'
                      : '${catProvider.categories.firstWhere((c) => c.id == _selectedCategoryId).name} 🍲',
                  style: AppFonts.cairoFont(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'عدد الأصناف: ${filteredProducts.length}',
                  style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1),
          ),

          // 5. Memory-efficient Lazy Loading Products list
          Expanded(
            child: prodProvider.isLoading
                ? _buildShimmerProducts()
                : filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty ? 'لا توجد وجبات تطابق البحث 🔍' : 'لا توجد أصناف متوفرة في هذه الفئة',
                          style: AppFonts.cairoFont(fontSize: 14, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (ctx, index) {
                          final product = filteredProducts[index];
                          final isFav = favProvider.isFavorite(product.id);
                          final isInCart = cartProvider.items.containsKey(product.id);
                          final qty = isInCart ? cartProvider.items[product.id]!.quantity : 0;

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    // Product Image
                                    Hero(
                                      tag: 'product_image_${product.id}',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CustomCachedImage(
                                          imageUrl: product.images.isNotEmpty ? product.images.first : '',
                                          width: 85,
                                          height: 85,
                                          errorWidget: const Icon(Icons.fastfood, size: 36, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Product details
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
                                                  style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: Icon(
                                                  isFav ? Icons.favorite : Icons.favorite_border,
                                                  color: isFav ? AppColors.danger : Colors.grey,
                                                  size: 20,
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
                                            style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                Formatters.formatCurrency(product.price),
                                                style: AppFonts.cairoFont(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),

                                              // Interactive add counter
                                              if (product.isAvailable)
                                                Builder(
                                                  builder: (ctx) {
                                                    if (isInCart) {
                                                      return Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(),
                                                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 22),
                                                            onPressed: () {
                                                              cartProvider.decrementItem(product.id);
                                                            },
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            '$qty',
                                                            style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          IconButton(
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(),
                                                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
                                                            onPressed: () {
                                                              cartProvider.addToCart(product);
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    } else {
                                                      return ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppColors.primary,
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          minimumSize: Size.zero,
                                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        onPressed: () {
                                                          cartProvider.addToCart(product);
                                                          CustomDialog.showSuccessSnackBar(context, 'تم إضافة ${product.name} إلى السلة 🍔');
                                                        },
                                                        child: Text(
                                                          'إضافة للطلب',
                                                          style: AppFonts.cairoFont(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                )
                                              else
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6)),
                                                  child: Text(
                                                    'غير متوفر',
                                                    style: AppFonts.cairoFont(fontSize: 9, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
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
                          );
                        },
                      ),
          ),
        ],
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
              return Container(
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
                    errorWidget: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
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
                    color: _currentAdPage == index ? AppColors.primary : Colors.grey.shade400,
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
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          suffixIcon: _searchQuery.isNotEmpty
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
                      color: _selectedCategoryId == null ? AppColors.primary : (isDark ? AppColors.darkSurfaceLight : Colors.grey.shade100),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedCategoryId == null ? AppColors.primary : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: _selectedCategoryId == null
                          ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 6, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: 24,
                      color: _selectedCategoryId == null ? Colors.white : (isDark ? Colors.white : Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الكل',
                    style: AppFonts.cairoFont(
                      fontSize: 10,
                      fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                      color: _selectedCategoryId == null ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : Colors.black),
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
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          width: 2.0,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 6, offset: const Offset(0, 3))]
                            : [],
                      ),
                      child: ClipOval(
                        child: CustomCachedImage(
                          imageUrl: cat.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(Icons.fastfood, size: 24, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.name,
                      style: AppFonts.cairoFont(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : Colors.black),
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
        itemBuilder: (ctx, idx) => Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              children: [
                Container(width: 52, height: 52, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
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
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (ctx, idx) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Row(
              children: [
                Container(width: 85, height: 85, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 14, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(width: double.infinity, height: 12, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(width: 150, height: 12, color: Colors.white),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(width: 60, height: 16, color: Colors.white),
                          Container(width: 80, height: 26, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
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
}
