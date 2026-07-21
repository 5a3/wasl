import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Helper service for Shared Preferences local caching & session management
class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Admin Session
  static Future<void> saveAdminSession({
    required String adminId,
    required String username,
    required String role,
  }) async {
    await init();
    await _prefs?.setBool(AppConstants.keyIsAdminLoggedIn, true);
    await _prefs?.setString(AppConstants.keyAdminId, adminId);
    await _prefs?.setString(AppConstants.keyAdminUsername, username);
    await _prefs?.setString(AppConstants.keyAdminRole, role);
  }

  static bool isAdminLoggedIn() {
    return _prefs?.getBool(AppConstants.keyIsAdminLoggedIn) ?? false;
  }

  static String? getAdminId() => _prefs?.getString(AppConstants.keyAdminId);
  static String? getAdminUsername() => _prefs?.getString(AppConstants.keyAdminUsername);
  static String? getAdminRole() => _prefs?.getString(AppConstants.keyAdminRole);

  static Future<void> clearAdminSession() async {
    await init();
    await _prefs?.remove(AppConstants.keyIsAdminLoggedIn);
    await _prefs?.remove(AppConstants.keyAdminId);
    await _prefs?.remove(AppConstants.keyAdminUsername);
    await _prefs?.remove(AppConstants.keyAdminRole);
  }

  // Customer Session
  static Future<void> saveCustomerSession({
    required String customerId,
    required String username,
    required String name,
    required String phone,
    required String address,
  }) async {
    await init();
    await _prefs?.setBool(AppConstants.keyIsCustomerLoggedIn, true);
    await _prefs?.setString(AppConstants.keyCustomerId, customerId);
    await _prefs?.setString(AppConstants.keyCustomerUsername, username);
    await _prefs?.setString(AppConstants.keyCustomerName, name);
    await _prefs?.setString(AppConstants.keyCustomerPhone, phone);
    await _prefs?.setString(AppConstants.keyCustomerAddress, address);
  }

  static bool isCustomerLoggedIn() {
    return _prefs?.getBool(AppConstants.keyIsCustomerLoggedIn) ?? false;
  }

  static String? getCustomerId() => _prefs?.getString(AppConstants.keyCustomerId);
  static String? getCustomerUsername() => _prefs?.getString(AppConstants.keyCustomerUsername);
  static String? getCustomerName() => _prefs?.getString(AppConstants.keyCustomerName);
  static String? getCustomerPhone() => _prefs?.getString(AppConstants.keyCustomerPhone);
  static String? getCustomerAddress() => _prefs?.getString(AppConstants.keyCustomerAddress);

  static Future<void> clearCustomerSession() async {
    await init();
    await _prefs?.remove(AppConstants.keyIsCustomerLoggedIn);
    await _prefs?.remove(AppConstants.keyCustomerId);
    await _prefs?.remove(AppConstants.keyCustomerUsername);
    await _prefs?.remove(AppConstants.keyCustomerName);
    await _prefs?.remove(AppConstants.keyCustomerPhone);
    await _prefs?.remove(AppConstants.keyCustomerAddress);
  }
}
