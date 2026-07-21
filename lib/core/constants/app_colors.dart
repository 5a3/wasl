import 'package:flutter/material.dart';

/// App color palette supporting Light & Dark themes with premium gradients
class AppColors {
  AppColors._();

  // Primary & Secondary Brand Colors (Fast food & Refreshment Theme)
  static const Color primary = Color(0xFFFF6B00); // Warm Vibrant Amber / Orange
  static const Color primaryDark = Color(0xFFD35400);
  static const Color primaryLight = Color(0xFFFF8E3C);
  static const Color accent = Color(0xFFFFC107); // Golden Amber

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E232A);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightBorder = Color(0xFFE9ECEF);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121418);
  static const Color darkSurface = Color(0xFF1E2229);
  static const Color darkSurfaceLight = Color(0xFF2C323D);
  static const Color darkTextPrimary = Color(0xFFF8F9FA);
  static const Color darkTextSecondary = Color(0xFFA0AEC0);
  static const Color darkBorder = Color(0xFF2D3748);

  // Status Colors
  static const Color success = Color(0xFF2ECC71); // Green (Delivered)
  static const Color warning = Color(0xFFF39C12); // Orange/Yellow (Preparing)
  static const Color info = Color(0xFF3498DB); // Blue (Delivering)
  static const Color pending = Color(0xFFE67E22); // Deep Amber (Pending)
  static const Color danger = Color(0xFFE74C3C); // Red (Canceled)

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFFF8800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFF9F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
