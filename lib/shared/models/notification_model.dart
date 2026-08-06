import 'package:cloud_firestore/cloud_firestore.dart';

/// Single read receipt entry for tracking which customer read a notification
class NotificationReceipt {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final DateTime readAt;

  NotificationReceipt({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.readAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'readAt': Timestamp.fromDate(readAt),
    };
  }

  factory NotificationReceipt.fromMap(Map<String, dynamic> map) {
    return NotificationReceipt(
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? 'عميل',
      customerPhone: map['customerPhone'] ?? '',
      readAt: (map['readAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Model for broadcast notifications sent by admin to users
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String sentBy;
  final String? targetCustomerId; // null for general broadcast, customerId for personal
  final List<NotificationReceipt> readReceipts;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.sentBy,
    this.targetCustomerId,
    this.readReceipts = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'sentBy': sentBy,
      if (targetCustomerId != null) 'targetCustomerId': targetCustomerId,
      'readReceipts': readReceipts.map((r) => r.toMap()).toList(),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawReceipts = map['readReceipts'] as List<dynamic>? ?? [];
    final receipts = rawReceipts
        .whereType<Map<String, dynamic>>()
        .map((r) => NotificationReceipt.fromMap(r))
        .toList();

    return NotificationModel(
      id: docId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentBy: map['sentBy'] ?? '',
      targetCustomerId: map['targetCustomerId'],
      readReceipts: receipts,
    );
  }
}
