import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../admin_app/providers/ad_provider.dart';
import '../../../admin_app/providers/vendor_store_provider.dart';
import '../../../shared/models/ad_model.dart';
import '../../../shared/models/store_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VendorStoreProvider>(context, listen: false).fetchStores();
      Provider.of<AdProvider>(context, listen: false).fetchAds();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<VendorStoreProvider>(context);
    final adProvider = Provider.of<AdProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final query = _searchQuery.trim().toLowerCase();
    final stores = storeProvider.stores.where((store) {
      if (query.isEmpty) return true;
      final nameMatch = store.name.toLowerCase().contains(query);
      final descMatch = store.description?.toLowerCase().contains(query) ?? false;
      final addrMatch = store.address?.toLowerCase().contains(query) ?? false;
      return nameMatch || descMatch || addrMatch;
    }).toList();

    return CustomScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Ads Carousel Slider at top
        SliverToBoxAdapter(child: _buildCarouselAds(adProvider)),

        // 2. Custom Store Promo Banner Card ("اطلب من أي محل آخر")
        SliverToBoxAdapter(child: _buildCustomStoreBanner(context)),

        // 3. Search Bar for Stores & Header Title
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'المطاعم والمتاجر المتاحة 🏬',
                          style: AppFonts.cairoFont(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${stores.length} مطعم',
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                      query.isNotEmpty
                          ? 'لا توجد مطاعم أو متاجر تطابق البحث "$query"'
                          : 'لا تتوفر مطاعم أو متاجر حالياً',
                      style: AppFonts.cairoFont(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, index) {
                  final store = stores[index];
                  return _buildStoreCard(context, store, isDark);
                },
                childCount: stores.length,
              ),
            ),
          ),
      ],
    );
  }

  /// Modern Store Card with Cover Image, Logo, Address, Rating, and Status Badge
  Widget _buildStoreCard(BuildContext context, StoreModel store, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoreMenuScreen(store: store),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Cover & Status Badge & Logo Overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: AppColors.primary.withAlpha(20),
                    child: store.coverUrl != null && store.coverUrl!.isNotEmpty
                        ? CustomCachedImage(
                            imageUrl: store.coverUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 130,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withAlpha(120),
                                  AppColors.primary.withAlpha(50),
                                ],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.storefront, size: 50, color: Colors.white),
                            ),
                          ),
                  ),
                ),

                // Gradient overlay over cover image
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(60),
                          Colors.transparent,
                          Colors.black.withAlpha(90),
                        ],
                      ),
                    ),
                  ),
                ),

                // Store Open/Closed Badge (Top Left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: store.isOpen ? Colors.green.shade600 : AppColors.danger,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          store.isOpen ? 'مفتوح 🟢' : 'مغلق 🔴',
                          style: AppFonts.cairoFont(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Rating Badge (Top Right)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: AppFonts.cairoFont(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Store Logo Avatar (Overlapping bottom left of cover)
                Positioned(
                  bottom: -24,
                  right: 16,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                          ? CustomCachedImage(
                              imageUrl: store.logoUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppColors.primary.withAlpha(30),
                              child: const Icon(Icons.store, color: AppColors.primary, size: 28),
                            ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Store Info Details
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: AppFonts.cairoFont(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (store.address != null && store.address!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store.address!,
                            style: AppFonts.cairoFont(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (store.description != null && store.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      store.description!,
                      style: AppFonts.cairoFont(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تصفح القائمة والوجبات',
                        style: AppFonts.cairoFont(
                          fontSize: 12.5,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'دخول المطعم',
                              style: AppFonts.cairoFont(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ],
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
  }

  /// Modern search bar for stores
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final fillColor = isDark ? AppColors.darkSurfaceLight : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'ابحث عن مطعم، كافيه، أو متجر...',
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
      ),
    );
  }

  /// Package based ads carousel
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

  /// Banner card promoting "Order from another store" feature
  Widget _buildCustomStoreBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                colors: isDark
                    ? [AppColors.primary.withAlpha(40), AppColors.primary.withAlpha(15)]
                    : [AppColors.primary.withAlpha(20), AppColors.primary.withAlpha(5)],
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
                    Icons.two_wheeler_rounded,
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
                        'تبي شيء من محل غير موجود؟ نوصّله لك فوراً 🛵',
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
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

  /// Full screen ad preview
  void _showAdFullPreview(BuildContext context, AdModel ad) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
