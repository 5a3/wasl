import 'package:cloud_firestore/cloud_firestore.dart';

/// Ad Model for slider promotions
class AdModel {
  final String id;
  final String title;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;

  AdModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AdModel.fromMap(Map<String, dynamic> map, String docId) {
    return AdModel(
      id: docId,
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
