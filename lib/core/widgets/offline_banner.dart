import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

/// Top banner notifying user whenever internet connection is lost
class OfflineBannerWrapper extends StatelessWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        return Column(
          children: [
            if (!connectivity.isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: AppColors.danger,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'لا يوجد اتصال بالإنترنت! يرجى التحقق من الشبكة',
                        style: AppFonts.cairoFont(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
