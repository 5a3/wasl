import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfHelper {
  static pw.Font? _cairoRegular;
  static pw.Font? _cairoBold;

  /// Cache and return Amiri Regular font (named cairoRegular to preserve calls)
  static Future<pw.Font> get cairoRegular async {
    _cairoRegular ??= await PdfGoogleFonts.amiriRegular();
    return _cairoRegular!;
  }

  /// Cache and return Amiri Bold font (named cairoBold to preserve calls)
  static Future<pw.Font> get cairoBold async {
    _cairoBold ??= await PdfGoogleFonts.amiriBold();
    return _cairoBold!;
  }

  /// Preload fonts in background (non-blocking)
  static void preloadFonts() async {
    try {
      await cairoRegular;
      await cairoBold;
    } catch (e) {
      debugPrint('Error preloading PDF fonts: $e');
    }
  }

  // Dual-connecting letters
  static const Set<int> _doubleConnecting = {
    0x0628, 0x062A, 0x062B, 0x062C, 0x062D, 0x062E, 0x0633, 0x0634, 0x0635,
    0x0636, 0x0637, 0x0638, 0x0639, 0x063A, 0x0641, 0x0642, 0x0643, 0x0644,
    0x0645, 0x0646, 0x0647, 0x064A, 0x0626,
  };

  // Right-connecting (double or right only)
  static const Set<int> _rightConnecting = {
    0x0622, 0x0623, 0x0624, 0x0625, 0x0627, 0x062F, 0x0630, 0x0631, 0x0632,
    0x0648, 0x0629, 0x0649,
  };

  // Forms map: [Isolated, Final, Initial, Medial]
  static const Map<int, List<int>> _arabicForms = {
    0x0621: [0xFE80, 0xFE80, 0xFE80, 0xFE80], // Hamza
    0x0622: [0xFE81, 0xFE82, 0xFE81, 0xFE82], // Alef Madda
    0x0623: [0xFE83, 0xFE84, 0xFE83, 0xFE84], // Alef Hamza Above
    0x0624: [0xFE85, 0xFE86, 0xFE85, 0xFE86], // Waw Hamza
    0x0625: [0xFE87, 0xFE88, 0xFE87, 0xFE88], // Alef Hamza Below
    0x0626: [0xFE89, 0xFE8A, 0xFE8B, 0xFE8C], // Yeh Hamza
    0x0627: [0xFE8D, 0xFE8E, 0xFE8D, 0xFE8E], // Alef
    0x0628: [0xFE8F, 0xFE90, 0xFE91, 0xFE92], // Beh
    0x0629: [0xFE93, 0xFE94, 0xFE93, 0xFE94], // Teh Marbuta
    0x062A: [0xFE95, 0xFE96, 0xFE97, 0xFE98], // Teh
    0x062B: [0xFE99, 0xFE9A, 0xFE9B, 0xFE9C], // Theh
    0x062C: [0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0], // Jeem
    0x062D: [0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4], // Hah
    0x062E: [0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8], // Khah
    0x062F: [0xFEA9, 0xFEAA, 0xFEA9, 0xFEAA], // Dal
    0x0630: [0xFEAB, 0xFEAC, 0xFEAB, 0xFEAC], // Thal
    0x0631: [0xFEAD, 0xFEAE, 0xFEAD, 0xFEAE], // Reh
    0x0632: [0xFEAF, 0xFEB0, 0xFEAF, 0xFEB0], // Zain
    0x0633: [0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4], // Seen
    0x0634: [0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8], // Sheen
    0x0635: [0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC], // Sad
    0x0636: [0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0], // Dad
    0x0637: [0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4], // Tah
    0x0638: [0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8], // Zah
    0x0639: [0xFEC9, 0xFECA, 0xFECB, 0xFECC], // Ain
    0x063A: [0xFECD, 0xFECE, 0xFECF, 0xFED0], // Ghain
    0x0641: [0xFED1, 0xFED2, 0xFED3, 0xFED4], // Feh
    0x0642: [0xFED5, 0xFED6, 0xFED7, 0xFED8], // Qaf
    0x0643: [0xFED9, 0xFEDA, 0xFEDB, 0xFEDC], // Kaf
    0x0644: [0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0], // Lam
    0x0645: [0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4], // Meem
    0x0646: [0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8], // Noon
    0x0647: [0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC], // Heh
    0x0648: [0xFEED, 0xFEEE, 0xFEED, 0xFEEE], // Waw
    0x0649: [0xFEEF, 0xFEF0, 0xFEEF, 0xFEF0], // Alef Maksura
    0x064A: [0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4], // Yeh (With Dots!)
  };

  /// Check if the char code is a standard Arabic letter we shape
  static bool _isArabicChar(int code) => _arabicForms.containsKey(code);

  /// Custom Arabic text reshaping to resolve pdf package's dotless Yeh and final form bugs
  static String reshapeArabic(String text) {
    if (text.isEmpty) return text;
    final codes = text.codeUnits;
    final len = codes.length;
    final List<int> result = [];

    int i = 0;
    while (i < len) {
      final code = codes[i];

      // Handle Lam-Alef Ligatures (لا, لأ, لإ, لآ)
      if (code == 0x0644 && i < len - 1) {
        final nextCode = codes[i + 1];
        int? ligatureIsolated;
        int? ligatureFinal;

        if (nextCode == 0x0627) { // لا
          ligatureIsolated = 0xFEF5;
          ligatureFinal = 0xFEF6;
        } else if (nextCode == 0x0623) { // لأ
          ligatureIsolated = 0xFEF7;
          ligatureFinal = 0xFEF8;
        } else if (nextCode == 0x0625) { // لإ
          ligatureIsolated = 0xFEF9;
          ligatureFinal = 0xFEFA;
        } else if (nextCode == 0x0622) { // لآ
          ligatureIsolated = 0xFEFB;
          ligatureFinal = 0xFEFC;
        }

        if (ligatureIsolated != null && ligatureFinal != null) {
          // Check if connects to right
          final connectsRight = i > 0 &&
              _isArabicChar(codes[i - 1]) &&
              _doubleConnecting.contains(codes[i - 1]) &&
              (_doubleConnecting.contains(code) || _rightConnecting.contains(code));

          result.add(connectsRight ? ligatureFinal : ligatureIsolated);
          i += 2; // skip both Lam and Alef
          continue;
        }
      }

      if (_isArabicChar(code)) {
        // Connects to right (preceding character)
        final connectsRight = i > 0 &&
            _isArabicChar(codes[i - 1]) &&
            _doubleConnecting.contains(codes[i - 1]) &&
            (_doubleConnecting.contains(code) || _rightConnecting.contains(code));

        // Connects to left (following character)
        final connectsLeft = i < len - 1 &&
            _isArabicChar(codes[i + 1]) &&
            _doubleConnecting.contains(code) &&
            (_doubleConnecting.contains(codes[i + 1]) || _rightConnecting.contains(codes[i + 1]));

        final forms = _arabicForms[code]!;
        int shapedCode;
        if (connectsRight && connectsLeft) {
          shapedCode = forms[3]; // Medial
        } else if (connectsRight) {
          shapedCode = forms[1]; // Final
        } else if (connectsLeft) {
          shapedCode = forms[2]; // Initial
        } else {
          shapedCode = forms[0]; // Isolated
        }

        result.add(shapedCode);
      } else {
        result.add(code);
      }
      i++;
    }

    return String.fromCharCodes(result);
  }
}
