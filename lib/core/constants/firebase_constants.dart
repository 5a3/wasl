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
  static const String collectionDailyReports = 'daily_reports';

  // Admin Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleSubAdmin = 'sub_admin';
}
