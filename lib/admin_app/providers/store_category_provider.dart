import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/store_category_model.dart';

/// Provider for managing Store Categories (أقسام المحلات) in Admin Panel and filters
class StoreCategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<StoreCategoryModel> _storeCategories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<StoreCategoryModel> get storeCategories {
    if (_searchQuery.trim().isEmpty) return _storeCategories;
    final query = _searchQuery.trim().toLowerCase();
    return _storeCategories.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  List<StoreCategoryModel> get activeStoreCategories =>
      storeCategories.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchStoreCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.collectionStoreCategories)
          .get(const GetOptions(source: Source.serverAndCache));

      _storeCategories = snapshot.docs
          .map((doc) => StoreCategoryModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر جلب أقسام المحلات: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStoreCategory(String name) async {
    try {
      final docRef = _firestore.collection(FirebaseConstants.collectionStoreCategories).doc();
      final newCategory = StoreCategoryModel(
        id: docRef.id,
        name: name.trim(),
        isActive: true,
        createdAt: DateTime.now(),
      );

      await docRef.set(newCategory.toMap());
      _storeCategories.add(newCategory);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إضافة قسم المحل: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editStoreCategory(String id, String newName) async {
    try {
      final index = _storeCategories.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updated = _storeCategories[index].copyWith(name: newName.trim());

        await _firestore
            .collection(FirebaseConstants.collectionStoreCategories)
            .doc(id)
            .update({'name': newName.trim()});

        _storeCategories[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'فشل تعديل اسم القسم: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStoreCategory(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.collectionStoreCategories)
          .doc(id)
          .delete();

      _storeCategories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف القسم: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
