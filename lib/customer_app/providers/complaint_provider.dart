import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../shared/models/complaint_model.dart';
import '../../shared/models/user_model.dart';

/// Provider for managing Customer Complaints & Suggestions with 2/day rate-limiting
class ComplaintProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _complaintsSubscription;

  List<ComplaintModel> _complaints = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ComplaintProvider() {
    listenToComplaints();
  }

  /// Real-time live listener for all complaints (for Admin)
  void listenToComplaints() {
    _isLoading = true;
    notifyListeners();

    _complaintsSubscription?.cancel();
    _complaintsSubscription = _firestore
        .collection('complaints')
        .snapshots()
        .listen(
      (snapshot) {
        _complaints = snapshot.docs
            .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
            .toList();

        // Sort locally from newest to oldest
        _complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'خطأ في جلب الشكاوى: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Check how many complaints a customer has submitted today
  Future<int> getTodayComplaintsCount(String customerId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('complaints')
          .where('customerId', isEqualTo: customerId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      // Fallback local memory check if index not built
      final now = DateTime.now();
      return _complaints.where((c) =>
        c.customerId == customerId &&
        c.createdAt.year == now.year &&
        c.createdAt.month == now.month &&
        c.createdAt.day == now.day
      ).length;
    }
  }

  /// Submit New Complaint / Suggestion with full customer location details (Max 2 per day)
  Future<bool> submitComplaint({
    required UserModel customer,
    required String type,
    required String message,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Verify rate limit (max 2 per day)
      final todayCount = await getTodayComplaintsCount(customer.id);
      if (todayCount >= 2) {
        _errorMessage = 'انتهت محاولاتك اليوم لإرسال الشكاوى (الحد الأقصى 2 في اليوم)';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Add to Firestore with full customer details
      final docRef = _firestore.collection('complaints').doc();
      final newComplaint = ComplaintModel(
        id: docRef.id,
        customerId: customer.id,
        customerName: customer.fullName,
        customerPhone: customer.phone,
        customerAddress: customer.address,
        deliveryZoneName: '', // Optional
        type: type,
        message: message.trim(),
        createdAt: DateTime.now(),
      );

      await docRef.set(newComplaint.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل إرسال الشكوى: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a complaint document (for Admin cleanup)
  Future<bool> deleteComplaint(String complaintId) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).delete();
      _complaints.removeWhere((c) => c.id == complaintId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حذف الشكوى: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    super.dispose();
  }
}
