/// Firestore collections and document field names
class FirebaseConstants {
  FirebaseConstants._();

  // Collection Names
  static const String collectionAdmins = 'admins';
  static const String collectionCustomers = 'customers';
  static const String collectionCategories = 'categories';
  static const String collectionProducts = 'products';
  static const String collectionDeliveryZones = 'delivery_zones';
  static const String collectionOrders = 'orders';
  static const String collectionPaymentMethods = 'payment_methods';
  static const String collectionStores = 'stores';
  static const String collectionDailyReports = 'daily_reports';
  static const String collectionNotifications = 'notifications';

  // Admin Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleSubAdmin = 'sub_admin';

  // FCM Push Notification Server Key (Legacy FCM HTTP API Key)
  static const String fcmServerKey = 'AIzaSyAaiHxvaYSYQ_GwIev6WbaUQlry-wW__g8';
}
