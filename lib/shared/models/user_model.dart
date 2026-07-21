import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer User Model
class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String password; // Unencrypted password as requested
  final bool isBlocked;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
    required this.password,
    this.isBlocked = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'password': password,
      'isBlocked': isBlocked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      username: map['username'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      password: map['password'] ?? '',
      isBlocked: map['isBlocked'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
