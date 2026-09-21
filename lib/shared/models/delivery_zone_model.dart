/// Delivery Zone & Fee Model managed by Admin
class DeliveryZoneModel {
  final String id;
  final String zoneName;
  final double deliveryFee;
  final bool isActive;
  final String? storeId;
  final String? storeName;

  DeliveryZoneModel({
    required this.id,
    required this.zoneName,
    required this.deliveryFee,
    this.isActive = true,
    this.storeId,
    this.storeName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zoneName': zoneName,
      'deliveryFee': deliveryFee,
      'isActive': isActive,
      'storeId': storeId,
      'storeName': storeName,
    };
  }

  factory DeliveryZoneModel.fromMap(Map<String, dynamic> map, String docId) {
    return DeliveryZoneModel(
      id: docId,
      zoneName: map['zoneName'] ?? '',
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
      storeId: map['storeId'],
      storeName: map['storeName'],
    );
  }

  DeliveryZoneModel copyWith({
    String? id,
    String? zoneName,
    double? deliveryFee,
    bool? isActive,
    String? storeId,
    String? storeName,
  }) {
    return DeliveryZoneModel(
      id: id ?? this.id,
      zoneName: zoneName ?? this.zoneName,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isActive: isActive ?? this.isActive,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryZoneModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
