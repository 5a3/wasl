import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../customer_app/views/auth/customer_login_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/theme/theme_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/order_management_provider.dart';
import '../categories/admin_categories_screen.dart';
import '../delivery_zones/admin_delivery_zones_screen.dart';
import '../orders/admin_orders_screen.dart';
import '../products/admin_products_screen.dart';
import '../reports/admin_reports_screen.dart';
import '../sub_admins/admin_sub_admins_screen.dart';
import '../notifications/admin_notifications_screen.dart';
import '../ads/admin_ads_screen.dart';
import '../complaints/admin_complaints_screen.dart';
import '../../../shared/providers/store_provider.dart';

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

    final isDark = themeProvider.isDarkMode;

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
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        child: Container(
          color: isDark ? AppColors.darkSurface : Colors.white,
          child: Column(
            children: [
              // Premium Custom Drawer Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20, left: 16, right: 16),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(
                              admin?.isSuperAdmin == true ? Icons.stars : Icons.admin_panel_settings,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                admin?.fullName ?? 'مدير النظام',
                                style: AppFonts.cairoFont(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  admin?.isSuperAdmin == true ? 'مدير عام بالنظام 👑' : 'مدير بصلاحيات محدودة 🛠️',
                                  style: AppFonts.cairoFont(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
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

              // Drawer Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  children: [
                    // Store Open / Closed Interactive Status Card
                    _buildStoreStatusCard(context, isDark),
                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text(
                        'القائمة الإدارية والإعدادات',
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Divider(height: 10, thickness: 0.5, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    const SizedBox(height: 8),

                    // Option 1: Reports & Analytics
                    if (admin != null && (admin.isSuperAdmin || admin.permissions.contains('view_reports')))
                      _buildDrawerItem(
                        icon: Icons.bar_chart_outlined,
                        title: 'التقارير والإحصائيات 📊',
                        subtitle: 'مراجعة المبيعات والأرباح والتصفية',
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
                          );
                        },
                      ),

                    // Option 2: Manage Sub-Admins
                    if (admin != null && (admin.isSuperAdmin || admin.permissions.contains('manage_admins')))
                      _buildDrawerItem(
                        icon: Icons.people_alt_outlined,
                        title: 'إدارة المدراء والصلاحيات 👥',
                        subtitle: 'تعيين المشرفين وتعديل صلاحياتهم',
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminSubAdminsScreen()),
                          );
                        },
                      ),

                    // Option 3: Manage Ads & Notifications
                    if (admin != null && (admin.isSuperAdmin || admin.permissions.contains('manage_products')))
                      _buildDrawerItem(
                        icon: Icons.campaign_outlined,
                        title: 'إدارة الإعلانات والتنبيهات 📢',
                        subtitle: 'نشر عروض جديدة وتنبيهات للعملاء',
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminAdsScreen()),
                          );
                        },
                      ),

                    // Option 4: Broadcast App Notifications
                    if (admin != null && admin.isSuperAdmin)
                      _buildDrawerItem(
                        icon: Icons.notifications_active_outlined,
                        title: 'إشعارات التطبيق 🔔',
                        subtitle: 'إرسال وتصفح الإشعارات العامة للعملاء',
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
                          );
                        },
                      ),

                    // Option 5: Customer Complaints & Suggestions
                    _buildDrawerItem(
                      icon: Icons.rate_review_outlined,
                      title: 'الشكاوى والمقترحات 📩',
                      subtitle: 'مراجعة رسائل وملاحظات العملاء والتواصل',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminComplaintsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Custom Logout Card at the bottom
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () async {
                    final confirm = await CustomDialog.showConfirmDialog(
                      context: context,
                      title: 'تسجيل الخروج 🚪',
                      message: 'هل أنت تأكد من أنك تريد تسجيل الخروج من لوحة الإدارة؟',
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
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.danger.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: AppColors.danger, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'تسجيل الخروج من النظام',
                          style: AppFonts.cairoFont(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.withAlpha(15),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: AppFonts.cairoFont(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppFonts.cairoFont(
            fontSize: 10,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStoreStatusCard(BuildContext context, bool isDark) {
    return Consumer<StoreProvider>(
      builder: (context, storeProvider, child) {
        final isOpen = storeProvider.isOpen;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOpen ? Colors.green.withAlpha(18) : AppColors.danger.withAlpha(18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOpen ? Colors.green.withAlpha(80) : AppColors.danger.withAlpha(80),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.green : AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOpen ? Icons.storefront : Icons.storefront_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOpen ? 'المحل مفتوح حالياً 🟢' : 'المحل مغلق حالياً 🔴',
                                style: AppFonts.cairoFont(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isOpen
                                      ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                                      : (isDark ? Colors.red.shade300 : AppColors.danger),
                                ),
                              ),
                              Text(
                                isOpen ? 'العملاء يستطيعون الطلب' : 'تم تقييد واستقبال الطلبات',
                                style: AppFonts.cairoFont(
                                  fontSize: 10,
                                  color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isOpen,
                    activeColor: Colors.green,
                    inactiveThumbColor: AppColors.danger,
                    inactiveTrackColor: AppColors.danger.withAlpha(40),
                    onChanged: (value) => _toggleStoreStatusDialog(context, storeProvider, value),
                  ),
                ],
              ),
              if (!isOpen && storeProvider.closedReason != null && storeProvider.closedReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'سبب الإغلاق: ${storeProvider.closedReason}',
                    style: AppFonts.cairoFont(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _toggleStoreStatusDialog(BuildContext context, StoreProvider storeProvider, bool newStatus) {
    if (newStatus) {
      // Re-opening store
      storeProvider.updateStoreStatus(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم فتح المحل بنجاح! يستطيع العملاء الطلب الآن 🟢', style: AppFonts.cairoFont(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );

      return;
    }

    // Closing store: show dialog for optional closed reason
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: AppColors.danger, size: 24),
            const SizedBox(width: 8),
            Text('إغلاق المحل 🔴', style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'عند إغلاق المحل، سيتم إظهار تنبيه للعملاء وتوقف زر إتمام الطلب بالسلة فوراً.',
                style: AppFonts.cairoFont(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Text('سبب الإغلاق (اختياري):', style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'مثال: مغلق لصلاة الجمعة / انتهاء ساعات العمل',
                  hintStyle: AppFonts.cairoFont(fontSize: 11, color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  'مغلق لصلاة الجمعة 🕌',
                  'انتهت ساعات العمل 🌙',
                  'مغلق للصيانة 🛠️',
                ].map((reason) => ActionChip(
                  label: Text(reason, style: AppFonts.cairoFont(fontSize: 10)),
                  backgroundColor: isDark ? AppColors.darkBackground : Colors.grey.shade200,
                  onPressed: () {
                    reasonController.text = reason;
                  },
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('إلغاء', style: AppFonts.cairoFont(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await storeProvider.updateStoreStatus(false, reason: reasonController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم إغلاق المحل وتقييد الطلبات بنجاح 🔴', style: AppFonts.cairoFont(color: Colors.white)),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: Text('تأكيد الإغلاق', style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
