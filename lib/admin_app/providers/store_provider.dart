import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/firebase_storage_service.dart';
import '../../shared/models/store_model.dart';

class StoreProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<StoreModel> _stores = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedStoreId;

  List<StoreModel> get stores {
    if (_searchQuery.trim().isEmpty) return _stores;
    final query = _searchQuery.trim().toLowerCase();
    return _stores.where((s) => s.name.toLowerCase().contains(query)).toList();
  }

  List<StoreModel> get rawStores => _stores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get error => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedStoreId => _selectedStoreId;

  void listenToStores() => fetchStores();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedStoreId(String? storeId) {
    _selectedStoreId = storeId;
    notifyListeners();
  }

  StoreModel? getStoreById(String id) {
    try {
      return _stores.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchStores() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.collectionStores)
          .get();

      _stores = snapshot.docs
          .map((doc) => StoreModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر جلب المطاعم: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStore(dynamic nameOrStore, {
    String? logoUrl,
    String? coverUrl,
    String? phone,
    String? description,
    bool isOpen = true,
  }) async {
    if (nameOrStore is StoreModel) {
      try {
        final docRef = _firestore.collection(FirebaseConstants.collectionStores).doc();
        final newStore = nameOrStore.copyWith(id: docRef.id);
        await docRef.set(newStore.toMap());
        _stores.add(newStore);
        notifyListeners();
        return true;
      } catch (e) {
        _errorMessage = 'فشل إضافة المطعم: ${e.toString()}';
        notifyListeners();
        return false;
      }
    }

    try {
      final docRef = _firestore.collection(FirebaseConstants.collectionStores).doc();
      final newStore = StoreModel(
        id: docRef.id,
        name: (nameOrStore as String).trim(),
        logoUrl: logoUrl,
        coverUrl: coverUrl,
        phone: phone?.trim(),
        description: description?.trim(),
        isOpen: isOpen,
        createdAt: DateTime.now(),
      );

      await docRef.set(newStore.toMap());
      _stores.add(newStore);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إضافة المطعم: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStore(StoreModel store) async {
    try {
      final index = _stores.indexWhere((s) => s.id == store.id);
      await _firestore
          .collection(FirebaseConstants.collectionStores)
          .doc(store.id)
          .update(store.toMap());

      if (index != -1) {
        _stores[index] = store;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل تعديل المطعم: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editStore({
    required String id,
    required String name,
    String? logoUrl,
    String? coverUrl,
    String? phone,
    String? description,
    bool? isOpen,
  }) async {
    try {
      final index = _stores.indexWhere((s) => s.id == id);
      if (index != -1) {
        final current = _stores[index];
        final updated = current.copyWith(
          name: name.trim(),
          logoUrl: logoUrl ?? current.logoUrl,
          coverUrl: coverUrl ?? current.coverUrl,
          phone: phone?.trim() ?? current.phone,
          description: description?.trim() ?? current.description,
          isOpen: isOpen ?? current.isOpen,
        );

        await _firestore
            .collection(FirebaseConstants.collectionStores)
            .doc(id)
            .update(updated.toMap());

        _stores[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'فشل تعديل المطعم: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStoreStatus(String id, bool isOpen) async {
    try {
      final index = _stores.indexWhere((s) => s.id == id);
      if (index != -1) {
        await _firestore
            .collection(FirebaseConstants.collectionStores)
            .doc(id)
            .update({'isOpen': isOpen});

        _stores[index] = _stores[index].copyWith(isOpen: isOpen);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'فشل تغيير حالة المطعم: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStore(String id) async {
    try {
      final index = _stores.indexWhere((s) => s.id == id);
      if (index != -1) {
        final store = _stores[index];
        if (store.logoUrl != null && store.logoUrl!.isNotEmpty) {
          await FirebaseStorageService.deleteImage(store.logoUrl!);
        }
        if (store.coverUrl != null && store.coverUrl!.isNotEmpty) {
          await FirebaseStorageService.deleteImage(store.coverUrl!);
        }
      }

      await _firestore
          .collection(FirebaseConstants.collectionStores)
          .doc(id)
          .delete();

      _stores.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف المطعم: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
