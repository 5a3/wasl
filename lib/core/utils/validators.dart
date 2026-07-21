/// Form input validation utilities
class Validators {
  Validators._();

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'حقل $fieldName مطلوب';
    }
    return null;
  }

  static String? validateYemeniPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    final cleanPhone = value.trim();
    // Valid Yemeni phone numbers start with 77, 73, 71, 70, or 78 followed by 7 digits (9 digits total)
    final yemeniPhoneRegex = RegExp(r'^(77|73|71|70|78)[0-9]{7}$');
    if (!yemeniPhoneRegex.hasMatch(cleanPhone)) {
      return 'يرجى إدخال رقم هاتف يمني صحيح (مثال: 771234567)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'يجب أن لا تقل كلمة المرور عن 6 أحرف/أرقام';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String originalPassword) {
    final passwordError = validatePassword(value);
    if (passwordError != null) return passwordError;
    if (value != originalPassword) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  static String? validateEmailOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
  }
}
