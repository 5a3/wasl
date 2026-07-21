import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/delivery_zone_model.dart';

/// Provider for Admin to manage Delivery Zones & Fees (e.g. داخل حريضة)
class DeliveryZoneProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DeliveryZoneModel> _zones = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DeliveryZoneModel> get zones => _zones;
  List<DeliveryZoneModel> get activeZones => _zones.where((z) => z.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
}
