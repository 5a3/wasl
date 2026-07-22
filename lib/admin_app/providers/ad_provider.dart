import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_storage_service.dart';
import '../../../shared/models/ad_model.dart';

/// Provider for managing promotional Ads and their Notifications in Firestore
class AdProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AdModel> _ads = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AdModel> get ads => _ads;
  List<AdModel> get activeAds => _ads.where((a) => a.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AdProvider() {
    fetchAds();
  }

  /// Listen to Ads stream in real-time
  void fetchAds() {
    _isLoading = true;
    notifyListeners();

    _firestore
        .collection('ads')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _ads = snapshot.docs.map((doc) => AdModel.fromMap(doc.data(), doc.id)).toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'خطأ في جلب الإعلانات: ${err.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Add new Ad & sync to Firestore "notafcation" collection
  Future<bool> addAd({
    required String title,
    required dynamic imageFile, // File or Uint8List or URL string
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final adDocRef = _firestore.collection('ads').doc();
      final String uploadedUrl = await FirebaseStorageService.uploadAdImage(
        imageFile: imageFile,
        adTitle: title,
      );

      final now = DateTime.now();
      final newAd = AdModel(
        id: adDocRef.id,
        title: title.trim(),
        imageUrl: uploadedUrl,
        isActive: true,
        createdAt: now,
      );

      // 1. Save in "ads"
      await adDocRef.set(newAd.toMap());

      // 2. Save in "notafcation" as requested by the user
      await _firestore.collection('notafcation').doc(adDocRef.id).set({
        'id': adDocRef.id,
        'title': title.trim(),
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
        'imageUrl': uploadedUrl,
        'notificationType': 'promotion_ad',
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إضافة الإعلان: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update existing Ad, upload new image if changed, delete old image, & sync to "notafcation"
  Future<bool> updateAd({
    required String adId,
    required String title,
    required dynamic imageFile, // File or Uint8List or null if unchanged
    required bool isActive,
    required String existingImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String finalImageUrl = existingImageUrl;

      if (imageFile != null) {
        // Upload new image
        finalImageUrl = await FirebaseStorageService.uploadAdImage(
          imageFile: imageFile,
          adTitle: title,
        );

        // Delete old image
        if (existingImageUrl.isNotEmpty && existingImageUrl.startsWith('http')) {
          await FirebaseStorageService.deleteImage(existingImageUrl);
        }
      }

      final now = DateTime.now();

      // 1. Update "ads" document
      await _firestore.collection('ads').doc(adId).update({
        'title': title.trim(),
        'imageUrl': finalImageUrl,
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(now),
      });

      // 2. Update "notafcation" document
      await _firestore.collection('notafcation').doc(adId).set({
        'id': adId,
        'title': title.trim(),
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(now),
        'imageUrl': finalImageUrl,
        'notificationType': 'promotion_ad',
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل تعديل الإعلان: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle Active status in both Firestore collections
  Future<bool> toggleAdStatus(String adId, bool isActive) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'isActive': isActive,
      });

      await _firestore.collection('notafcation').doc(adId).update({
        'isActive': isActive,
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling ad: $e');
      return false;
    }
  }

  /// Delete Ad from storage, "ads" and "notafcation" collections
  Future<bool> deleteAd(String adId, String imageUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Delete image file
      if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
        await FirebaseStorageService.deleteImage(imageUrl);
      }

      // 2. Delete Firestore doc from "ads"
      await _firestore.collection('ads').doc(adId).delete();

      // 3. Delete Firestore doc from "notafcation"
      await _firestore.collection('notafcation').doc(adId).delete();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف الإعلان: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
