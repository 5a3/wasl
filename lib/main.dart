import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
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
import 'admin_app/providers/notification_provider.dart';
import 'admin_app/providers/order_management_provider.dart';
import 'admin_app/providers/product_provider.dart';
import 'admin_app/providers/ad_provider.dart';
import 'admin_app/views/auth/admin_login_screen.dart';

// Customer App Providers & Views
import 'customer_app/providers/cart_provider.dart';
import 'customer_app/providers/customer_auth_provider.dart';
import 'customer_app/providers/customer_notification_provider.dart';
import 'customer_app/providers/customer_order_provider.dart';
import 'customer_app/providers/favorite_provider.dart';
import 'customer_app/views/auth/customer_login_screen.dart';
import 'core/services/fcm_service.dart';
import 'core/utils/pdf_helper.dart';
import 'shared/providers/store_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Date Formatting Locale for Arabic
  await initializeDateFormatting('ar', null);

  // Initialize Storage Service & Connectivity Listener
  await StorageService.init();
  ConnectivityService().initialize();

  // Preload PDF fonts in the background to eliminate lag when printing/saving PDFs
  PdfHelper.preloadFonts();

  // Initialize Firebase (safely handles web/mobile platform checks)
  try {
    await Firebase.initializeApp();

    // Pass all uncaught Flutter framework errors to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors that aren't handled by Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Enable automatic Crashlytics collection in both debug and release modes
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    // Initialize FCM Messaging & Local Notifications
    await FcmService.initialize();
  } catch (e) {
    debugPrint('Firebase Initialization Note: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryZoneProvider()),
        ChangeNotifierProvider(create: (_) => OrderManagementProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => AdminNotificationProvider()),
        ChangeNotifierProvider(create: (_) => CustomerNotificationProvider()),
        ChangeNotifierProvider(create: (_) => CustomerAuthProvider()),
        ChangeNotifierProxyProvider<CustomerAuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) {
            final customer = auth.currentCustomer;
            if (cart != null) {
              if (customer != null) {
                if (cart.currentCustomerId != customer.id) {
                  cart.loadCart(customer.id);
                }
              } else {
                if (cart.currentCustomerId != null) {
                  cart.clearCart();
                }
              }
            }
            return cart ?? CartProvider();
          },
        ),
        ChangeNotifierProxyProvider<CustomerAuthProvider, FavoriteProvider>(
          create: (_) => FavoriteProvider(),
          update: (_, auth, favorite) {
            final customer = auth.currentCustomer;
            if (customer != null) {
              favorite?.loadFavorites(customer.id);
            } else {
              favorite?.clearFavorites();
            }
            return favorite ?? FavoriteProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => CustomerOrderProvider()),
      ],
      child: const WaslAppMain(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class WaslAppMain extends StatelessWidget {
  const WaslAppMain({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: const Locale('ar', 'YE'),
      supportedLocales: const [Locale('ar', 'YE'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
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
              child: const Icon(Icons.fastfood, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'أهلاً بك في نظام وصل لي للمأكولات السريعة',
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
                  MaterialPageRoute(
                    builder: (_) => const CustomerLoginScreen(),
                  ),
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
