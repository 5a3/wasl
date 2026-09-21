import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String? coverUrl;
  final String? phone;
  final String? address;
  final String? description;
  final bool isOpen;
  final double rating;
  final DateTime? createdAt;

  StoreModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.coverUrl,
    this.phone,
    this.address,
    this.description,
    this.isOpen = true,
    this.rating = 5.0,
    this.createdAt,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map, String id) {
    return StoreModel(
      id: id,
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'],
      coverUrl: map['coverUrl'],
      phone: map['phone'],
      address: map['address'],
      description: map['description'],
      isOpen: map['isOpen'] ?? true,
      rating: (map['rating'] ?? 5.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'coverUrl': coverUrl,
      'phone': phone,
      'address': address,
      'description': description,
      'isOpen': isOpen,
      'rating': rating,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  StoreModel copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? coverUrl,
    String? phone,
    String? address,
    String? description,
    bool? isOpen,
    double? rating,
    DateTime? createdAt,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      description: description ?? this.description,
      isOpen: isOpen ?? this.isOpen,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
