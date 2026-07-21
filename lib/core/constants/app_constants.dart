/// Application wide constants and string identifiers
class AppConstants {
  AppConstants._();

  static const String appName = 'واصل للتوصيل';
  static const String adminAppName = 'لوحة إدارة واصل';
  static const String customerAppName = 'واصل - الطلب والتوصيل';
  static const String currencySymbol = 'ر.ي'; // الريال اليمني

  // Shared Preferences Keys
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyIsAdminLoggedIn = 'is_admin_logged_in';
  static const String keyAdminId = 'admin_id';
  static const String keyAdminUsername = 'admin_username';
  static const String keyAdminRole = 'admin_role';

  static const String keyIsCustomerLoggedIn = 'is_customer_logged_in';
  static const String keyCustomerId = 'customer_id';
  static const String keyCustomerUsername = 'customer_username';
  static const String keyCustomerPhone = 'customer_phone';
  static const String keyCustomerName = 'customer_name';
  static const String keyCustomerAddress = 'customer_address';

  // Order Status Strings
  static const String statusPending = 'pending';
  static const String statusAcceptedPreparing = 'accepted_preparing';
  static const String statusDelivering = 'delivering';
  static const String statusDelivered = 'delivered';
  static const String statusCanceled = 'canceled';

  static const String statusPendingAr = 'معلق';
  static const String statusAcceptedPreparingAr = 'تم الاستلام - قيد التحضير';
  static const String statusDeliveringAr = 'في الطريق مع المندوب';
  static const String statusDeliveredAr = 'تم التوصيل';
  static const String statusCanceledAr = 'ملغي';
}
