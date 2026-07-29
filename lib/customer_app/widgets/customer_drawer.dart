import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/theme/theme_provider.dart';
import '../../shared/views/developer_profile_screen.dart';
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

    final customerName =
        customer?.fullName.isNotEmpty == true
            ? customer!.fullName
            : 'عميل وصل لي';
    final customerPhone =
        customer?.phone.isNotEmpty == true ? customer!.phone : '';
    final customerEmail =
        customer?.email.isNotEmpty == true ? customer!.email : '';

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: Column(
        children: [
          // Header Profile Card
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withAlpha(200)],
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
              style: AppFonts.cairoFont(fontSize: 12, color: Colors.white70),
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
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                const CustomerOrdersScreen(isStandalone: true),
                      ),
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
                      MaterialPageRoute(
                        builder:
                            (_) => const FavoritesScreen(isStandalone: true),
                      ),
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
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(isStandalone: true),
                      ),
                    );
                  },
                ),

                const Divider(indent: 16, endIndent: 16),

                _buildDrawerTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'عن التطبيق',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAboutAppDialog(context);
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.code_rounded,
                  title: 'مطور التطبيق',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeveloperProfileScreen(),
                      ),
                    );
                  },
                ),

                // Theme Mode Switch
                ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    themeProvider.isDarkMode ? 'الوضع الليلي' : 'الوضع النهارى',
                    style: AppFonts.cairoFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
                  MaterialPageRoute(
                    builder: (_) => const CustomerLoginScreen(),
                  ),
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
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder:
          (dialogCtx) => Dialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Partner Logo Header (logoreport.svg)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.darkBackground
                                : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isDark
                                  ? AppColors.darkBorder
                                  : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.asset(
                            'assets/images/logoreport.svg',
                            height: 55,
                            fit: BoxFit.contain,
                          ),
                          SvgPicture.asset(
                            'assets/images/logo.svg',
                            height: 55,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'تطبيق وصل لي - Wasl App',
                      style: AppFonts.cairoFont(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🤝 الشريك الرسمي مقهئ جدة للوجبات السريعة',
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Comprehensive Description
                    Text(
                      'تطبيق "وصل لي" هي المنصة الرقمية والتطبيق الرسمي المعترف به لتصفح وطلب أشهى الوجبات والمأكولات والمشروبات، بالتنسيق والشراكة الاستراتيجية الحصرية مع (مقهى جدة للوجبات السريعة).\n\nيمكّن التطبيق العملاء من تصفح أصناف الوجبات، إضافة الطلبات للسلة، واختيار منطقة التوصيل بدقة، مع تتبع لحظي ومباشر لمراحل الطلب خطوة بخطوة من التجهيز والتحضير وحتى وصول الوجبة الساخنة إليك بسرعة وأمان.',
                      textAlign: TextAlign.center,
                      style: AppFonts.cairoFont(
                        fontSize: 12.5,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey.shade800,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Version Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'إصدار التطبيق: 1.0.0',
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: Text(
                          'إغلاق',
                          style: AppFonts.cairoFont(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
