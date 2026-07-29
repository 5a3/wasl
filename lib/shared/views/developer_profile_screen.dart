import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

/// Official Developer Profile Screen for Eng. Ahmed Al-Attas
class DeveloperProfileScreen extends StatelessWidget {
  const DeveloperProfileScreen({super.key});

  /// Launch General URLs (Websites, Email, Social)
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح الرابط، يرجى المحاولة لاحقاً',
              style: AppFonts.cairoFont(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Launch WhatsApp via Native Android Chooser (whatsapp://send Scheme)
  Future<void> _launchWhatsApp(BuildContext context, String rawPhone) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    const message = 'مرحباً م. أحمد العطاس، أود التواصل معك من خلال تطبيق وصل لي.';
    final encodedMsg = Uri.encodeComponent(message);

    final schemeUrl = Uri.parse('whatsapp://send?phone=$phone&text=$encodedMsg');
    final webUrl = Uri.parse('https://wa.me/$phone?text=$encodedMsg');

    try {
      if (await canLaunchUrl(schemeUrl)) {
        await launchUrl(
          schemeUrl,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } else {
        await launchUrl(
          webUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح تطبيق الواتساب، يرجى المحاولة لاحقاً',
              style: AppFonts.cairoFont(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'مطور التطبيق',
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Profile Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.darkSurface,
                          AppColors.primary.withAlpha(80),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.primary.withAlpha(210),
                        ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary.withAlpha(20),
                      child: Text(
                        'أ',
                        style: AppFonts.cairoFont(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Engineer Name
                  Text(
                    'م. أحمد العطاس',
                    textAlign: TextAlign.center,
                    style: AppFonts.cairoFont(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle Title
                  Text(
                    'Eng. Ahmed Al-Attas',
                    textAlign: TextAlign.center,
                    style: AppFonts.cairoFont(
                      fontSize: 14,
                      color: Colors.white.withAlpha(220),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Main Content Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Social & Contact Channels
                  _buildSectionHeader(context, 'قنوات التواصل الحسابات الرسمية', Icons.contact_phone_outlined),
                  const SizedBox(height: 12),

                  // WhatsApp Primary (Separate Card 1)
                  _buildContactCard(
                    context,
                    title: 'واتساب التواصل الأساسي',
                    subtitle: '+967 716226912',
                    icon: FontAwesomeIcons.whatsapp,
                    iconColor: const Color(0xFF25D366),
                    bgColor: const Color(0xFF25D366).withAlpha(18),
                    onTap: () => _launchWhatsApp(context, '967716226912'),
                  ),

                  // WhatsApp Secondary (Separate Card 2)
                  _buildContactCard(
                    context,
                    title: 'واتساب الدعم الفني المباشر',
                    subtitle: '+967 770985114',
                    icon: FontAwesomeIcons.whatsapp,
                    iconColor: const Color(0xFF128C7E),
                    bgColor: const Color(0xFF128C7E).withAlpha(18),
                    onTap: () => _launchWhatsApp(context, '967770985114'),
                  ),

                  // Email
                  _buildContactCard(
                    context,
                    title: 'البريد الإلكتروني الرسمي',
                    subtitle: 'aahmedmohammed75@gmail.com',
                    icon: Icons.email_outlined,
                    iconColor: Colors.redAccent,
                    bgColor: Colors.redAccent.withAlpha(18),
                    onTap: () => _launchUrl(context, 'mailto:aahmedmohammed75@gmail.com'),
                  ),

                  // GitHub
                  _buildContactCard(
                    context,
                    title: 'حساب البرمجيات GitHub',
                    subtitle: 'github.com/5a3',
                    icon: FontAwesomeIcons.github,
                    iconColor: isDark ? Colors.white : Colors.black87,
                    bgColor: (isDark ? Colors.white : Colors.black87).withAlpha(18),
                    onTap: () => _launchUrl(context, 'https://github.com/5a3'),
                  ),

                  // Instagram
                  _buildContactCard(
                    context,
                    title: 'إنستغرام Instagram',
                    subtitle: '@AHMED_ALATTAS910',
                    icon: FontAwesomeIcons.instagram,
                    iconColor: const Color(0xFFE1306C),
                    bgColor: const Color(0xFFE1306C).withAlpha(18),
                    onTap: () => _launchUrl(context, 'https://www.instagram.com/AHMED_ALATTAS910/'),
                  ),

                  // Facebook
                  _buildContactCard(
                    context,
                    title: 'فيسبوك Facebook',
                    subtitle: 'أحمد العطاس - Eng. Ahmed Al-Attas',
                    icon: FontAwesomeIcons.facebook,
                    iconColor: const Color(0xFF1877F2),
                    bgColor: const Color(0xFF1877F2).withAlpha(18),
                    onTap: () => _launchUrl(context, 'https://www.facebook.com/people/%D8%A3%D8%A2%D8%AD%D9%85%D8%AF-%D8%A7%D9%84%D8%B9%D8%B7%D8%A7%D8%B3'),
                  ),

                  // Snapchat
                  _buildContactCard(
                    context,
                    title: 'سناب شات Snapchat',
                    subtitle: '@a3ats',
                    icon: FontAwesomeIcons.snapchat,
                    iconColor: const Color(0xFFFFFC00),
                    bgColor: Colors.amber.withAlpha(25),
                    onTap: () => _launchUrl(context, 'https://www.snapchat.com/add/a3ats'),
                  ),

                  const SizedBox(height: 24),

                  // Footer Copyright Notice
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'تم التطوير والتصميم بواسطة Eng. Ahmed Al-Attas',
                          style: AppFonts.cairoFont(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'جميع الحقوق محفوظة © ${DateTime.now().year}',
                          style: AppFonts.cairoFont(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppFonts.cairoFont(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: isDark ? 0 : 0.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.cairoFont(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
