import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wasl/core/constants/app_colors.dart';
import 'package:wasl/core/constants/app_constants.dart';
import 'package:wasl/core/constants/app_fonts.dart';
import 'package:wasl/core/services/storage_service.dart';
import '../auth/customer_login_screen.dart';
import '../home/customer_home_screen.dart';
import '../../models/onboarding_item.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      title: 'استكشف أشهى الوجبات والمأكولات',
      description:
          'تصفح قائمة واسعة من أشهر الوجبات السريعة، المشروبات، والمأكولات اللذيذة بسهولة مطلقة عبر تطبيق وصل لي.',
      icon: FontAwesomeIcons.utensils,
      badgeText: 'قائمة متنوعة وعروض حصريّة',
      gradientColors: [Color(0xFFFF6B00), Color(0xFFFF8E3C)],
    ),
    OnboardingItem(
      title: 'طلب سهل وتتبع مباشر لطلبك',
      description:
          'اختر وجباتك المفضلة، أضفها للسلة بلمسة واحدة، وتابع حالة تجهيز طلبك وموقع المندوب في الوقت الفعلي.',
      icon: FontAwesomeIcons.mapLocationDot,
      badgeText: 'تتبع في الوقت الفعلي',
      gradientColors: [Color(0xFFFF8800), Color(0xFFFFB300)],
    ),
    OnboardingItem(
      title: 'توصيل سريع حتى باب منزلكم',
      description:
          'نضمن لك وصول طلبك طازجاً، ساخناً، وفي أسرع وقت ممكن أينما كنت ضمن مناطق الخدمة المعتمدة.',
      icon: FontAwesomeIcons.truckFast,
      badgeText: 'سرعة، جودة، وكفاءة عالية',
      gradientColors: [Color(0xFFE65100), Color(0xFFFF6B00)],
    ),
  ];

  Future<void> _finishOnboarding() async {
    await StorageService.setOnboardingCompleted(true);
    if (!mounted) return;

    final isCustomerLoggedIn = StorageService.isCustomerLoggedIn();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isCustomerLoggedIn
            ? const CustomerHomeScreen()
            : const CustomerLoginScreen(),
      ),
    );
  }

  void _nextPage() {
    if (_currentIndex < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLastPage = _currentIndex == _items.length - 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header with Logo & Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Branding Logo & Title
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/LogoApp.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.fastfood,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppConstants.appName,
                        style: AppFonts.cairoFont(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  if (!isLastPage)
                    TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceLight
                            : Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'تخطي',
                        style: AppFonts.cairoFont(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // Page View Container
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _buildPageCard(context, item, isDark);
                },
              ),
            ),

            // Bottom Navigation Footer (Dots Indicator & Actions)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Animated Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 28 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Control Buttons (Next / Get Started & Back)
                  Row(
                    children: [
                      // Back Button
                      if (_currentIndex > 0) ...[
                        InkWell(
                          onTap: _previousPage,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 54,
                            width: 54,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceLight
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Primary Action Button (Next or Get Started)
                      Expanded(
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFFFF8E3C)],
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLastPage
                                      ? 'ابدأ الاستخدام الآن'
                                      : 'التالي',
                                  style: AppFonts.cairoFont(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLastPage
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCard(
      BuildContext context, OnboardingItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Icon Container with Gradient Effect
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Decorative Soft Glow Circle
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      item.gradientColors.first.withValues(alpha: 0.2),
                      item.gradientColors.last.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),

              // Glassmorphic Card Container
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: item.gradientColors.first.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: FaIcon(
                    item.icon,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Decorative Badge Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              item.badgeText,
              style: AppFonts.cairoFont(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title Text
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: AppFonts.cairoFont(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Description Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              item.description,
              textAlign: TextAlign.center,
              style: AppFonts.cairoFont(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
