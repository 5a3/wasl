import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/firebase_constants.dart';
import '../../shared/models/notification_model.dart';

/// Provider for Customer App to fetch notifications, listen to real-time broadcasts,
/// store local personal order notifications, and support customer deletion.
class CustomerNotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _keyReadNotificationIds = 'read_notification_ids';
  static const String _keyDeletedNotificationIds = 'deleted_notification_ids';

  List<NotificationModel> _notifications = [];
  Set<String> _readIds = {};
  Set<String> _deletedIds = {};
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<NotificationModel> get notifications => _notifications
      .where((n) => !_deletedIds.contains(n.id))
      .toList();
  bool get isLoading => _isLoading;

  int get unreadCount {
    return notifications.where((n) => !_readIds.contains(n.id)).length;
  }

  bool isRead(String id) => _readIds.contains(id);

  /// Load read, notified, and deleted notifications
  Future<void> fetchNotifications({String? currentCustomerId}) async {
    _subscription?.cancel();

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load local preferences for read/deleted IDs
      final prefs = await SharedPreferences.getInstance();
      final savedReadList = prefs.getStringList(_keyReadNotificationIds) ?? [];
      final savedDeletedList = prefs.getStringList(_keyDeletedNotificationIds) ?? [];

      _readIds = savedReadList.toSet();
      _deletedIds = savedDeletedList.toSet();

      // 2. Start real-time Firestore stream listener for general broadcast notifications
      _subscription = _firestore
          .collection(FirebaseConstants.collectionNotifications)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) async {
        final List<NotificationModel> updatedList = [];

        for (var doc in snapshot.docs) {
          final notification = NotificationModel.fromMap(doc.data(), doc.id);
          final target = notification.targetCustomerId;

          // Strictly keep general broadcast notifications from Firestore (promotions / announcements from admin)
          if (target == null || target.isEmpty) {
            if (!_deletedIds.contains(notification.id)) {
              updatedList.add(notification);
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
