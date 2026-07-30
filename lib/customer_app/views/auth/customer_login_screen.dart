import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../providers/customer_auth_provider.dart';
import '../home/customer_home_screen.dart';
import 'customer_register_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<CustomerAuthProvider>(
        context,
        listen: false,
      );
      if (StorageService.isCustomerLoggedIn() || authProvider.currentCustomer != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<CustomerAuthProvider>(
      context,
      listen: false,
    );
    final success = await authProvider.loginCustomer(
      _identifierController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      );
    } else if (authProvider.errorMessage != null) {
      CustomDialog.showErrorSnackBar(context, authProvider.errorMessage!);
    }
  }

  /// Launch WhatsApp Direct Support via Android Chooser (Regular / Business)
  Future<void> _launchWhatsAppSupport(String identifier) async {
    const phone = '967770985114';
    final cleanId = identifier.trim();
    final message =
        cleanId.isNotEmpty
            ? 'مرحباً إدارة تطبيق وصل لي، أود إعادة تعيين الرمز السري الخاص بحسابي ($cleanId).'
            : 'مرحباً إدارة تطبيق وصل لي، لقد نسيت الرمز السري الخاص بحسابي وأود مساعدتي في استعادته.';

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
        final launched = await launchUrl(
          webUrl,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && mounted) {
          CustomDialog.showErrorSnackBar(
            context,
            'تعذر فتح الواتساب، تواصل مباشرة مع الدعم: 770985114',
          );
        }
      }
    } catch (_) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          CustomDialog.showErrorSnackBar(
            context,
            'يرجى التأكد من تثبيت تطبيق الواتساب على جهازك',
          );
        }
      }
    }
  }

  /// Display Forgot Password WhatsApp Support Bottom Sheet
  void _showForgotPasswordDialog() {
    final identifierText = _identifierController.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final tempController = TextEditingController(text: identifierText);
        bool isChecking = false;
        String? sheetErrorMessage;

        return StatefulBuilder(
          builder: (bottomSheetContext, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom:
                    MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_reset,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'إعادة تعيين كلمة المرور عبر الواتساب',
                        style: AppFonts.cairoFont(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'سيتم التأكد من وجود الحساب في قاعدة البيانات أولاً ثم فتح محادثة المساعدة المباشرة على الواتساب مع رقم إدارة التطبيق (770985114).',
                    style: AppFonts.cairoFont(
                      fontSize: 12,
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: tempController,
                    labelText: 'اسم المستخدم أو رقم الهاتف المسجل',
                    hintText: 'ادخل اسم المستخدم أو رقم هاتفك اليمني',
                    prefixIcon: Icons.person_outline,
                    onChanged: (_) {
                      if (sheetErrorMessage != null) {
                        setSheetState(() {
                          sheetErrorMessage = null;
                        });
                      }
                    },
                  ),
                  if (sheetErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sheetErrorMessage!,
                              style: AppFonts.cairoFont(
                                color: AppColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'تحقق وفتح الواتساب 💬',
                    backgroundColor: const Color(0xFF25D366),
                    isLoading: isChecking,
                    onPressed:
                        isChecking
                            ? null
                            : () async {
                              final input = tempController.text.trim();
                              if (input.isEmpty) {
                                setSheetState(() {
                                  sheetErrorMessage =
                                      'يرجى إدخال اسم المستخدم أو رقم الهاتف';
                                });
                                return;
                              }

                              final navigator = Navigator.of(
                                bottomSheetContext,
                              );

                              setSheetState(() {
                                isChecking = true;
                                sheetErrorMessage = null;
                              });

                              final authProvider =
                                  Provider.of<CustomerAuthProvider>(
                                    context,
                                    listen: false,
                                  );
                              final exists = await authProvider.checkUserExists(
                                input,
                              );

                              if (!mounted) return;

                              if (!exists) {
                                setSheetState(() {
                                  isChecking = false;
                                  sheetErrorMessage =
                                      'اسم المستخدم هذا غير موجود تأكد من إدارة التطبيق';
                                });
                                return;
                              }

                              setSheetState(() {
                                isChecking = false;
                              });

                              navigator.pop();
                              _launchWhatsAppSupport(input);
                            },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomerAuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirm = await CustomDialog.showConfirmDialog(
          context: context,
          title: 'الخروج من التطبيق 🚪',
          message: 'هل تريد حقاً الخروج من تطبيق وصل لي؟',
          confirmText: 'خروج',
          cancelText: 'إلغاء',
          confirmColor: AppColors.danger,
        );
        if (confirm == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول للعملاء'),
        actions: [
          IconButton(
            tooltip: 'تغيير المظهر (فاتح / داكن)',
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'مرحباً بك مجدداً!',
                textAlign: TextAlign.center,
                style: AppFonts.cairoFont(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ادخل اسم المستخدم أو رقم الهاتف وكلمة المرور',
                textAlign: TextAlign.center,
                style: AppFonts.cairoFont(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 28),
              CustomTextField(
                controller: _identifierController,
                labelText: 'اسم المستخدم أو رقم الهاتف',
                hintText: 'ادخل اسم المستخدم أو رقم هاتفك اليمني',
                prefixIcon: Icons.person_outline,
                validator:
                    (val) => Validators.validateRequired(
                      val,
                      'اسم المستخدم أو رقم الهاتف',
                    ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                labelText: 'كلمة المرور',
                hintText: 'ادخل كلمة المرور (6+ أحرف)',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 4),

              // Forgot Password Button
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    'نسيت كلمة المرور؟ 🔑',
                    style: AppFonts.cairoFont(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              CustomButton(
                text: 'تسجيل الدخول',
                isLoading: authProvider.isLoading,
                onPressed: _submitLogin,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ليس لديك حساب بعد؟',
                    style: AppFonts.cairoFont(color: Colors.grey.shade700),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CustomerRegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'إنشاء حساب جديد',
                      style: AppFonts.cairoFont(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
