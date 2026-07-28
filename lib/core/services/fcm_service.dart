import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../customer_app/views/notifications/customer_notifications_screen.dart';
import '../../main.dart';
import '../constants/firebase_constants.dart';

/// Background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background Message: ${message.notification?.title}');
}

/// Core service for handling push notifications via Firebase Cloud Messaging & Flutter Local Notifications
class FcmService {
  FcmService._();

  static const String topicAllCustomers = 'all_customers';

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'wasl_notifications_channel',
    'Wasl App Notifications',
    description: 'Notifications for offers, updates, and order alerts',
    importance: Importance.high,
    playSound: true,
  );

  /// Initializes FCM and Local Notifications
  static Future<void> initialize() async {
    // 1. Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Local Notifications initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification clicked: ${response.payload}');
      },
    );

    // 3. Create Android channel
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_channel);
    }

    // 4. Request permissions & subscribe to broadcast topic
    final granted = await requestPermissions(silent: true);
    if (granted) {
      if (!kIsWeb) {
        try {
          await _messaging.subscribeToTopic(topicAllCustomers);
          debugPrint('FCM: Subscribed to topic [$topicAllCustomers]');
        } catch (e) {
          debugPrint('FCM topic subscription note: $e');
        }
      }
    }

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showLocalNotification(
          id: notification.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
        );
      }
    });

    // 6. Handle Background Push Notification Click (opens app normally)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM onMessageOpenedApp clicked: ${message.notification?.title}');
    });

    // 7. Handle Terminated Push Notification Click (opens app normally)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('FCM getInitialMessage clicked: ${message.notification?.title}');
      }
    });
  }

  /// Request Notification Permissions. Returns true if authorized.
  static Future<bool> requestPermissions({bool silent = false}) async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (isAuthorized) {
        if (!kIsWeb) {
          try {
            await _messaging.subscribeToTopic(topicAllCustomers);
          } catch (_) {}
        }
      } else if (!silent) {
        debugPrint('FCM: Notification permission denied.');
      }

      return isAuthorized;
    } catch (e) {
      debugPrint('FCM permission request error: $e');
      return false;
    }
  }

  /// Check current notification permission status
  static Future<bool> hasPermission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Display a local pop-up notification banner
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? notificationId,
  }) async {
    if (notificationId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final list = prefs.getStringList('notified_notification_ids') ?? [];
        if (!list.contains(notificationId)) {
          list.add(notificationId);
          await prefs.setStringList('notified_notification_ids', list);
        }
      } catch (_) {}
    }

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformDetails,
    );
  }

  /// Send broadcast push notification via FCM HTTP API to all subscribed devices
  /// Send broadcast push notification via Google FCM V1 HTTP API to all subscribed devices
  static Future<bool> sendHttpPushNotification({
    required String title,
    required String body,
  }) async {
    try {
      // 1. Try FCM V1 via service_account.json asset if present
      String? jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/service_account.json');
      } catch (e) {
        debugPrint('assets/service_account.json asset not loaded yet: $e');
      }

      if (jsonString != null && jsonString.contains('project_id')) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        final String projectId = jsonMap['project_id'] ?? 'wasl-cdcb6';

        final credentials = ServiceAccountCredentials.fromJson(jsonMap);
        final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
        final authClient = await clientViaServiceAccount(credentials, scopes);
        final accessToken = authClient.credentials.accessToken.data;

        final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'message': {
              'topic': topicAllCustomers,
              'notification': {
                'title': title,
                'body': body,
              },
              'android': {
                'priority': 'HIGH',
                'notification': {
                  'channel_id': _channel.id,
                  'icon': 'ic_launcher',
                  'sound': 'default',
                },
              },
              'data': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'title': title,
                'body': body,
              },
            },
          }),
        );

        debugPrint('FCM V1 Push response: ${response.statusCode} ${response.body}');
        authClient.close();
        if (response.statusCode == 200) return true;
      }

      // 2. Fallback to FCM Legacy API
      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=${FirebaseConstants.fcmServerKey}',
        },
        body: jsonEncode({
          'to': '/topics/$topicAllCustomers',
          'priority': 'high',
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'icon': 'ic_launcher',
            'android_channel_id': _channel.id,
            'channel_id': _channel.id,
            'badge': '1',
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'title': title,
            'body': body,
          },
        }),
      );

      debugPrint('FCM HTTP Push response: ${response.statusCode} ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending FCM Push: $e');
      return false;
    }
  }
}
