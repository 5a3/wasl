import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firebase_storage_service.dart';
import '../../../shared/models/ad_model.dart';

/// Provider for managing promotional Ads in Firestore ("ads" collection only)
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

  /// Listen to Ads stream in real-time from "ads" collection
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

  /// Add new Ad to "ads" collection only
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

      // Save ONLY in "ads" collection
      await adDocRef.set(newAd.toMap());

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

  /// Update existing Ad in "ads" collection.
  /// Safely handles image updates without deleting the existing image if no new file is picked.
  Future<bool> updateAd({
    required String adId,
    required String title,
    required dynamic imageFile, // File or Uint8List or new URL string (or null/existing url)
    required bool isActive,
    required String existingImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String finalImageUrl = existingImageUrl;

      // Check if a NEW image file or new URL was actually provided by user
      final bool isNewImageSelected = imageFile != null &&
          imageFile != existingImageUrl &&
          (imageFile is File || imageFile is Uint8List || (imageFile is String && imageFile.startsWith('http')));

      if (isNewImageSelected) {
        // Upload new image to Storage under ads/<title>_<timestamp>.jpg
        finalImageUrl = await FirebaseStorageService.uploadAdImage(
          imageFile: imageFile,
          adTitle: title,
        );

        // Safely delete old image ONLY after new image uploaded successfully
        if (existingImageUrl.isNotEmpty && existingImageUrl.startsWith('http') && existingImageUrl != finalImageUrl) {
          await FirebaseStorageService.deleteImage(existingImageUrl);
        }
      }

      final now = DateTime.now();

      // Update document ONLY in "ads" collection
      await _firestore.collection('ads').doc(adId).update({
        'title': title.trim(),
        'imageUrl': finalImageUrl,
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(now),
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

  /// Toggle Active status in "ads" collection only
  Future<bool> toggleAdStatus(String adId, bool isActive) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'isActive': isActive,
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling ad: $e');
      return false;
    }
  }

  /// Delete Ad from Storage & "ads" collection only
  Future<bool> deleteAd(String adId, String imageUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Delete image file from Firebase Storage
      if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
        await FirebaseStorageService.deleteImage(imageUrl);
      }

      // 2. Delete document from "ads" collection
      await _firestore.collection('ads').doc(adId).delete();

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
