/// Category Model supporting Main and Sub categories
class CategoryModel {
  final String id;
  final String name;
  final String? parentId; // null = Main Category, string id = Sub Category
  final String imageUrl;
  final bool isActive;
  final int orderIndex;

  CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.imageUrl,
    this.isActive = true,
    this.orderIndex = 0,
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
    );
  }
}
