import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/category_model.dart';

/// Provider for managing Main and Sub Categories
class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get mainCategories => _categories.where((c) => c.isMainCategory).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CategoryModel> getSubCategories(String parentId) {
    return _categories.where((c) => c.parentId == parentId).toList();
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.collectionCategories)
          .orderBy('orderIndex')
          .get(const GetOptions(source: Source.serverAndCache));

      _categories = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر جلب الفئات: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory({
    required String name,
    String? parentId,
    required String imageUrl,
  }) async {
    try {
      final docRef = _firestore.collection(FirebaseConstants.collectionCategories).doc();
      final newCat = CategoryModel(
        id: docRef.id,
        name: name.trim(),
        parentId: parentId,
        imageUrl: imageUrl,
        orderIndex: _categories.length,
      );

      await docRef.set(newCat.toMap());
      _categories.add(newCat);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إضافة الفئة: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleCategoryStatus(String id, bool isActive) async {
    try {
      await _firestore
          .collection(FirebaseConstants.collectionCategories)
          .doc(id)
          .update({'isActive': isActive});

      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        final old = _categories[index];
        _categories[index] = CategoryModel(
          id: old.id,
          name: old.name,
          parentId: old.parentId,
          imageUrl: old.imageUrl,
          isActive: isActive,
          orderIndex: old.orderIndex,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
