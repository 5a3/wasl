import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/theme/theme_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/order_management_provider.dart';
import '../categories/admin_categories_screen.dart';
import '../delivery_zones/admin_delivery_zones_screen.dart';
import '../orders/admin_orders_screen.dart';
import '../products/admin_products_screen.dart';
import '../reports/admin_reports_screen.dart';
import '../sub_admins/admin_sub_admins_screen.dart';
import '../ads/admin_ads_screen.dart';

class DashboardTab {
  final Widget screen;
  final BottomNavigationBarItem item;
  final String? requiredPermission;

  const DashboardTab({
    required this.screen,
    required this.item,
    this.requiredPermission,
  });
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final orderProvider = Provider.of<OrderManagementProvider>(context);
    final admin = authProvider.currentAdmin;
    final activeOrdersCount = orderProvider.activeOrders.length;

    // Bottom Navigation tabs (simplified to 4 tabs as requested)
    final List<DashboardTab> allTabs = [
      DashboardTab(
        screen: const AdminOrdersScreen(),
        requiredPermission: 'manage_orders',
        item: BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.receipt_long_outlined),
              if (activeOrdersCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeOrdersCount',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          activeIcon: const Icon(Icons.receipt_long, color: AppColors.primary),
          label: 'الطلبات',
        ),
      ),
      const DashboardTab(
        screen: AdminCategoriesScreen(),
        requiredPermission: 'manage_products',
        item: BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          activeIcon: Icon(Icons.category, color: AppColors.primary),
          label: 'الفئات',
        ),
      ),
      const DashboardTab(
        screen: AdminProductsScreen(),
        requiredPermission: 'manage_products',
        item: BottomNavigationBarItem(
          icon: Icon(Icons.fastfood_outlined),
          activeIcon: Icon(Icons.fastfood, color: AppColors.primary),
          label: 'المنتجات',
        ),
      ),
      const DashboardTab(
        screen: AdminDeliveryZonesScreen(),
        requiredPermission: 'manage_orders',
        item: BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping, color: AppColors.primary),
          label: 'التوصيل',
        ),
      ),
    ];

    // Filter tabs based on admin role and permissions
    final List<DashboardTab> allowedTabs = allTabs.where((tab) {
      if (admin == null) return false;
      if (admin.isSuperAdmin) return true;
      if (tab.requiredPermission == null) return true;
      return admin.permissions.contains(tab.requiredPermission);
    }).toList();

    // Prevent index out of bounds if permissions dynamically change
    if (_currentIndex >= allowedTabs.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              admin != null ? 'إدارة: ${admin.fullName}' : 'لوحة تحكم الإدارة',
              style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تغيير المظهر',
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout, color: AppColors.danger),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header displaying Admin Profile Info
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  admin?.isSuperAdmin == true ? Icons.stars : Icons.admin_panel_settings,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              accountName: Text(
                admin?.fullName ?? 'مدير النظام',
                style: AppFonts.cairoFont(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
              ),
              accountEmail: Text(
                admin?.isSuperAdmin == true ? 'مدير عام بالنظام 👑' : 'مدير بصلاحيات محدودة 🛠️',
                style: AppFonts.cairoFont(color: Colors.white70, fontSize: 11),
              ),
            ),

            // Drawer Items with permission checks
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'الواجهات الإدارية الإضافية',
                      style: AppFonts.cairoFont(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  const Divider(),

                  // Option 1: Reports & Analytics
                  if (admin != null && (admin.isSuperAdmin || admin.permissions.contains('view_reports')))
                    ListTile(
                      leading: const Icon(Icons.bar_chart_outlined, color: AppColors.primary),
                      title: Text('التقارير والإحصائيات 📊', style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text('عرض الإيرادات والتحليلات اليومية', style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey)),
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
                        );
                      },
                    ),

                  // Option 2: Manage Sub-Admins
                  if (admin != null && (admin.isSuperAdmin || admin.permissions.contains('manage_admins')))
                    ListTile(
                      leading: const Icon(Icons.people_alt_outlined, color: AppColors.primary),
                      title: Text('إدارة المدراء والصلاحيات 👥', style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text('إضافة وتعديل المشرفين وصلاحياتهم', style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey)),
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminSubAdminsScreen()),
                        );
                      },
                    ),

                  // Option 3: Manage Ads & Notifications
                  if (admin != null && (admin.isSuperAdmin || admin.permissions.contains('manage_products')))
                    ListTile(
                      leading: const Icon(Icons.campaign_outlined, color: AppColors.primary),
                      title: Text('إدارة الإعلانات والتنبيهات 📢', style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text('إضافة عروض وتنبيهات في شريط العملاء', style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey)),
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminAdsScreen()),
                        );
                      },
                    ),
                  
                  const Divider(),
                ],
              ),
            ),

            // Logout row at the bottom of the Drawer
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: Text('تسجيل الخروج', style: AppFonts.cairoFont(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.of(context).pop(); // Close drawer
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: allowedTabs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 60, color: AppColors.danger),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد صلاحيات!',
                      style: AppFonts.cairoFont(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.danger),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'حسابك لا يمتلك أي صلاحيات حالياً. يرجى التواصل مع المدير العام لتفعيل حسابك.',
                      style: AppFonts.cairoFont(fontSize: 14, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: IndexedStack(
                key: ValueKey<int>(_currentIndex),
                index: _currentIndex,
                children: allowedTabs.map((t) => t.screen).toList(),
              ),
            ),
      bottomNavigationBar: allowedTabs.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey.shade600,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: AppFonts.cairoFont(fontSize: 11, fontWeight: FontWeight.bold),
                unselectedLabelStyle: AppFonts.cairoFont(fontSize: 10),
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: allowedTabs.map((t) => t.item).toList(),
              ),
            ),
    );
  }
}
