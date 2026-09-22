import 'package:cloud_firestore/cloud_firestore.dart';

/// City Model managed by Admin for store location filtering
class CityModel {
  final String id;
  final String name;
  final bool isActive;
  final DateTime? createdAt;

  CityModel({
    required this.id,
    required this.name,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory CityModel.fromMap(Map<String, dynamic> map, String docId) {
    return CityModel(
      id: docId,
      name: map['name'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  CityModel copyWith({
    String? id,
    String? name,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
