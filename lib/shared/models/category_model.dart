/// Category Model supporting Main and Sub categories with discount support
class CategoryModel {
  final String id;
  final String name;
  final String? parentId; // null = Main Category, string id = Sub Category
  final String imageUrl;
  final bool isActive;
  final int orderIndex;
  final bool hasDiscount;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final String? storeId;
  final String? storeName;

  CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.imageUrl,
    this.isActive = true,
    this.orderIndex = 0,
    this.hasDiscount = false,
    this.discountType = 'percentage',
    this.discountValue = 0.0,
    this.storeId,
    this.storeName,
  });

  bool get isMainCategory => parentId == null || parentId!.isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'orderIndex': orderIndex,
      'hasDiscount': hasDiscount,
      'discountType': discountType,
      'discountValue': discountValue,
      'storeId': storeId,
      'storeName': storeName,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryModel(
      id: docId,
      name: map['name'] ?? '',
      parentId: map['parentId'],
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      orderIndex: map['orderIndex'] ?? 0,
      hasDiscount: map['hasDiscount'] ?? false,
      discountType: map['discountType'] ?? 'percentage',
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
      storeId: map['storeId'],
      storeName: map['storeName'],
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? parentId,
    String? imageUrl,
    bool? isActive,
    int? orderIndex,
    bool? hasDiscount,
    String? discountType,
    double? discountValue,
    String? storeId,
    String? storeName,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      orderIndex: orderIndex ?? this.orderIndex,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
    );
  }
}
