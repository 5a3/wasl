import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/services/fcm_service.dart';
import '../../shared/models/notification_model.dart';

/// Provider for Admin to send, view, and delete broadcast notifications
class AdminNotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Fetch all notifications from Firestore
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.collectionNotifications)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _errorMessage = 'فشل تحميل الإشعارات: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create and broadcast a new notification
  Future<bool> sendNotification({
    required String title,
    required String body,
    required String sentBy,
  }) async {
    if (title.trim().isEmpty || body.trim().isEmpty) {
      _errorMessage = 'يرجى إدخال عنوان ونص الإشعار';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final docRef = _firestore.collection(FirebaseConstants.collectionNotifications).doc();
      final now = DateTime.now();

      final notification = NotificationModel(
        id: docRef.id,
        title: title.trim(),
        body: body.trim(),
        createdAt: now,
        sentBy: sentBy,
      );

      await docRef.set(notification.toMap());

      // Send real Push Notification to all subscribed devices
      final pushSuccess = await FcmService.sendHttpPushNotification(
        title: title.trim(),
        body: body.trim(),
      );

      _notifications.insert(0, notification);
      if (pushSuccess) {
        _successMessage = 'تم إرسال الإشعار وبثه بنجاح لجميع الجوالات! 🚀';
      } else {
        _successMessage = 'تم حفظ الإشعار في التطبيق بنجاح ✅';
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إرسال الإشعار: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a single notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.collectionNotifications)
          .doc(notificationId)
          .delete();
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف الإشعار: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delete selected notifications in bulk
  Future<bool> deleteSelectedNotifications(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return true;
    _isLoading = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      for (final id in notificationIds) {
        final docRef = _firestore.collection(FirebaseConstants.collectionNotifications).doc(id);
        batch.delete(docRef);
      }
      await batch.commit();

      _notifications.removeWhere((n) => notificationIds.contains(n.id));
      _successMessage = 'تم حذف الإشعارات المحددة بنجاح 🗑️';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف الإشعارات المحددة: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete all notifications in bulk
  Future<bool> deleteAllNotifications() async {
    if (_notifications.isEmpty) return true;
    _isLoading = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      for (final n in _notifications) {
        final docRef = _firestore.collection(FirebaseConstants.collectionNotifications).doc(n.id);
        batch.delete(docRef);
      }
      await batch.commit();

      _notifications.clear();
      _successMessage = 'تم مسح جميع الإشعارات بنجاح 🗑️';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف جميع الإشعارات: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
