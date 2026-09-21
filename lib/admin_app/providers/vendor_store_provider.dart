import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/firebase_storage_service.dart';
import '../../shared/models/store_model.dart';

class VendorStoreProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<StoreModel> _stores = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;
  String _searchQuery = '';
  String? _selectedStoreId;

  List<StoreModel> get stores {
    if (_searchQuery.trim().isEmpty) return _stores;
    final query = _searchQuery.trim().toLowerCase();
    return _stores.where((s) => s.name.toLowerCase().contains(query)).toList();
  }

  List<StoreModel> get rawStores => _stores;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error;
  String get searchQuery => _searchQuery;
  String? get selectedStoreId => _selectedStoreId;

  VendorStoreProvider() {
    listenToStores();
  }

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
    listenToStores();
  }

  void listenToStores() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _firestore
        .collection(FirebaseConstants.collectionStores)
        .snapshots()
        .listen(
      (snapshot) {
        _stores = snapshot.docs
            .map((doc) => StoreModel.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        _error = err.toString();
        notifyListeners();
      },
    );
  }

  Future<bool> addStore(dynamic nameOrStore, {
    String? logoUrl,
    String? coverUrl,
    String? phone,
    String? address,
    String? description,
    bool isOpen = true,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (nameOrStore is StoreModel) {
        final docRef = _firestore.collection(FirebaseConstants.collectionStores).doc();
        final newStore = nameOrStore.copyWith(id: docRef.id);
        await docRef.set(newStore.toMap());
      } else {
        final docRef = _firestore.collection(FirebaseConstants.collectionStores).doc();
        final newStore = StoreModel(
          id: docRef.id,
          name: (nameOrStore as String).trim(),
          logoUrl: logoUrl,
          coverUrl: coverUrl,
          phone: phone?.trim(),
          address: address?.trim(),
          description: description?.trim(),
          isOpen: isOpen,
          createdAt: DateTime.now(),
        );
        await docRef.set(newStore.toMap());
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStore(StoreModel store) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection(FirebaseConstants.collectionStores)
          .doc(store.id)
          .update(store.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
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
    String? address,
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
          address: address?.trim() ?? current.address,
          description: description?.trim() ?? current.description,
          isOpen: isOpen ?? current.isOpen,
        );

        await _firestore
            .collection(FirebaseConstants.collectionStores)
            .doc(id)
            .update(updated.toMap());

        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStoreStatus(String storeId, bool isOpen) async {
    try {
      await _firestore
          .collection(FirebaseConstants.collectionStores)
          .doc(storeId)
          .update({'isOpen': isOpen});
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStore(String storeId) async {
    try {
      final index = _stores.indexWhere((s) => s.id == storeId);
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
          .doc(storeId)
          .delete();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
