import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

class InAppUpdateService {
  /// Checks Google Play for available In-App Updates on Android.
  /// Performs Flexible Update (in background) or Immediate Update smoothly.
  static Future<void> checkForUpdate(BuildContext context) async {
    // In-App Update is exclusive to Android platform builds
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          // Mandatory / Immediate Update Flow
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          // Flexible / Background Download Update Flow
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success && context.mounted) {
            _showCompleteUpdateSnackbar(context);
          }
        }
      }
    } catch (e) {
      // Graceful fallback for debug / sideloaded builds
      debugPrint('InAppUpdate service notice: $e');
    }
  }

  /// Displays a SnackBar when a flexible update download completes
  static void _showCompleteUpdateSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم تنزيل التحديث الجديد جاهز للتثبيت 🚀',
                style: AppFonts.cairoFont(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(days: 1), // Remains until user taps
        action: SnackBarAction(
          label: 'تثبيت الآن',
          textColor: Colors.amber,
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
      ),
    );
  }
}
