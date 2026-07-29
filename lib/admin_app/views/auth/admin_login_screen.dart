import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
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
              const SizedBox(height: 50),
              CustomButton(
                text: 'تسجيل الدخول',
                isLoading: authProvider.isLoading,
                onPressed: _submitLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
