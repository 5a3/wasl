import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../providers/customer_auth_provider.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<CustomerAuthProvider>(context, listen: false);
    final success = await authProvider.registerCustomer(
      username: _usernameController.text,
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      CustomDialog.showSuccessSnackBar(
        context,
        'تم إنشاء حسابك بنجاح! يرجى إدخال اسم المستخدم وكلمة المرور لتسجيل الدخول.',
      );
      Navigator.of(context).pop(); // Go back to login screen as requested
    } else if (authProvider.errorMessage != null) {
      CustomDialog.showErrorSnackBar(context, authProvider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<CustomerAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب عميل جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'أدخل بياناتك الشخصية بالتفصيل',
                style: AppFonts.cairoFont(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الرجاء إدخال رقم هاتف يمني صحيح للاتصال والتوصيل',
                style: AppFonts.cairoFont(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _fullNameController,
                labelText: 'الاسم الكامل الرباعي',
                hintText: 'مثال: محمد عبد الله أحمد السقاف',
                prefixIcon: Icons.badge_outlined,
                validator: (val) => Validators.validateRequired(val, 'الاسم الكامل الرباعي'),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _usernameController,
                labelText: 'اسم المستخدم',
                hintText: 'اسم منحصر لتسجيل الدخول (باللغة الإنجليزية/الأرقام)',
                prefixIcon: Icons.account_circle_outlined,
                validator: (val) => Validators.validateRequired(val, 'اسم المستخدم'),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _phoneController,
                labelText: 'رقم الهاتف اليمني',
                hintText: 'مثال: 771234567',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_android_outlined,
                validator: Validators.validateYemeniPhone,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _addressController,
                labelText: 'العنوان / مكان السكن بالتفصيل',
                hintText: 'مثال: حريضة - الشارع العام - بجانب...',
                prefixIcon: Icons.location_on_outlined,
                validator: (val) => Validators.validateRequired(val, 'العنوان'),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _emailController,
                labelText: 'البريد الإلكتروني (اختياري)',
                hintText: 'example@domain.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: Validators.validateEmailOptional,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _passwordController,
                labelText: 'كلمة المرور',
                hintText: '6 أحرف/أرقام على الأقل',
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
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: 'تأكيد كلمة المرور',
                hintText: 'أعد كتابة كلمة المرور للتأكيد',
                prefixIcon: Icons.lock_reset_outlined,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                validator: (val) => Validators.validateConfirmPassword(
                  val,
                  _passwordController.text,
                ),
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: 'إنشاء الحساب الان',
                isLoading: authProvider.isLoading,
                onPressed: _submitRegister,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
