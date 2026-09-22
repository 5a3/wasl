import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../admin_app/providers/ad_provider.dart';
import '../../../admin_app/providers/category_provider.dart';
import '../../../admin_app/providers/city_provider.dart';
import '../../../admin_app/providers/store_category_provider.dart';
import '../../../admin_app/providers/vendor_store_provider.dart';
import '../../../shared/models/ad_model.dart';
import '../../../shared/models/store_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_cached_image.dart';
import 'store_menu_screen.dart';

class MenuScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const MenuScreen({super.key, this.scrollController});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _searchQuery = '';
  int _currentAdPage = 0;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedCityId;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VendorStoreProvider>(context, listen: false).fetchStores();
      Provider.of<AdProvider>(context, listen: false).fetchAds();
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      Provider.of<CityProvider>(context, listen: false).fetchCities();
      Provider.of<StoreCategoryProvider>(context, listen: false).fetchStoreCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String? tempCategoryId = _selectedCategoryId;
        String? tempCityId = _selectedCityId;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final storeCategoryProvider = Provider.of<StoreCategoryProvider>(context);
            final cityProvider = Provider.of<CityProvider>(context);
            final storeCats = storeCategoryProvider.storeCategories;
            final cities = cityProvider.cities;

            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.filter_list_rounded, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'تصفية وفلترة المطاعم 🎯',
                            style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Filter by Store Category (نوع المطعم / القسم)
                  Text(
                    'نوع المحل / القسم:',
                    style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: storeCats.any((c) => c.id == tempCategoryId) ? tempCategoryId : null,
                    decoration: InputDecoration(
                      hintText: 'جميع الأقسام والأنواع',
                      prefixIcon: const Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('جميع الأقسام (الكل)', style: AppFonts.cairoFont()),
                      ),
                      ...storeCats.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name, style: AppFonts.cairoFont()),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        tempCategoryId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filter by City (المدينة)
                  Text(
                    'مدينة المطعم:',
                    style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: cities.any((c) => c.id == tempCityId) ? tempCityId : null,
                    decoration: InputDecoration(
                      hintText: 'جميع المدن',
                      prefixIcon: const Icon(Icons.location_city_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('جميع المدن (الكل)', style: AppFonts.cairoFont()),
                      ),
                      ...cities.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name, style: AppFonts.cairoFont()),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        tempCityId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCategoryId = null;
                              _selectedCityId = null;
                            });
                            Navigator.of(ctx).pop();
                          },
                          child: Text('إعادة ضبط', style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCategoryId = tempCategoryId;
                              _selectedCityId = tempCityId;
                            });
                            Navigator.of(ctx).pop();
                          },
                          child: Text('تطبيق الفلترة', style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<VendorStoreProvider>(context);
    final adProvider = Provider.of<AdProvider>(context);
    final cityProvider = Provider.of<CityProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final query = _searchQuery.trim().toLowerCase();
    final stores = storeProvider.stores.where((store) {
      if (query.isNotEmpty) {
        final nameMatch = store.name.toLowerCase().contains(query);
        final descMatch = store.description?.toLowerCase().contains(query) ?? false;
        final addrMatch = store.address?.toLowerCase().contains(query) ?? false;
        final catMatch = store.storeCategoryName?.toLowerCase().contains(query) ?? false;
        final cityMatch = store.cityName?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !descMatch && !addrMatch && !catMatch && !cityMatch) return false;
      }
      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        if (store.storeCategoryId != _selectedCategoryId) return false;
      }
      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) {
        if (store.cityId != _selectedCityId) return false;
      }
      return true;
    }).toList();

    final activeFilterCount = (_selectedCategoryId != null ? 1 : 0) + (_selectedCityId != null ? 1 : 0);

    final headerHeight = activeFilterCount > 0 ? 154.0 : 112.0;

    return CustomScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Ads Carousel Slider at top (scrolls away on scroll)
        SliverToBoxAdapter(child: _buildCarouselAds(adProvider)),

        // 2. Search Bar & Stores Header (Pinned at top when scrolling)
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            height: headerHeight,
            child: _buildPinnedHeader(
              context,
              isDark,
              activeFilterCount,
              stores,
              cityProvider,
            ),
          ),
        ),

        // 4. Stores List / Grid
        if (storeProvider.isLoading && storeProvider.stores.isEmpty)
          SliverToBoxAdapter(child: _buildShimmerStores())
        else if (stores.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 64,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      query.isNotEmpty || activeFilterCount > 0
                          ? 'لا توجد مطاعم تابعة لهذا الخيار أو البحث'
                          : 'لا تتوفر مطاعم أو متاجر حالياً',
                      style: AppFonts.cairoFont(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_isGridView)
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount = screenWidth >= 900 ? 4 : (screenWidth >= 600 ? 3 : 2);
              final childAspectRatio = screenWidth < 360
                  ? 0.78
                  : (screenWidth < 400 ? 0.84 : (screenWidth >= 600 ? 0.98 : 0.86));

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      final store = stores[index];
                      return _buildStoreGridCard(context, store, isDark);
                    },
                    childCount: stores.length,
                  ),
                ),
              );
            },
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, index) {
                  final store = stores[index];
                  return _buildStoreListCard(context, store, isDark);
                },
                childCount: stores.length,
              ),
            ),
          ),
      ],
    );
  }

  /// Compact List View Store Card (~110px height)
  Widget _buildStoreListCard(BuildContext context, StoreModel store, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
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
      child: InkWell(
        onTap: () {
          if (!store.isOpen) {
            _showStoreClosedDialog(context, store);
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoreMenuScreen(store: store),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Store Logo / Cover Avatar with Rating Overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 85,
                      height: 85,
                      color: AppColors.primary.withAlpha(20),
                      child: !store.isOpen
                          ? ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.grey,
                                BlendMode.saturation,
                              ),
                              child: Stack(
                                children: [
                                  store.logoUrl != null && store.logoUrl!.isNotEmpty
                                      ? CustomCachedImage(imageUrl: store.logoUrl!, fit: BoxFit.cover)
                                      : (store.coverUrl != null && store.coverUrl!.isNotEmpty
                                          ? CustomCachedImage(imageUrl: store.coverUrl!, fit: BoxFit.cover)
                                          : Container(
                                              color: AppColors.primary.withAlpha(30),
                                              child: const Icon(Icons.storefront, color: AppColors.primary, size: 36),
                                            )),
                                  Container(color: Colors.black.withAlpha(90)),
                                ],
                              ),
                            )
                          : (store.logoUrl != null && store.logoUrl!.isNotEmpty
                              ? CustomCachedImage(imageUrl: store.logoUrl!, fit: BoxFit.cover)
                              : (store.coverUrl != null && store.coverUrl!.isNotEmpty
                                  ? CustomCachedImage(imageUrl: store.coverUrl!, fit: BoxFit.cover)
                                  : Container(
                                      color: AppColors.primary.withAlpha(30),
                                      child: const Icon(Icons.storefront, color: AppColors.primary, size: 36),
                                    ))),
                    ),
                  ),
                  if (!store.isOpen)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'مغلق 🔴',
                            style: AppFonts.cairoFont(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Single Decimal Precision Rating Badge (⭐ 4.8)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            store.rating.toStringAsFixed(1),
                            style: AppFonts.cairoFont(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: AppFonts.cairoFont(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: store.isOpen ? Colors.green.withAlpha(25) : AppColors.danger.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            store.isOpen ? 'مفتوح 🟢' : 'مغلق 🔴',
                            style: AppFonts.cairoFont(
                              color: store.isOpen ? Colors.green.shade700 : AppColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Category & City Badges
                    Wrap(
                      spacing: 5,
                      runSpacing: 2,
                      children: [
                        if (store.storeCategoryName != null && store.storeCategoryName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              store.storeCategoryName!,
                              style: AppFonts.cairoFont(fontSize: 9.5, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (store.cityName != null && store.cityName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(20),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              store.cityName!,
                              style: AppFonts.cairoFont(fontSize: 9.5, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    if (store.description != null && store.description!.isNotEmpty)
                      Text(
                        store.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_left_rounded, color: isDark ? Colors.grey : Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact Grid View Store Card (2 Columns)
  Widget _buildStoreGridCard(BuildContext context, StoreModel store, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
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
      child: InkWell(
        onTap: () {
          if (!store.isOpen) {
            _showStoreClosedDialog(context, store);
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoreMenuScreen(store: store),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image + Rating & Status Badges
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 95,
                    width: double.infinity,
                    color: AppColors.primary.withAlpha(20),
                    child: !store.isOpen
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                            child: Stack(
                              children: [
                                store.coverUrl != null && store.coverUrl!.isNotEmpty
                                    ? CustomCachedImage(imageUrl: store.coverUrl!, fit: BoxFit.cover)
                                    : (store.logoUrl != null && store.logoUrl!.isNotEmpty
                                        ? CustomCachedImage(imageUrl: store.logoUrl!, fit: BoxFit.cover)
                                        : Container(
                                            color: AppColors.primary.withAlpha(40),
                                            child: const Icon(Icons.storefront, color: AppColors.primary, size: 36),
                                          )),
                                Container(color: Colors.black.withAlpha(90)),
                              ],
                            ),
                          )
                        : (store.coverUrl != null && store.coverUrl!.isNotEmpty
                            ? CustomCachedImage(imageUrl: store.coverUrl!, fit: BoxFit.cover)
                            : (store.logoUrl != null && store.logoUrl!.isNotEmpty
                                ? CustomCachedImage(imageUrl: store.logoUrl!, fit: BoxFit.cover)
                                : Container(
                                    color: AppColors.primary.withAlpha(40),
                                    child: const Icon(Icons.storefront, color: AppColors.primary, size: 36),
                                  ))),
                  ),
                ),
                if (!store.isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Text(
                          'مغلق 🔴',
                          style: AppFonts.cairoFont(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Rating Badge (⭐ 4.8) Top Right
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(170),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: AppFonts.cairoFont(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Open/Closed Tag Top Left
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: store.isOpen ? Colors.green.shade600 : AppColors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      store.isOpen ? 'مفتوح' : 'مغلق',
                      style: AppFonts.cairoFont(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Logo Avatar Overlap
                Positioned(
                  bottom: -16,
                  right: 10,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: ClipOval(
                      child: !store.isOpen
                          ? ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.grey,
                                BlendMode.saturation,
                              ),
                              child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                                  ? CustomCachedImage(imageUrl: store.logoUrl!, fit: BoxFit.cover)
                                  : const Icon(Icons.store, color: AppColors.primary, size: 20),
                            )
                          : (store.logoUrl != null && store.logoUrl!.isNotEmpty
                              ? CustomCachedImage(imageUrl: store.logoUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.store, color: AppColors.primary, size: 20)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Card Text Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: AppFonts.cairoFont(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      if (store.storeCategoryName != null && store.storeCategoryName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            store.storeCategoryName!,
                            style: AppFonts.cairoFont(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (store.cityName != null && store.cityName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            store.cityName!,
                            style: AppFonts.cairoFont(fontSize: 9, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  if (store.description != null && store.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      store.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.cairoFont(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreClosedDialog(BuildContext context, StoreModel store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: AppColors.danger),
            const SizedBox(width: 8),
            Text('المطعم مغلق حالياً 🔴', style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'عذراً، مطعم "${store.name}" مغلق حالياً ولا يستقبل أي طلبات جديدة. يرجى محاولة الطلب لاحقاً.',
          style: AppFonts.cairoFont(fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('حسناً، فهمت', style: AppFonts.cairoFont(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Modern search bar for stores
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final fillColor = isDark ? AppColors.darkSurfaceLight : Colors.white;

    return TextField(
      controller: _searchController,
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
        });
      },
      style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'ابحث عن مطعم، قسم، مدينة...',
        hintStyle: AppFonts.cairoFont(
          color: hintColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(Icons.search, size: 20, color: iconColor),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 18, color: hintColor),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
      ),
    );
  }

  /// Package based ads carousel
  Widget _buildCarouselAds(AdProvider adProvider) {
    final activeAds = adProvider.activeAds;
    if (activeAds.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Dynamic responsive height based on screen size (~16:7 aspect ratio, clamped 180 to 280)
    final carouselHeight = (screenWidth * 0.45).clamp(180.0, 280.0);
    final horizontalMargin = (screenWidth * 0.04).clamp(12.0, 20.0);

    return Container(
      margin: EdgeInsets.fromLTRB(horizontalMargin, 12, horizontalMargin, 8),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: activeAds.length,
            options: CarouselOptions(
              height: carouselHeight,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: activeAds.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              onPageChanged: (index, reason) {
                setState(() {
                  _currentAdPage = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final ad = activeAds[index];
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () {
                      if (ad.imageUrl.isNotEmpty) {
                        _showAdPreviewDialog(ad);
                      }
                    },
                    child: CustomCachedImage(
                      imageUrl: ad.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: AppColors.primary.withAlpha(30),
                        child: const Icon(Icons.campaign, size: 40, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (activeAds.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: activeAds.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentAdPage == entry.key ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentAdPage == entry.key
                        ? AppColors.primary
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showAdPreviewDialog(AdModel ad) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 450, maxWidth: 350),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
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

  /// Pinned Header containing Search Bar, Filters & Stores Title Header
  Widget _buildPinnedHeader(
    BuildContext context,
    bool isDark,
    int activeFilterCount,
    List<StoreModel> stores,
    CityProvider cityProvider,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Search Bar & Filter Button
        Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _buildSearchBar()),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: activeFilterCount > 0 ? AppColors.primary : (isDark ? AppColors.darkSurface : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: activeFilterCount > 0 ? AppColors.primary : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: activeFilterCount > 0 ? Colors.white : (isDark ? Colors.white : Colors.grey.shade800),
                          ),
                          onPressed: () => _showFilterBottomSheet(context),
                          tooltip: 'فلترة حسب المدينة أو القسم',
                        ),
                      ),
                      if (activeFilterCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$activeFilterCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (activeFilterCount > 0) ...[
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_selectedCategoryId != null) ...[
                        Builder(builder: (context) {
                          final storeCategoryProvider = Provider.of<StoreCategoryProvider>(context);
                          final catName = storeCategoryProvider.storeCategories.any((c) => c.id == _selectedCategoryId)
                              ? storeCategoryProvider.storeCategories.firstWhere((c) => c.id == _selectedCategoryId).name
                              : 'محدد';
                          return Chip(
                            avatar: const Icon(Icons.category, size: 14, color: Colors.white),
                            label: Text('القسم: $catName', style: AppFonts.cairoFont(fontSize: 11, color: Colors.white)),
                            backgroundColor: AppColors.primary,
                            deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                            onDeleted: () => setState(() => _selectedCategoryId = null),
                          );
                        }),
                        const SizedBox(width: 8),
                      ],
                      if (_selectedCityId != null) ...[
                        Builder(builder: (context) {
                          final cityName = cityProvider.cities
                              .firstWhere((c) => c.id == _selectedCityId, orElse: () => cityProvider.cities.first)
                              .name;
                          return Chip(
                            avatar: const Icon(Icons.location_city, size: 14, color: Colors.white),
                            label: Text('المدينة: $cityName', style: AppFonts.cairoFont(fontSize: 11, color: Colors.white)),
                            backgroundColor: Colors.blue.shade700,
                            deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                            onDeleted: () => setState(() => _selectedCityId = null),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // 2. Stores Header Title, Count & View Toggle Switch
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    'المطاعم والمتاجر 🏬',
                    style: AppFonts.cairoFont(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${stores.length}',
                      style: AppFonts.cairoFont(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // Mode Toggle Button (Grid / List Icons Only)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isGridView = false),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: !_isGridView ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.view_list_rounded,
                          size: 18,
                          color: !_isGridView ? Colors.white : (isDark ? Colors.grey : Colors.grey.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () => setState(() => _isGridView = true),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isGridView ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          size: 18,
                          color: _isGridView ? Colors.white : (isDark ? Colors.grey : Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Shimmer loading placeholder for stores
  Widget _buildShimmerStores() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (ctx, idx) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 140, height: 16, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 200, height: 12, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Persistent Header Delegate for Sticky Search & Store Navigation Bar
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          height: height,
          child: child,
        ),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
