import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/category_model.dart';

/// Provider for managing Main and Sub Categories with full CRUD & Search
import '../../core/services/firebase_storage_service.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<CategoryModel> get categories {
    if (_searchQuery.trim().isEmpty) return _categories;
    final query = _searchQuery.trim().toLowerCase();
    return _categories.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  List<CategoryModel> get mainCategories => categories.where((c) => c.isMainCategory).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

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

  Future<bool> editCategory({
    required String id,
    required String name,
    String? parentId,
    required String imageUrl,
  }) async {
    try {
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updated = CategoryModel(
          id: id,
          name: name.trim(),
          parentId: parentId,
          imageUrl: imageUrl.isNotEmpty ? imageUrl : _categories[index].imageUrl,
          isActive: _categories[index].isActive,
          orderIndex: _categories[index].orderIndex,
        );

        await _firestore
            .collection(FirebaseConstants.collectionCategories)
            .doc(id)
            .update(updated.toMap());

        _categories[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'فشل تعديل الفئة: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        final imageUrl = _categories[index].imageUrl;
        if (imageUrl.isNotEmpty) {
          await FirebaseStorageService.deleteImage(imageUrl);
        }
      }

      await _firestore
          .collection(FirebaseConstants.collectionCategories)
          .doc(id)
          .delete();

      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف الفئة: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
