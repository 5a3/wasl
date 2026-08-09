import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../admin_app/providers/category_provider.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/delivery_zone_model.dart';
import '../../shared/models/order_model.dart';
import '../../shared/models/product_model.dart';

/// Provider for Shopping Cart Management with persistent storage per customer ID
class CartProvider extends ChangeNotifier {
  final Map<String, OrderItemModel> _items = {};
  DeliveryZoneModel? _selectedZone;
  String? _currentCustomerId;
  CategoryProvider? _categoryProvider;

  Map<String, OrderItemModel> get items => _items;
  List<OrderItemModel> get itemList => _items.values.toList();
  int get itemCount => _items.length;
  DeliveryZoneModel? get selectedZone => _selectedZone;
  String? get currentCustomerId => _currentCustomerId;

  void setCategoryProvider(CategoryProvider? categoryProvider) {
    _categoryProvider = categoryProvider;
  }

  double get subtotal {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }

  double get deliveryFee => _selectedZone?.deliveryFee ?? 0.0;
  double get totalAmount => subtotal + deliveryFee;

  /// Loads the cart from SharedPreferences for a specific customer
  Future<void> loadCart(String customerId) async {
    _currentCustomerId = customerId;
    _items.clear();
    _selectedZone = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load cart items
      final cartKey = 'customer_cart_$customerId';
      final jsonStr = prefs.getString(cartKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(jsonStr);
        for (var itemMap in decodedList) {
          final item = OrderItemModel.fromMap(Map<String, dynamic>.from(itemMap));
          _items[item.productId] = item;
        }
      }
    } catch (e) {
      debugPrint('Error loading customer cart: $e');
    }
    notifyListeners();
  }

  /// Saves the current cart to SharedPreferences for the active customer
  Future<void> saveCartToStorage() async {
    final customerId = _currentCustomerId;
    if (customerId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save items list
      final cartKey = 'customer_cart_$customerId';
      final list = _items.values.map((item) => item.toMap()).toList();
      await prefs.setString(cartKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving customer cart: $e');
    }
  }

  void setSelectedZone(DeliveryZoneModel? zone) {
    _selectedZone = zone;
    notifyListeners();
  }

  void addToCart(ProductModel product, {CategoryModel? category}) {
    final cat = category ?? _categoryProvider?.getCategoryById(product.mainCategoryId);
    final effectivePrice = product.getEffectivePrice(cat);
    if (_items.containsKey(product.id)) {
      final old = _items[product.id]!;
      _items[product.id] = OrderItemModel(
        productId: old.productId,
        productName: old.productName,
        price: effectivePrice,
        quantity: old.quantity + 1,
        imageUrl: old.imageUrl.isNotEmpty ? old.imageUrl : (product.images.isNotEmpty ? product.images.first : ''),
      );
    } else {
      _items[product.id] = OrderItemModel(
        productId: product.id,
        productName: product.name,
        price: effectivePrice,
        quantity: 1,
        imageUrl: product.images.isNotEmpty ? product.images.first : '',
      );
    }
    saveCartToStorage();
    notifyListeners();
  }

  void decrementItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      final old = _items[productId]!;
      _items[productId] = OrderItemModel(
        productId: old.productId,
        productName: old.productName,
        price: old.price,
        quantity: old.quantity - 1,
        imageUrl: old.imageUrl,
      );
    } else {
      _items.remove(productId);
    }
    saveCartToStorage();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    saveCartToStorage();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedZone = null;
    _clearUserStorage();
    notifyListeners();
  }

  /// Clears SharedPreferences cache for the current customer
  Future<void> _clearUserStorage() async {
    final customerId = _currentCustomerId;
    if (customerId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('customer_cart_$customerId');
    } catch (_) {}
  }
}
