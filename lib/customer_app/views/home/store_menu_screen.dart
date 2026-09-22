import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../../admin_app/providers/category_provider.dart';
import '../../../admin_app/providers/product_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/store_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../utils/cart_helper.dart';
import 'product_details_screen.dart';

class StoreMenuScreen extends StatefulWidget {
  final StoreModel store;

  const StoreMenuScreen({super.key, required this.store});

  @override
  State<StoreMenuScreen> createState() => _StoreMenuScreenState();
}

class _StoreMenuScreenState extends State<StoreMenuScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
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
          _isGridView = prefs.getBool('store_menu_is_grid_view') ?? false;
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
      await prefs.setBool('store_menu_is_grid_view', isGrid);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAddToCart(ProductModel product, CategoryModel? category) async {
    if (!product.isAvailable) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، هذا الصنف غير متوفر حالياً 🔴');
      return;
    }

    await CartHelper.checkAndAddToCart(
      context: context,
      product: product,
      category: category,
      showSnackBarOnSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catProvider = Provider.of<CategoryProvider>(context);
    final prodProvider = Provider.of<ProductProvider>(context);
    final favProvider = Provider.of<FavoriteProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    // Get categories belonging to this store or global
    final storeCategories = catProvider.categories.where((c) =>
      c.storeId == widget.store.id || c.storeId == null
    ).toList();

    // Filter products for this store
    final storeProducts = prodProvider.products.where((p) {
      final matchesStore = p.storeId == widget.store.id || p.storeId == null;
      final matchesCategory = _selectedCategoryId == null ||
          p.mainCategoryId == _selectedCategoryId ||
          p.subCategoryId == _selectedCategoryId;
      final matchesSearch = _searchQuery.trim().isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.trim().toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.trim().toLowerCase());

      return matchesStore && matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header Cover, Logo & Status Badge
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withAlpha(140),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.store.name,
                style: AppFonts.cairoFont(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.store.coverUrl != null && widget.store.coverUrl!.isNotEmpty
                      ? CustomCachedImage(imageUrl: widget.store.coverUrl!, fit: BoxFit.cover)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withAlpha(150),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.storefront, size: 60, color: Colors.white),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(80),
                          Colors.transparent,
                          Colors.black.withAlpha(180),
                        ],
                      ),
                    ),
                  ),

                  // Store Status Badge
                  Positioned(
                    top: 40,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.store.isOpen ? Colors.green.shade600 : AppColors.danger,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Text(
                        widget.store.isOpen ? 'مفتوح 🟢' : 'مغلق 🔴',
                        style: AppFonts.cairoFont(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Store Logo Circle
                  if (widget.store.logoUrl != null && widget.store.logoUrl!.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 6),
                          ],
                        ),
                        child: ClipOval(
                          child: CustomCachedImage(imageUrl: widget.store.logoUrl!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Store Info Header Bar (Description, Phone, Address)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              color: isDark ? AppColors.darkSurface : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.store.name,
                          style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              widget.store.rating.toStringAsFixed(1),
                              style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (widget.store.address != null && widget.store.address!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.store.address!,
                            style: AppFonts.cairoFont(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (widget.store.phone != null && widget.store.phone!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          widget.store.phone!,
                          style: AppFonts.cairoFont(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],

                  if (widget.store.description != null && widget.store.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.store.description!,
                      style: AppFonts.cairoFont(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Sticky Search Bar & Category Navigation Bar (Pinned Header)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyStoreHeaderDelegate(
              height: storeCategories.isNotEmpty ? 156.0 : 62.0,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 10),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search Bar inside Store
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: AppFonts.cairoFont(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن وجبة أو صنف في ${widget.store.name}...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            isDense: true,
                            fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),

                      // Store Categories Avatars Circular Row (أقسام المطعم بالصور)
                      if (storeCategories.isNotEmpty)
                        SizedBox(
                          height: 88,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            children: [
                              // "All" option
                              GestureDetector(
                                onTap: () => setState(() => _selectedCategoryId = null),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 14),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _selectedCategoryId == null
                                              ? AppColors.primary
                                              : (isDark ? AppColors.darkSurfaceLight : Colors.grey.shade100),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _selectedCategoryId == null ? AppColors.primary : Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.grid_view_rounded,
                                          size: 22,
                                          color: _selectedCategoryId == null ? Colors.white : (isDark ? Colors.white : Colors.grey.shade700),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'الكل',
                                        style: AppFonts.cairoFont(
                                          fontSize: 10,
                                          fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                                          color: _selectedCategoryId == null ? AppColors.primary : (isDark ? Colors.white : Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Categories with Images
                              ...storeCategories.map((cat) {
                                final isSelected = _selectedCategoryId == cat.id;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedCategoryId = cat.id),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                              width: 2.0,
                                            ),
                                            boxShadow: isSelected
                                                ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 6)]
                                                : [],
                                          ),
                                          child: ClipOval(
                                            child: CustomCachedImage(
                                              imageUrl: cat.imageUrl,
                                              width: 46,
                                              height: 46,
                                              fit: BoxFit.cover,
                                              errorWidget: const Icon(Icons.fastfood, size: 22, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          cat.name,
                                          style: AppFonts.cairoFont(
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? AppColors.primary : (isDark ? Colors.white : Colors.black),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Section Title & List/Grid View Switcher
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fastfood, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCategoryId == null
                            ? 'أصناف ووجبات المطعم'
                            : (storeCategories.any((c) => c.id == _selectedCategoryId)
                                ? storeCategories.firstWhere((c) => c.id == _selectedCategoryId).name
                                : 'الوجبات'),
                        style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${storeProducts.length} وجبة',
                          style: AppFonts.cairoFont(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // View Mode Switcher
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceLight : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _toggleViewMode(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: !_isGridView ? AppColors.primary : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                ),
                                child: Icon(Icons.view_list, size: 16, color: !_isGridView ? Colors.white : Colors.grey),
                              ),
                            ),
                            InkWell(
                              onTap: () => _toggleViewMode(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _isGridView ? AppColors.primary : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                ),
                                child: Icon(Icons.grid_view, size: 16, color: _isGridView ? Colors.white : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Products List / Grid
          prodProvider.isLoading
              ? SliverToBoxAdapter(child: _buildShimmerProducts())
              : storeProducts.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          _searchQuery.isNotEmpty ? 'لا توجد وجبات تطابق البحث' : 'لا تتوفر وجبات تابعة لهذا القسم حالياً',
                          style: AppFonts.cairoFont(color: Colors.grey),
                        ),
                      ),
                    )
                  : _isGridView
                      ? Builder(
                          builder: (context) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final crossAxisCount = screenWidth >= 900 ? 4 : (screenWidth >= 600 ? 3 : 2);
                            final childAspectRatio = screenWidth < 360
                                ? 0.54
                                : (screenWidth < 400 ? 0.57 : (screenWidth >= 600 ? 0.72 : 0.60));

                            return SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, index) {
                                    final product = storeProducts[index];
                                    final category = catProvider.getCategoryById(product.mainCategoryId);
                                    final isFav = favProvider.isFavorite(product.id);
                                    final isInCart = cartProvider.items.containsKey(product.id);
                                    final qty = isInCart ? cartProvider.items[product.id]!.quantity : 0;

                                    return _buildGridProductCard(
                                      product,
                                      isFav,
                                      isInCart,
                                      qty,
                                      isDark,
                                      favProvider,
                                      cartProvider,
                                      category,
                                    );
                                  },
                                  childCount: storeProducts.length,
                                ),
                              ),
                            );
                          },
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = storeProducts[index];
                                final category = catProvider.getCategoryById(product.mainCategoryId);
                                final isFav = favProvider.isFavorite(product.id);
                                final isInCart = cartProvider.items.containsKey(product.id);
                                final qty = isInCart ? cartProvider.items[product.id]!.quantity : 0;
                                final effectivePrice = product.getEffectivePrice(category);
                                final hasDiscount = product.hasEffectiveDiscount(category);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 2,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailsScreen(product: product),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          // Image with discount badge & unavailable overlay
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: product.images.isNotEmpty
                                                    ? CustomCachedImage(imageUrl: product.images.first, width: 85, height: 85)
                                                    : Container(width: 85, height: 85, color: Colors.grey.shade200, child: const Icon(Icons.fastfood)),
                                              ),
                                              if (hasDiscount)
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
                                                      style: AppFonts.cairoFont(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              if (!widget.store.isOpen || !product.isAvailable)
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withAlpha(150),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'غير متوفر 🔴',
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
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 15),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (product.description.isNotEmpty)
                                                  Text(
                                                    product.description,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey),
                                                  ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Text(
                                                      Formatters.formatCurrency(effectivePrice),
                                                      style: AppFonts.cairoFont(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                                                    ),
                                                    if (hasDiscount) ...[
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        Formatters.formatCurrency(product.price),
                                                        style: AppFonts.cairoFont(
                                                          decoration: TextDecoration.lineThrough,
                                                          color: Colors.grey,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Actions
                                          Column(
                                            children: [
                                              IconButton(
                                                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? AppColors.danger : Colors.grey),
                                                onPressed: () => favProvider.toggleFavorite(product.id),
                                              ),
                                              if (!widget.store.isOpen || !product.isAvailable)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.danger.withAlpha(20),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: AppColors.danger.withAlpha(40)),
                                                  ),
                                                  child: Text(
                                                    'غير متوفر',
                                                    style: AppFonts.cairoFont(
                                                      fontSize: 10,
                                                      color: AppColors.danger,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                              else if (isInCart)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    InkWell(
                                                      onTap: () => cartProvider.decrementItem(product.id),
                                                      child: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                                      child: Text('$qty', style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
                                                    ),
                                                    InkWell(
                                                      onTap: () => _onAddToCart(product, category),
                                                      child: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                                                    ),
                                                  ],
                                                )
                                              else
                                                IconButton(
                                                  icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                                                  onPressed: widget.store.isOpen ? () => _onAddToCart(product, category) : null,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: storeProducts.length,
                            ),
                          ),
                        ),
        ],
      ),
    );
  }

  /// Grid Product Card
  Widget _buildGridProductCard(
    ProductModel product,
    bool isFav,
    bool isInCart,
    int qty,
    bool isDark,
    FavoriteProvider favProvider,
    CartProvider cartProvider,
    CategoryModel? category,
  ) {
    final hasDisc = product.hasEffectiveDiscount(category);
    final effectivePrice = product.getEffectivePrice(category);

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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  child: CustomCachedImage(
                    imageUrl: product.images.isNotEmpty ? product.images.first : '',
                    width: double.infinity,
                    height: 125,
                    fit: BoxFit.cover,
                    errorWidget: const Icon(Icons.fastfood, size: 36, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withAlpha(190),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppColors.danger : Colors.grey.shade500,
                        size: 18,
                      ),
                      onPressed: () => favProvider.toggleFavorite(product.id),
                    ),
                  ),
                ),
                if (hasDisc)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🔥 ${product.getDiscountBadgeText(category)}',
                        style: AppFonts.cairoFont(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (isInCart)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Text(
                        '$qty بالسلة 🛒',
                        style: AppFonts.cairoFont(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (!widget.store.isOpen || !product.isAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                      ),
                      child: Center(
                        child: Text(
                          'غير متوفر 🔴',
                          style: AppFonts.cairoFont(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
                          style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.description,
                          style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Formatters.formatCurrency(effectivePrice),
                                style: AppFonts.cairoFont(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasDisc)
                                Text(
                                  Formatters.formatCurrency(product.price),
                                  style: AppFonts.cairoFont(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (!product.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'غير متوفر',
                              style: AppFonts.cairoFont(fontSize: 9.5, color: AppColors.danger, fontWeight: FontWeight.bold),
                            ),
                          )
                        else if (isInCart)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => cartProvider.decrementItem(product.id),
                                  child: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 18),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
                                  onTap: widget.store.isOpen ? () => _onAddToCart(product, category) : null,
                                  child: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
                                ),
                              ],
                            ),
                          )
                        else
                          InkWell(
                            onTap: widget.store.isOpen ? () => _onAddToCart(product, category) : null,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_shopping_cart, size: 16, color: Colors.white),
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
    );
  }

  /// Shimmer products loader
  Widget _buildShimmerProducts() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 3,
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

class _StickyStoreHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyStoreHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyStoreHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
