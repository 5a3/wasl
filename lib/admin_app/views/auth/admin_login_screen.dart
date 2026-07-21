import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../providers/admin_auth_provider.dart';
import '../dashboard/admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (authProvider.errorMessage != null) {
      CustomDialog.showErrorSnackBar(context, authProvider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دخول الإدارة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 70,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'مرحباً بك في لوحة تحكم الإدارة',
                textAlign: TextAlign.center,
                style: AppFonts.cairoFont(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'أدخل اسم المستخدم وكلمة المرور الخاصة بك',
                textAlign: TextAlign.center,
                style: AppFonts.cairoFont(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _usernameController,
                labelText: 'اسم المستخدم',
                hintText: 'ادخل اسم المستخدم الحصري للإدارة',
                prefixIcon: Icons.person_outline,
                validator: (val) => Validators.validateRequired(val, 'اسم المستخدم'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                labelText: 'كلمة المرور',
                hintText: 'ادخل كلمة المرور',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (val) => Validators.validateRequired(val, 'كلمة المرور'),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'تسجيل الدخول',
                isLoading: authProvider.isLoading,
                onPressed: _submitLogin,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
                label: Text(
                  'إضافة وتعبئة حساب مدير مبدئي (ahmed / 123456)',
                  style: AppFonts.cairoFont(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await authProvider.createInitialAdmin(
                    username: 'ahmed',
                    password: '123456',
                  );
                  if (ok) {
                    setState(() {
                      _usernameController.text = 'ahmed';
                      _passwordController.text = '123456';
                    });
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم إنشاء حساب المدير (ahmed) بنجاح وتعبئة البيانات! يمكنك الآن اضغط تسجيل الدخول.',
                          style: AppFonts.cairoFont(color: Colors.white),
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else if (authProvider.errorMessage != null) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          authProvider.errorMessage!,
                          style: AppFonts.cairoFont(color: Colors.white),
                        ),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
