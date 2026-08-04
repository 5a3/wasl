import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_auth_provider.dart';
import '../../providers/customer_notification_provider.dart';
import '../../providers/customer_order_provider.dart';
import '../../widgets/customer_drawer.dart';
import '../notifications/customer_notifications_screen.dart';
import '../cart/cart_screen.dart';
import '../favorites/favorites_screen.dart';
import '../my_orders/customer_orders_screen.dart';
import '../../../core/services/fcm_service.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/custom_dialog.dart';
import 'menu_screen.dart';
import '../../../shared/providers/store_provider.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerNotificationProvider>(context, listen: false).fetchNotifications();
      final customer = Provider.of<CustomerAuthProvider>(context, listen: false).currentCustomer;
      if (customer != null) {
        Provider.of<CustomerOrderProvider>(context, listen: false).listenToCustomerOrders(customer.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final notificationProvider = Provider.of<CustomerNotificationProvider>(context);
    final customerOrderProvider = Provider.of<CustomerOrderProvider>(context);
    final customerAuth = Provider.of<CustomerAuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customer = customerAuth.currentCustomer;
    final fullName = customer?.fullName.trim() ?? '';
    final firstName = fullName.isNotEmpty ? fullName.split(' ').first : 'العميل';

    String appBarTitle;
    switch (_currentIndex) {
      case 0:
        appBarTitle = 'مرحباً، $firstName';
        break;
      case 1:
        appBarTitle = 'الأطباق المفضلة';
        break;
      case 2:
        appBarTitle = 'سلة الطلبات';
        break;
      case 3:
        appBarTitle = 'طلباتي ومتابعة الشحن';
        break;
      default:
        appBarTitle = 'مرحباً، $firstName';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirm = await CustomDialog.showConfirmDialog(
          context: context,
          title: 'الخروج من التطبيق 🚪',
          message: 'هل تريد حقاً الخروج من تطبيق وصل لي؟',
          confirmText: 'خروج',
          cancelText: 'إلغاء',
          confirmColor: AppColors.danger,
        );
        if (confirm == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const CustomerDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 26),
            tooltip: 'القائمة الرئيسية',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          appBarTitle,
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          // Instant Notification Action Button with Badge (No lag!)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                tooltip: 'الإشعارات',
                onPressed: () async {
                  final allowed = await FcmService.ensurePermissionWithDialog(context);
                  if (allowed && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerNotificationsScreen(),
                      ),
                    );
                  }
                },
              ),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      notificationProvider.unreadCount > 99
                          ? '99+'
                          : '+${notificationProvider.unreadCount}',
                      textAlign: TextAlign.center,
                      style: AppFonts.cairoFont(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  setState(() {
                    _currentIndex = 2; // Jump to Cart
                  });
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cartProvider.itemCount}',
                      textAlign: TextAlign.center,
                      style: AppFonts.cairoFont(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: BottomBar(
        barColor: isDark ? Colors.grey.shade900 : AppColors.primary,
        borderRadius: BorderRadius.circular(30),
        width: MediaQuery.of(context).size.width - 32,
        hideOnScroll: true,
        body: (context, controller) {
          final storeProvider = Provider.of<StoreProvider>(context);

          Widget activeScreen;
          switch (_currentIndex) {
            case 0:
              activeScreen = MenuScreen(scrollController: controller);
              break;
            case 1:
              activeScreen = FavoritesScreen(scrollController: controller);
              break;
            case 2:
              activeScreen = CartScreen(
                scrollController: controller,
                onOrderPlaced: () {
                  setState(() {
                    _currentIndex = 3; // Switch to My Orders tab
                  });
                },
              );
              break;
            case 3:
              activeScreen = CustomerOrdersScreen(scrollController: controller);
              break;
            default:
              activeScreen = MenuScreen(scrollController: controller);
          }

          if (!storeProvider.isOpen) {
            return Column(
              children: [
                // Store Closed Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withAlpha(60),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'المطعم مغلق حالياً 🔴',
                              style: AppFonts.cairoFont(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              storeProvider.closedReason ?? 'يسعدنا خدمتكم واستقبال طلباتكم في أوقات العمل الرسمية.',
                              style: AppFonts.cairoFont(
                                color: Colors.white.withAlpha(230),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: activeScreen),
              ],
            );
          }

          return activeScreen;
        },
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'القائمة'),
              _buildNavItem(1, Icons.favorite_outline, Icons.favorite, 'المفضلة'),
              _buildCartNavItem(cartProvider),
              _buildOrdersNavItem(customerOrderProvider),
            ],
          ),
        ),
      ),
    ),
  );
}

  /// Special navigation item for My Orders with active orders count badge
  Widget _buildOrdersNavItem(CustomerOrderProvider orderProvider) {
    final isSelected = _currentIndex == 3;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color selectedColor = isDark ? AppColors.primary : Colors.white;
    final Color unselectedColor = isDark ? Colors.grey.shade400 : Colors.white.withAlpha(170);

    final Color badgeBgColor = isDark ? AppColors.primary : Colors.white;
    final Color badgeTextColor = isDark ? Colors.white : AppColors.primary;

    final activeCount = orderProvider.myActiveOrders.length;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 3;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? Icons.delivery_dining : Icons.delivery_dining_outlined,
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 22,
                ),
                if (activeCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$activeCount',
                        textAlign: TextAlign.center,
                        style: AppFonts.cairoFont(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'طلباتي',
              style: AppFonts.cairoFont(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds navigation item for general tabs with dynamic theme color contrasts
  Widget _buildNavItem(int index, IconData outlineIcon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color selectedColor = isDark ? AppColors.primary : Colors.white;
    final Color unselectedColor = isDark ? Colors.grey.shade400 : Colors.white.withAlpha(170);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : outlineIcon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppFonts.cairoFont(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Special navigation item for the Cart with badge overlay
  Widget _buildCartNavItem(CartProvider cartProvider) {
    final isSelected = _currentIndex == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color selectedColor = isDark ? AppColors.primary : Colors.white;
    final Color unselectedColor = isDark ? Colors.grey.shade400 : Colors.white.withAlpha(170);

    final Color badgeBgColor = isDark ? AppColors.primary : Colors.white;
    final Color badgeTextColor = isDark ? Colors.white : AppColors.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 22,
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '${cartProvider.itemCount}',
                        textAlign: TextAlign.center,
                        style: AppFonts.cairoFont(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'السلة',
              style: AppFonts.cairoFont(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
