import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

/// Institutional & Formal Developer Profile Screen for Eng. Ahmed Al-Attas
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

  /// Launch WhatsApp via Native Scheme
  Future<void> _launchWhatsApp(BuildContext context, String rawPhone) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    const message = 'مرحباً م. أحمد العطاس، أود التواصل معك بشأن تطبيق وصل لي.';
    final encodedMsg = Uri.encodeComponent(message);

    final schemeUrl = Uri.parse(
      'whatsapp://send?phone=$phone&text=$encodedMsg',
    );
    final webUrl = Uri.parse('https://wa.me/$phone?text=$encodedMsg');

    try {
      if (await canLaunchUrl(schemeUrl)) {
        await launchUrl(
          schemeUrl,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'مطور التطبيق',
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor:
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Corporate Official Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'م. أحمد العطاس',
                          style: AppFonts.cairoFont(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Eng. Ahmed Al-Attas',
                          style: AppFonts.cairoFont(
                            fontSize: 12,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مطور برمجيات - مهندس تكنلوجيا معلومات',
                          style: AppFonts.cairoFont(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Contact Methods
            _buildSectionLabel(context, 'بيانات التواصل والدعم', isDark),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildCorporateTile(
                    context,
                    title: 'واتساب التواصل',
                    value: '+967 716226912',
                    icon: FontAwesomeIcons.whatsapp,
                    iconColor: const Color(0xFF25D366),
                    onTap: () => _launchWhatsApp(context, '967716226912'),
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildCorporateTile(
                    context,
                    title: 'واتساب الدعم الفني',
                    value: '+967 770985114',
                    icon: FontAwesomeIcons.whatsapp,
                    iconColor: const Color(0xFF128C7E),
                    onTap: () => _launchWhatsApp(context, '967770985114'),
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildCorporateTile(
                    context,
                    title: 'البريد الإلكتروني',
                    value: 'aahmedmohammed75@gmail.com',
                    icon: Icons.email_outlined,
                    iconColor: const Color(0xFFEA4335),
                    onTap:
                        () => _launchUrl(
                          context,
                          'mailto:aahmedmohammed75@gmail.com',
                        ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Official Platforms
            _buildSectionLabel(context, 'الحسابات الرسمية والمنصات', isDark),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildCorporateTile(
                    context,
                    title: 'منصة GitHub البرمجية',
                    value: 'github.com/5a3',
                    icon: FontAwesomeIcons.github,
                    iconColor: isDark ? Colors.white : Colors.black87,
                    onTap: () => _launchUrl(context, 'https://github.com/5a3'),
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildCorporateTile(
                    context,
                    title: 'إنستغرام Instagram',
                    value: 'AHMED_ALATTAS910',
                    icon: FontAwesomeIcons.instagram,
                    iconColor: const Color(0xFFE1306C),
                    onTap:
                        () => _launchUrl(
                          context,
                          'https://www.instagram.com/AHMED_ALATTAS910/',
                        ),
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildCorporateTile(
                    context,
                    title: 'فيسبوك Facebook',
                    value: 'أحمد العطاس - Eng. Ahmed Al-Attas',
                    icon: FontAwesomeIcons.facebook,
                    iconColor: const Color(0xFF1877F2),
                    onTap:
                        () => _launchUrl(
                          context,
                          'https://www.facebook.com/people/%D8%A3%D8%A2%D8%AD%D9%85%D8%AF-%D8%A7%D9%84%D8%B9%D8%B7%D8%A7%D8%B3',
                        ),
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildCorporateTile(
                    context,
                    title: 'سناب شات Snapchat',
                    value: 'a3ats',
                    icon: FontAwesomeIcons.snapchat,
                    iconColor: Colors.amber.shade700,
                    onTap:
                        () => _launchUrl(
                          context,
                          'https://www.snapchat.com/add/a3ats',
                        ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer Institutional Copyright
            Center(
              child: Column(
                children: [
                  Text(
                    'تطبيق وصل لي © ${DateTime.now().year}',
                    style: AppFonts.cairoFont(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'تطوير وتنفيذ: م. أحمد العطاس',
                    style: AppFonts.cairoFont(
                      fontSize: 11,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary.withValues(
                                alpha: 0.7,
                              )
                              : AppColors.lightTextSecondary.withValues(
                                alpha: 0.7,
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: AppFonts.cairoFont(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }

  Widget _buildCorporateTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: FaIcon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        style: AppFonts.cairoFont(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        value,
        style: AppFonts.cairoFont(
          fontSize: 11,
          color:
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
        ),
        textDirection: TextDirection.ltr,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
    );
  }
}
