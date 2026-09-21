import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a Payment Method (e.g. Cash on Delivery, Kuraimi Express, Cash Wallet, Bank Transfer)
class PaymentMethodModel {
  final String id;
  final String name;
  final String description;
  final String accountNumber;
  final bool isActive;
  final int orderIndex;
  final DateTime createdAt;
  final String? storeId;
  final bool isGlobal;

  PaymentMethodModel({
    required this.id,
    required this.name,
    this.description = '',
    this.accountNumber = '',
    this.isActive = true,
    this.orderIndex = 0,
    required this.createdAt,
    this.storeId,
    this.isGlobal = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'accountNumber': accountNumber,
      'isActive': isActive,
      'orderIndex': orderIndex,
      'createdAt': Timestamp.fromDate(createdAt),
      'storeId': storeId,
      'isGlobal': isGlobal,
    };
  }

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      }
    }

    return PaymentMethodModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      isActive: map['isActive'] ?? true,
      orderIndex: (map['orderIndex'] as num?)?.toInt() ?? 0,
      createdAt: parsedDate,
      storeId: map['storeId'],
      isGlobal: map['isGlobal'] ?? true,
    );
  }

  PaymentMethodModel copyWith({
    String? id,
    String? name,
    String? description,
    String? accountNumber,
    bool? isActive,
    int? orderIndex,
    DateTime? createdAt,
    String? storeId,
    bool? isGlobal,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      accountNumber: accountNumber ?? this.accountNumber,
      isActive: isActive ?? this.isActive,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      storeId: storeId ?? this.storeId,
      isGlobal: isGlobal ?? this.isGlobal,
    );
  }
}
