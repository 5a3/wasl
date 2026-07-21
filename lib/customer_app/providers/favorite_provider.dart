import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing Customer Favorite meals locally
class FavoriteProvider extends ChangeNotifier {
  static const String _keyFavorites = 'customer_favorite_product_ids';
  final Set<String> _favoriteProductIds = {};

  Set<String> get favoriteProductIds => _favoriteProductIds;

  FavoriteProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavorites) ?? [];
    _favoriteProductIds.addAll(list);
    notifyListeners();
  }

  bool isFavorite(String productId) => _favoriteProductIds.contains(productId);

  Future<void> toggleFavorite(String productId) async {
    if (_favoriteProductIds.contains(productId)) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavorites, _favoriteProductIds.toList());
  }
}
