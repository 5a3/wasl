/// Delivery Zone & Fee Model managed by Admin
class DeliveryZoneModel {
  final String id;
  final String zoneName;
  final double deliveryFee;
  final bool isActive;

  DeliveryZoneModel({
    required this.id,
    required this.zoneName,
    required this.deliveryFee,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zoneName': zoneName,
      'deliveryFee': deliveryFee,
      'isActive': isActive,
    };
  }

  factory DeliveryZoneModel.fromMap(Map<String, dynamic> map, String docId) {
    return DeliveryZoneModel(
      id: docId,
      zoneName: map['zoneName'] ?? '',
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
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
