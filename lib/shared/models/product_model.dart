import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_model.dart';

/// Product Model supporting max 3 images, availability toggle, and product/category level discounts
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
  final bool hasDiscount;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final DateTime createdAt;
  final String? storeId;
  final String? storeName;

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
    this.hasDiscount = false,
    this.discountType = 'percentage',
    this.discountValue = 0.0,
    required this.createdAt,
    this.storeId,
    this.storeName,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? mainCategoryId,
    String? subCategoryId,
    List<String>? images,
    bool? isAvailable,
    int? salesCount,
    bool? hasDiscount,
    String? discountType,
    double? discountValue,
    DateTime? createdAt,
    String? storeId,
    String? storeName,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      mainCategoryId: mainCategoryId ?? this.mainCategoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      salesCount: salesCount ?? this.salesCount,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      createdAt: createdAt ?? this.createdAt,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
    );
  }

  /// Check if an effective discount is active for this product (direct or via category)
  bool hasEffectiveDiscount(CategoryModel? category) {
    if (hasDiscount && discountValue > 0) return true;
    if (category != null && category.hasDiscount && category.discountValue > 0) return true;
    return false;
  }

  /// Calculates the final discounted price after applying product or category level discounts
  double getEffectivePrice(CategoryModel? category) {
    if (hasDiscount && discountValue > 0) {
      if (discountType == 'percentage') {
        final calc = price * (1 - (discountValue / 100));
        return calc < 0 ? 0.0 : calc;
      } else {
        final calc = price - discountValue;
        return calc < 0 ? 0.0 : calc;
      }
    } else if (category != null && category.hasDiscount && category.discountValue > 0) {
      if (category.discountType == 'percentage') {
        final calc = price * (1 - (category.discountValue / 100));
        return calc < 0 ? 0.0 : calc;
      } else {
        final calc = price - category.discountValue;
        return calc < 0 ? 0.0 : calc;
      }
    }
    return price;
  }

  /// Returns total money saved per item
  double getSavingsAmount(CategoryModel? category) {
    final effective = getEffectivePrice(category);
    final savings = price - effective;
    return savings < 0 ? 0.0 : savings;
  }

  /// Returns localized text for discount badge (e.g., "خصم 20%" or "خصم 500 ر.ي")
  String getDiscountBadgeText(CategoryModel? category) {
    if (hasDiscount && discountValue > 0) {
      if (discountType == 'percentage') {
        return 'خصم ${discountValue.toStringAsFixed(0)}%';
      } else {
        return 'خصم ${discountValue.toStringAsFixed(0)} ر.ي';
      }
    } else if (category != null && category.hasDiscount && category.discountValue > 0) {
      if (category.discountType == 'percentage') {
        return 'خصم ${category.discountValue.toStringAsFixed(0)}%';
      } else {
        return 'خصم ${category.discountValue.toStringAsFixed(0)} ر.ي';
      }
    }
    return '';
  }

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
      'hasDiscount': hasDiscount,
      'discountType': discountType,
      'discountValue': discountValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'storeId': storeId,
      'storeName': storeName,
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
      hasDiscount: map['hasDiscount'] ?? false,
      discountType: map['discountType'] ?? 'percentage',
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      storeId: map['storeId'],
      storeName: map['storeName'],
    );
  }
}
