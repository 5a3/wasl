import 'package:flutter/material.dart';
import '../../shared/models/delivery_zone_model.dart';
import '../../shared/models/order_model.dart';
import '../../shared/models/product_model.dart';

/// Provider for Shopping Cart Management
class CartProvider extends ChangeNotifier {
  final Map<String, OrderItemModel> _items = {};
  DeliveryZoneModel? _selectedZone;

  Map<String, OrderItemModel> get items => _items;
  List<OrderItemModel> get itemList => _items.values.toList();
  int get itemCount => _items.length;
  DeliveryZoneModel? get selectedZone => _selectedZone;

  double get subtotal {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }

  double get deliveryFee => _selectedZone?.deliveryFee ?? 0.0;
  double get totalAmount => subtotal + deliveryFee;

  void setSelectedZone(DeliveryZoneModel? zone) {
    _selectedZone = zone;
    notifyListeners();
  }

  void addToCart(ProductModel product) {
    if (_items.containsKey(product.id)) {
      final old = _items[product.id]!;
      _items[product.id] = OrderItemModel(
        productId: old.productId,
        productName: old.productName,
        price: old.price,
        quantity: old.quantity + 1,
        imageUrl: old.imageUrl.isNotEmpty ? old.imageUrl : (product.images.isNotEmpty ? product.images.first : ''),
      );
    } else {
      _items[product.id] = OrderItemModel(
        productId: product.id,
        productName: product.name,
        price: product.price,
        quantity: 1,
        imageUrl: product.images.isNotEmpty ? product.images.first : '',
      );
    }
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
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedZone = null;
    notifyListeners();
  }
}
