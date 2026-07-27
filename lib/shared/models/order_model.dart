import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Single item inside an order or cart
class OrderItemModel {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}

/// Full Order Model tracking all order states
class OrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String deliveryZoneId;
  final String deliveryZoneName;
  final double deliveryFee;
  final double subtotal;
  final double totalAmount;
  final String status; // pending, accepted_preparing, delivering, delivered, canceled
  final List<OrderItemModel> items;
  final String? note;
  final String? additionalPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.deliveryZoneId,
    required this.deliveryZoneName,
    required this.deliveryFee,
    required this.subtotal,
    required this.totalAmount,
    required this.status,
    required this.items,
    this.note,
    this.additionalPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusArabic {
    switch (status) {
      case AppConstants.statusPending:
        return AppConstants.statusPendingAr;
      case AppConstants.statusAcceptedPreparing:
        return AppConstants.statusAcceptedPreparingAr;
      case AppConstants.statusDelivering:
        return AppConstants.statusDeliveringAr;
      case AppConstants.statusDelivered:
        return AppConstants.statusDeliveredAr;
      case AppConstants.statusCanceled:
        return AppConstants.statusCanceledAr;
      default:
        return 'غير معروف';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'deliveryZoneId': deliveryZoneId,
      'deliveryZoneName': deliveryZoneName,
      'deliveryFee': deliveryFee,
      'subtotal': subtotal,
      'totalAmount': totalAmount,
      'status': status,
      'items': items.map((x) => x.toMap()).toList(),
      'note': note,
      'additionalPhone': additionalPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    return OrderModel(
      id: docId,
      orderNumber: map['orderNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? '',
      deliveryZoneId: map['deliveryZoneId'] ?? '',
      deliveryZoneName: map['deliveryZoneName'] ?? '',
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? AppConstants.statusPending,
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      note: map['note'],
      additionalPhone: map['additionalPhone'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
