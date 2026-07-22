import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing Customer Favorite meals locally with session isolation
class FavoriteProvider extends ChangeNotifier {
  static const String _keyFavorites = 'customer_favorite_product_ids';
  final Set<String> _favoriteProductIds = {};
  String? _currentCustomerId;

  Set<String> get favoriteProductIds => _favoriteProductIds;

  FavoriteProvider();

  /// Load favorites specifically for the currently logged-in customer
  Future<void> loadFavorites(String customerId) async {
    if (_currentCustomerId == customerId) return;

    _currentCustomerId = customerId;
    _favoriteProductIds.clear();

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('${_keyFavorites}_$customerId') ?? [];
    _favoriteProductIds.addAll(list);
    notifyListeners();
  }

  /// Reset in-memory state on logout
  void clearFavorites() {
    _currentCustomerId = null;
    _favoriteProductIds.clear();
    notifyListeners();
  }

  bool isFavorite(String productId) => _favoriteProductIds.contains(productId);

  Future<void> toggleFavorite(String productId) async {
    if (_currentCustomerId == null) return; // User must be authenticated

    if (_favoriteProductIds.contains(productId)) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_keyFavorites}_$_currentCustomerId', _favoriteProductIds.toList());
  }
}
