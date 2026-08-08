import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../shared/views/developer_profile_screen.dart';
import '../providers/customer_auth_provider.dart';
import '../views/auth/customer_login_screen.dart';
import '../views/favorites/favorites_screen.dart';
import '../views/my_orders/customer_orders_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/complaints/customer_complaint_screen.dart';

/// Official Responsive & Modern Customer Navigation Drawer Component
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
    final customerAddress =
        customer?.address.isNotEmpty == true ? customer!.address : '';

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: Column(
        children: [
          // Header Profile Card with App SVG Logo & User Address Capsule
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.darkSurfaceLight, AppColors.darkSurface]
                    : [AppColors.primary, AppColors.primary.withAlpha(200)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  fit: BoxFit.contain,
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
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (customerPhone.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.phone_iphone_rounded, size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        customerPhone,
                        style: AppFonts.cairoFont(fontSize: 11.5, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(28),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withAlpha(45), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          customerAddress.isNotEmpty ? customerAddress : 'العنوان غير محدد 📍',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.cairoFont(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Menu Options List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _buildSectionTitle('الخدمات والطلبات', isDark),
                const SizedBox(height: 4),
                _buildDrawerTile(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: 'طلباتي ومتابعة الشحن',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerOrdersScreen(isStandalone: true),
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
                        builder: (_) => const FavoritesScreen(isStandalone: true),
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
                _buildDrawerTile(
                  context,
                  icon: Icons.storefront_outlined,
                  title: 'اطلب من محل آخر',
                  badgeText: 'قريباً 🚀',
                  onTap: () {
                    Navigator.of(context).pop();
                    CustomDialog.showOrderFromAnotherStoreDialog(context);
                  },
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.rate_review_outlined,
                  title: 'الشكاوى والمقترحات',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerComplaintScreen(),
                      ),
                    );
                  },
                ),

                // Subtle Thin Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: isDark ? Colors.white.withAlpha(20) : Colors.grey.withAlpha(40),
                  ),
                ),

                _buildSectionTitle('التطبيق والإعدادات', isDark),
                const SizedBox(height: 4),

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

                // Theme Mode Switch Tile
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceLight.withAlpha(80) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      themeProvider.isDarkMode ? 'الوضع الليلي' : 'الوضع النهارى',
                      style: AppFonts.cairoFont(
                        fontSize: 13.5,
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
                ),
              ],
            ),
          ),

          // 3. Responsive Safe Area Logout Footer (Guarantees no overlap on Redmi / Samsung phones)
          SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Material(
                color: AppColors.danger.withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final confirm = await CustomDialog.showConfirmDialog(
                      context: context,
                      title: 'تسجيل الخروج 🚪',
                      message: 'هل أنت تأكد من أنك تريد تسجيل الخروج من تطبيق وصل لي؟',
                      confirmText: 'تسجيل الخروج',
                      cancelText: 'إلغاء',
                      confirmColor: AppColors.danger,
                    );
                    if (confirm == true) {
                      await authProvider.logout();
                      navigatorKey.currentState?.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const CustomerLoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'تسجيل الخروج',
                          style: AppFonts.cairoFont(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      child: Text(
        title,
        style: AppFonts.cairoFont(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.cairoFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(60),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: AppFonts.cairoFont(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
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
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
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
