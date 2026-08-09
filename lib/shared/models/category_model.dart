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
    );
  }
}
