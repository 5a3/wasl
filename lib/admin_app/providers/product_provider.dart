import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/product_model.dart';

/// Provider for Product Management (up to 3 images, availability toggle, price)
class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
          .get(const GetOptions(source: Source.serverAndCache));

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

  /// Add new product with up to 3 images
  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required String mainCategoryId,
    required String subCategoryId,
    required List<String> images,
    bool isAvailable = true,
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
        images: images.take(3).toList(), // Limit max 3 images
        isAvailable: isAvailable,
        salesCount: 0,
        createdAt: DateTime.now(),
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
        _products[index] = ProductModel(
          id: p.id,
          name: p.name,
          description: p.description,
          price: p.price,
          mainCategoryId: p.mainCategoryId,
          subCategoryId: p.subCategoryId,
          images: p.images,
          isAvailable: isAvailable,
          salesCount: p.salesCount,
          createdAt: p.createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
