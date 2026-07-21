import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/delivery_zone_model.dart';

/// Provider for Admin to manage Delivery Zones & Fees with full CRUD & Search
class DeliveryZoneProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DeliveryZoneModel> _zones = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<DeliveryZoneModel> get zones {
    if (_searchQuery.trim().isEmpty) return _zones;
    final query = _searchQuery.trim().toLowerCase();
    return _zones.where((z) => z.zoneName.toLowerCase().contains(query)).toList();
  }

  List<DeliveryZoneModel> get activeZones => zones.where((z) => z.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchDeliveryZones() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.collectionDeliveryZones)
          .get(const GetOptions(source: Source.serverAndCache));

      _zones = snapshot.docs
          .map((doc) => DeliveryZoneModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر جلب مناطق التوصيل: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDeliveryZone({
    required String zoneName,
    required double deliveryFee,
  }) async {
    try {
      final docRef = _firestore.collection(FirebaseConstants.collectionDeliveryZones).doc();
      final newZone = DeliveryZoneModel(
        id: docRef.id,
        zoneName: zoneName.trim(),
        deliveryFee: deliveryFee,
        isActive: true,
      );

      await docRef.set(newZone.toMap());
      _zones.add(newZone);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إضافة منطقة التوصيل: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editDeliveryZone({
    required String id,
    required String zoneName,
    required double deliveryFee,
  }) async {
    try {
      final index = _zones.indexWhere((z) => z.id == id);
      if (index != -1) {
        final updated = DeliveryZoneModel(
          id: id,
          zoneName: zoneName.trim(),
          deliveryFee: deliveryFee,
          isActive: _zones[index].isActive,
        );

        await _firestore
            .collection(FirebaseConstants.collectionDeliveryZones)
            .doc(id)
            .update(updated.toMap());

        _zones[index] = updated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'فشل تعديل منطقة التوصيل: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDeliveryZone(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.collectionDeliveryZones)
          .doc(id)
          .delete();

      _zones.removeWhere((z) => z.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف منطقة التوصيل: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
