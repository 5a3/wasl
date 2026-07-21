import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

/// Full-screen offline modal blocking app interactions when connection is lost
class OfflineBannerWrapper extends StatelessWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        return Directionality(
          textDirection: TextDirection.rtl, // Ensure Arabic right-to-left layout
          child: Stack(
            children: [
              child,
              if (!connectivity.isOnline)
                // Modal barrier to block all user interactions
                ModalBarrier(
                  dismissible: false,
                  color: Colors.black.withAlpha(216),
                ),
              if (!connectivity.isOnline)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 12,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.wifi,
                              color: AppColors.danger,
                              size: 70,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'لا يوجد اتصال بالإنترنت!',
                              style: AppFonts.cairoFont(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'يلزم توفر اتصال نشط بالإنترنت لاستخدام تطبيق واصل. يرجى التحقق من اتصال شبكة Wi-Fi أو بيانات الهاتف.',
                              style: AppFonts.cairoFont(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'جاري محاولة إعادة الاتصال تلقائياً...',
                              style: AppFonts.cairoFont(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
