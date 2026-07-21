import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for uploading category and product images to Firebase Storage with custom path structures
class FirebaseStorageService {
  FirebaseStorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload Category Image to: `main/<category_name>/<category_name>_<timestamp>.jpg`
  static Future<String> uploadCategoryImage({
    required dynamic imageFile, // File (Mobile) or Uint8List (Web)
    required String categoryName,
  }) async {
    try {
      final cleanCategoryName = categoryName.trim().replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '_');
      final fileName = '${cleanCategoryName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'main/$cleanCategoryName/$fileName';

      final ref = _storage.ref().child(storagePath);
      UploadTask uploadTask;

      if (kIsWeb && imageFile is Uint8List) {
        uploadTask = ref.putData(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      } else if (imageFile is File) {
        uploadTask = ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      } else if (imageFile is String && imageFile.startsWith('http')) {
        return imageFile; // Already a URL
      } else {
        throw 'نوع الملف غير مدعوم للرفع';
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.message?.contains('404') == true) {
        throw 'لم يتم إنشَاء خدمة Storage على وحدة تحكم Firebase (wasl-cdcb6). يرجى الضغط على Storage -> Get Started وتفعيل قواعد الأمان.';
      }
      throw 'خطأ رفع الصورة (${e.code}): ${e.message}';
    } catch (e) {
      throw 'فشل رفع الصورة: ${e.toString()}';
    }
  }

  /// Upload Product Image under Category folder to: `<category_name>/<product_name>_<image_index>_<timestamp>.jpg`
  static Future<String> uploadProductImage({
    required dynamic imageFile, // File or Uint8List or URL String
    required String categoryName,
    required String productName,
    required int imageIndex,
  }) async {
    if (imageFile is String && imageFile.startsWith('http')) {
      return imageFile; // If user entered a direct web URL
    }

    try {
      final cleanCatName = categoryName.trim().replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '_');
      final cleanProdName = productName.trim().replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '_');
      final fileName = '${cleanProdName}_${imageIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '$cleanCatName/$fileName';

      final ref = _storage.ref().child(storagePath);
      UploadTask uploadTask;

      if (kIsWeb && imageFile is Uint8List) {
        uploadTask = ref.putData(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      } else if (imageFile is File) {
        uploadTask = ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        throw 'نوع الملف غير مدعوم للرفع';
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.message?.contains('404') == true) {
        throw 'لم يتم تفعيل Firebase Storage في مشروع wasl-cdcb6! يرجى إنشاؤها وتعديل الـ Rules في Firebase Console.';
      }
      throw 'خطأ رفع صورة المنتج: ${e.message}';
    } catch (e) {
      throw 'فشل رفع صورة المنتج: ${e.toString()}';
    }
  }
}
