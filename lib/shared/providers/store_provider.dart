import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Provider for managing and real-time listening to Store Status (Open/Closed)
class StoreProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _subscription;

  bool _isOpen = true;
  String? _closedReason;
  bool _isLoading = true;

  bool get isOpen => _isOpen;
  String? get closedReason => _closedReason;
  bool get isLoading => _isLoading;

  StoreProvider() {
    _initListener();
  }

  /// Listen to real-time store status changes in Firestore (app_settings/store_status)
  void _initListener() {
    _subscription = _firestore
        .collection('app_settings')
        .doc('store_status')
        .snapshots()
        .listen(
      (snapshot) {
        _isLoading = false;
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          _isOpen = data['isOpen'] ?? true;
          _closedReason = data['closedReason'];
        } else {
          // Default to Open if document doesn't exist yet
          _isOpen = true;
          _closedReason = null;
          _createDefaultDoc();
        }
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        debugPrint('StoreProvider Error: $error');
        notifyListeners();
      },
    );
  }

  /// Create default store_status document if missing
  Future<void> _createDefaultDoc() async {
    try {
      await _firestore.collection('app_settings').doc('store_status').set({
        'isOpen': true,
        'closedReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'system',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creating default store_status doc: $e');
    }
  }

  /// Update Store Status (Open/Closed) and optional custom reason
  Future<void> updateStoreStatus(bool isOpen, {String? reason, String? updatedBy}) async {
    try {
      final cleanReason = reason?.trim().isEmpty ?? true ? null : reason?.trim();
      await _firestore.collection('app_settings').doc('store_status').set({
        'isOpen': isOpen,
        'closedReason': isOpen ? null : cleanReason,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy ?? 'admin',
      }, SetOptions(merge: true));

      _isOpen = isOpen;
      _closedReason = isOpen ? null : cleanReason;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating store status: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
