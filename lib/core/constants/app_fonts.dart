import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography using Google Fonts Cairo for full Arabic aesthetics
class AppFonts {
  AppFonts._();

  static TextStyle cairoFont({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  static TextTheme textTheme(Color textColor) {
    return TextTheme(
      headlineLarge: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
      titleLarge: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
      titleMedium: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.normal, color: textColor),
      bodyMedium: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.normal, color: textColor),
      labelLarge: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
    );
  }
}
