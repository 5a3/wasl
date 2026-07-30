import 'package:cloud_firestore/cloud_firestore.dart';

/// Data Model for Customer Complaints & Suggestions
class ComplaintModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String deliveryZoneName;
  final String type; // "شكوى", "مقترح", "استفسار"
  final String message;
  final DateTime createdAt;

  const ComplaintModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress = '',
    this.deliveryZoneName = '',
    required this.type,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'deliveryZoneName': deliveryZoneName,
      'type': type,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String docId) {
    return ComplaintModel(
      id: docId,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      deliveryZoneName: map['deliveryZoneName'] ?? '',
      type: map['type'] ?? 'شكوى',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
