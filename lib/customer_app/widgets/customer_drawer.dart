import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/customer_auth_provider.dart';
import '../views/auth/customer_login_screen.dart';
import '../views/favorites/favorites_screen.dart';
import '../views/my_orders/customer_orders_screen.dart';
import '../views/profile/profile_screen.dart';

/// Official Customer Navigation Drawer Component
class CustomerDrawer extends StatelessWidget {
  const CustomerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomerAuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final customer = authProvider.currentCustomer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customerName = customer?.fullName.isNotEmpty == true
        ? customer!.fullName
        : 'عميل وصل لي';
    final customerPhone = customer?.phone.isNotEmpty == true
        ? customer!.phone
        : '';
    final customerEmail = customer?.email.isNotEmpty == true
        ? customer!.email
        : '';

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: Column(
        children: [
          // Header Profile Card
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withAlpha(200),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                customerName.isNotEmpty ? customerName[0].toUpperCase() : 'ع',
                style: AppFonts.cairoFont(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            accountName: Text(
              customerName,
              style: AppFonts.cairoFont(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              customerPhone.isNotEmpty ? customerPhone : customerEmail,
              style: AppFonts.cairoFont(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerTile(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'طلباتي ومتابعة الشحن',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CustomerOrdersScreen(isStandalone: true)),
                    );
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.favorite_border,
                  title: 'الأطباق المفضلة',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FavoritesScreen(isStandalone: true)),
                    );
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.person_outline,
                  title: 'الملف الشخصي والحساب',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen(isStandalone: true)),
                    );
                  },
                ),

                const Divider(indent: 16, endIndent: 16),

                // Theme Mode Switch
                ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    themeProvider.isDarkMode ? 'الوضع الليلي' : 'الوضع النهارى',
                    style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      themeProvider.toggleTheme(val);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Logout Footer Button
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text(
              'تسجيل الخروج',
              style: AppFonts.cairoFont(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.danger,
              ),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
