import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_fonts.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/custom_button.dart';
import 'core/widgets/offline_banner.dart';

// Admin App Providers & Views
import 'admin_app/providers/admin_auth_provider.dart';
import 'admin_app/providers/analytics_provider.dart';
import 'admin_app/providers/category_provider.dart';
import 'admin_app/providers/delivery_zone_provider.dart';
import 'admin_app/providers/order_management_provider.dart';
import 'admin_app/providers/product_provider.dart';
import 'admin_app/views/auth/admin_login_screen.dart';

// Customer App Providers & Views
import 'customer_app/providers/cart_provider.dart';
import 'customer_app/providers/customer_auth_provider.dart';
import 'customer_app/providers/customer_order_provider.dart';
import 'customer_app/providers/favorite_provider.dart';
import 'customer_app/views/auth/customer_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage Service & Connectivity Listener
  await StorageService.init();
  ConnectivityService().initialize();

  // Initialize Firebase (safely handles web/mobile platform checks)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Initialization Note: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryZoneProvider()),
        ChangeNotifierProvider(create: (_) => OrderManagementProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => CustomerAuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => CustomerOrderProvider()),
      ],
      child: const WaslAppMain(),
    ),
  );
}

class WaslAppMain extends StatelessWidget {
  const WaslAppMain({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: (context, child) {
        return OfflineBannerWrapper(child: child ?? const SizedBox.shrink());
      },
      home: const AppLauncherChooserScreen(),
    );
  }
}

/// Initial Gateway Chooser Screen allowing quick testing/switching between Admin & Customer apps
class AppLauncherChooserScreen extends StatelessWidget {
  const AppLauncherChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fastfood,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'أهلاً بك في نظام واصل للمأكولات السريعة',
              textAlign: TextAlign.center,
              style: AppFonts.cairoFont(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر التطبيق للبدء والتجربة',
              style: AppFonts.cairoFont(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'تطبيق العملاء (Customer App)',
              icon: Icons.person_pin_circle_outlined,
              backgroundColor: AppColors.primary,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'تطبيق الإدارة (Admin App)',
              icon: Icons.admin_panel_settings_outlined,
              backgroundColor: AppColors.darkSurface,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
