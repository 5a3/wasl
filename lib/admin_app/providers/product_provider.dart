import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/product_model.dart';
import '../../core/services/firebase_storage_service.dart';

/// Provider for Product Management (CRUD, Search, Full Edit & Availability toggle)
class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<ProductModel> get products {
    if (_searchQuery.trim().isEmpty) return _products;
    final query = _searchQuery.trim().toLowerCase();
    return _products.where((p) =>
      p.name.toLowerCase().contains(query) ||
      p.description.toLowerCase().contains(query)
    ).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<ProductModel> getProductsBySubCategory(String subCatId) {
    return _products.where((p) => p.subCategoryId == subCatId).toList();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.collectionProducts)
          .orderBy('createdAt', descending: true)
          .get();

      _products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر جلب المنتجات: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ProductModel> getProductsByStore(String? storeId) {
    if (storeId == null || storeId.isEmpty) return products;
    return products.where((p) => p.storeId == storeId || p.storeId == null).toList();
  }

  /// Add new product with up to 3 images and optional discount settings
  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required String mainCategoryId,
    required String subCategoryId,
    required List<String> images,
    bool isAvailable = true,
    bool hasDiscount = false,
    String discountType = 'percentage',
    double discountValue = 0.0,
    String? storeId,
    String? storeName,
  }) async {
    try {
      final docRef = _firestore.collection(FirebaseConstants.collectionProducts).doc();
      final newProduct = ProductModel(
        id: docRef.id,
        name: name.trim(),
        description: description.trim(),
        price: price,
        mainCategoryId: mainCategoryId,
        subCategoryId: subCategoryId,
        images: images.take(3).toList(),
        isAvailable: isAvailable,
        salesCount: 0,
        hasDiscount: hasDiscount,
        discountType: discountType,
        discountValue: discountValue,
        createdAt: DateTime.now(),
        storeId: storeId,
        storeName: storeName,
      );

      await docRef.set(newProduct.toMap());
      _products.insert(0, newProduct);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إضافة المنتج: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Full Product Edit (name, price, description, images, category, availability, discount)
  Future<bool> editProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required String mainCategoryId,
    required String subCategoryId,
    required List<String> images,
    required bool isAvailable,
    bool hasDiscount = false,
    String discountType = 'percentage',
    double discountValue = 0.0,
    String? storeId,
    String? storeName,
  }) async {
    try {
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        final old = _products[index];
        final updated = ProductModel(
          id: id,
          name: name.trim(),
          description: description.trim(),
          price: price,
          mainCategoryId: mainCategoryId,
          subCategoryId: subCategoryId,
          images: images.isNotEmpty ? images.take(3).toList() : old.images,
          isAvailable: isAvailable,
          salesCount: old.salesCount,
          hasDiscount: hasDiscount,
          discountType: discountType,
          discountValue: discountValue,
          createdAt: old.createdAt,
          storeId: storeId ?? old.storeId,
          storeName: storeName ?? old.storeName,
        );

        await _firestore
            .collection(FirebaseConstants.collectionProducts)
            .doc(id)
            .update(updated.toMap());

        _products[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'فشل تعديل المنتج: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delete Product
  Future<bool> deleteProduct(String id) async {
    try {
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        final oldImages = _products[index].images;
        for (final img in oldImages) {
          if (img.isNotEmpty) {
            await FirebaseStorageService.deleteImage(img);
          }
        }
      }

      await _firestore
          .collection(FirebaseConstants.collectionProducts)
          .doc(id)
          .delete();

      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف المنتج: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Toggle Availability Switch (متوفر / غير متوفر)
  Future<bool> toggleAvailability(String productId, bool isAvailable) async {
    try {
      await _firestore
          .collection(FirebaseConstants.collectionProducts)
          .doc(productId)
          .update({'isAvailable': isAvailable});

      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final p = _products[index];
        _products[index] = p.copyWith(isAvailable: isAvailable);
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
