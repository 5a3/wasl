import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/fcm_service.dart';
import '../../shared/models/notification_model.dart';

/// Provider for Customer App to fetch notifications, listen to real-time broadcasts,
/// trigger pop-up banners, and track per-customer read/unread status.
class CustomerNotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _keyReadNotificationIds = 'read_notification_ids';
  static const String _keyNotifiedNotificationIds = 'notified_notification_ids';

  List<NotificationModel> _notifications = [];
  Set<String> _readIds = {};
  Set<String> _notifiedIds = {};
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount {
    return _notifications.where((n) => !_readIds.contains(n.id)).length;
  }

  bool isRead(String id) => _readIds.contains(id);

  /// Load read and notified notification IDs and start real-time Firestore stream listener
  Future<void> fetchNotifications() async {
    if (_subscription != null) return; // Already listening

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load local read & notified notification IDs from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedReadList = prefs.getStringList(_keyReadNotificationIds) ?? [];
      final savedNotifiedList = prefs.getStringList(_keyNotifiedNotificationIds) ?? [];

      _readIds = savedReadList.toSet();
      _notifiedIds = savedNotifiedList.toSet();

      bool isInitialLoad = true;

      // 2. Start real-time Firestore stream listener
      _subscription = _firestore
          .collection(FirebaseConstants.collectionNotifications)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) async {
        final List<NotificationModel> updatedList = [];

        for (var doc in snapshot.docs) {
          final notification = NotificationModel.fromMap(doc.data(), doc.id);
          updatedList.add(notification);
        }

        if (isInitialLoad) {
          // On initial app launch / login load: record all existing IDs as notified
          for (var n in updatedList) {
            _notifiedIds.add(n.id);
          }
          isInitialLoad = false;
          _saveNotifiedIds();
        } else {
          // Record newly added notification IDs silently for state tracking
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final doc = change.doc;
              final notification = NotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              if (!_notifiedIds.contains(notification.id)) {
                _notifiedIds.add(notification.id);
                _saveNotifiedIds();
              }
            }
          }
        }

        _notifications = updatedList;
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint('Error in notification stream listener: $e');
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing notification provider: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persist notified IDs to SharedPreferences
  Future<void> _saveNotifiedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyNotifiedNotificationIds, _notifiedIds.toList());
    } catch (e) {
      debugPrint('Error saving notified notification IDs: $e');
    }
  }

  /// Mark notification as read, persist locally, and push read receipt to Firestore
  Future<void> markAsRead(
    String notificationId, {
    String? customerId,
    String? customerName,
    String? customerPhone,
  }) async {
    if (_readIds.contains(notificationId)) return;

    _readIds.add(notificationId);
    notifyListeners();

    try {
      // 1. Save read ID locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyReadNotificationIds, _readIds.toList());

      // 2. Push read receipt entry to Firestore if customer info is available
      if (customerName != null && customerName.isNotEmpty) {
        final receipt = NotificationReceipt(
          customerId: customerId ?? '',
          customerName: customerName,
          customerPhone: customerPhone ?? '',
          readAt: DateTime.now(),
        );

        await _firestore
            .collection(FirebaseConstants.collectionNotifications)
            .doc(notificationId)
            .update({
          'readReceipts': FieldValue.arrayUnion([receipt.toMap()]),
        });
      }
    } catch (e) {
      debugPrint('Error recording read receipt: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
