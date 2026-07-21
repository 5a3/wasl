import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/theme/theme_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../categories/admin_categories_screen.dart';
import '../delivery_zones/admin_delivery_zones_screen.dart';
import '../orders/admin_orders_screen.dart';
import '../products/admin_products_screen.dart';
import '../reports/admin_reports_screen.dart';
import '../sub_admins/admin_sub_admins_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminOrdersScreen(),
    AdminCategoriesScreen(),
    AdminProductsScreen(),
    AdminDeliveryZonesScreen(),
    AdminReportsScreen(),
    AdminSubAdminsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final admin = authProvider.currentAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          admin != null ? 'لوحة التحكم - ${admin.fullName}' : 'لوحة تحكم الإدارة',
        ),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
          IconButton(
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppFonts.cairoFont(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppFonts.cairoFont(fontSize: 10),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarTypeItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'الطلبات',
          ),
          BottomNavigationBarTypeItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'الفئات',
          ),
          BottomNavigationBarTypeItem(
            icon: Icon(Icons.fastfood_outlined),
            activeIcon: Icon(Icons.fastfood),
            label: 'المنتجات',
          ),
          BottomNavigationBarTypeItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'التوصيل',
          ),
          BottomNavigationBarTypeItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'التقارير',
          ),
          BottomNavigationBarTypeItem(
            icon: Icon(Icons.supervisor_account_outlined),
            activeIcon: Icon(Icons.supervisor_account),
            label: 'المدراء',
          ),
        ],
      ),
    );
  }
}

class BottomNavigationBarTypeItem extends BottomNavigationBarItem {
  const BottomNavigationBarTypeItem({
    required super.icon,
    super.activeIcon,
    required super.label,
  });
}
