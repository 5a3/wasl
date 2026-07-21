import 'package:cloud_firestore/cloud_firestore.dart';

/// Product Model supporting max 3 images and availability toggle
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String mainCategoryId;
  final String subCategoryId;
  final List<String> images; // Up to 3 images
  final bool isAvailable;
  final int salesCount;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.mainCategoryId,
    required this.subCategoryId,
    required this.images,
    this.isAvailable = true,
    this.salesCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'mainCategoryId': mainCategoryId,
      'subCategoryId': subCategoryId,
      'images': images,
      'isAvailable': isAvailable,
      'salesCount': salesCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      mainCategoryId: map['mainCategoryId'] ?? '',
      subCategoryId: map['subCategoryId'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      salesCount: map['salesCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
