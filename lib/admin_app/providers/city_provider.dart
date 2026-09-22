import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/city_model.dart';

/// Provider for managing Cities in Admin Panel and filtering in Customer App
class CityProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CityModel> _cities = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<CityModel> get cities {
    if (_searchQuery.trim().isEmpty) return _cities;
    final query = _searchQuery.trim().toLowerCase();
    return _cities.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  List<CityModel> get activeCities => cities.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchCities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.collectionCities)
          .get(const GetOptions(source: Source.serverAndCache));

      _cities = snapshot.docs
          .map((doc) => CityModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر جلب المدن: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCity(String name) async {
    try {
      final docRef = _firestore.collection(FirebaseConstants.collectionCities).doc();
      final newCity = CityModel(
        id: docRef.id,
        name: name.trim(),
        isActive: true,
        createdAt: DateTime.now(),
      );

      await docRef.set(newCity.toMap());
      _cities.add(newCity);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إضافة المدينة: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editCity(String id, String newName) async {
    try {
      final index = _cities.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updated = _cities[index].copyWith(name: newName.trim());

        await _firestore
            .collection(FirebaseConstants.collectionCities)
            .doc(id)
            .update({'name': newName.trim()});

        _cities[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'فشل تعديل اسم المدينة: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCity(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.collectionCities)
          .doc(id)
          .delete();

      _cities.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف المدينة: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
