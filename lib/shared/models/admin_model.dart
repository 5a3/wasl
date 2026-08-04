import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/admin_permissions.dart';

/// Admin User Model with Role-based Access Control & Granular Permissions
class AdminModel {
  final String id;
  final String username;
  final String password; // Unencrypted password as requested
  final String fullName;
  final String role; // 'super_admin' or 'sub_admin'
  final List<String> permissions;
  final DateTime createdAt;

  late final List<String> effectivePermissions;

  AdminModel({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    required this.permissions,
    required this.createdAt,
  }) {
    effectivePermissions = AdminPermissions.normalizePermissions(permissions);
  }

  bool get isSuperAdmin => role == 'super_admin';

  /// Check if admin has a specific granular permission
  bool hasPermission(String permKey) {
    if (isSuperAdmin) return true;
    return effectivePermissions.contains(permKey);
  }

  /// Check if admin has AT LEAST ONE of the given permissions
  bool hasAnyPermission(List<String> permKeys) {
    if (isSuperAdmin) return true;
    return permKeys.any((key) => effectivePermissions.contains(key));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map, String docId) {
    return AdminModel(
      id: docId,
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'sub_admin',
      permissions: List<String>.from(map['permissions'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
