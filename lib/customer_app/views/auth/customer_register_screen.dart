import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../providers/customer_auth_provider.dart';
import 'privacy_policy_screen.dart';

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
  String _phoneType = 'mobile'; // 'mobile' or 'fixed'
  bool _isAgreedPhone = false;
  bool _isAgreedPrivacy = false;

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
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                labelText: 'الاسم الكامل الثلاثي/الرباعي *',
                hintText: 'مثال: أحمد محمد سالم العطاس',
                prefixIcon: Icons.badge_outlined,
                validator: Validators.validateFullName,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _usernameController,
                labelText: 'اسم المستخدم (4 أحرف/أرقام على الأقل) *',
                hintText: 'اسم منحصر لتسجيل الدخول (مثال: ahmed12)',
                prefixIcon: Icons.account_circle_outlined,
                validator: Validators.validateUsername,
              ),
              const SizedBox(height: 14),
              Text(
                'نوع رقم الهاتف:',
                style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPhoneTypeButton('هاتف محمول 📱', 'mobile'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPhoneTypeButton('هاتف ثابت ☎️', 'fixed'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Legal Warning Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withAlpha(35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تنبيه هام: يجب إدخال رقم الهاتف الفعلي الخاص بك تحت طائل المسؤولية. إدخال رقم هاتف وهمي أو غير عائد لك يعرضك للمساءلة القانونية والقضائية الكاملة.',
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _phoneController,
                labelText: _phoneType == 'mobile' ? 'رقم الهاتف المحمول' : 'رقم الهاتف الثابت',
                hintText: _phoneType == 'mobile' ? 'مثال: 771234567' : 'مثال: 508000 أو 05508000',
                keyboardType: TextInputType.phone,
                prefixIcon: _phoneType == 'mobile' ? Icons.phone_android_outlined : Icons.phone_in_talk_outlined,
                validator: _validatePhone,
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
              const SizedBox(height: 20),

              // Checkbox 1: Phone Responsibility
              CheckboxListTile(
                value: _isAgreedPhone,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'نعم، هذا رقمي وأنا مسؤول عن أي مسألة قانونية تثبت عني وهذا الرقم لي.',
                  style: AppFonts.cairoFont(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onChanged: (val) {
                  setState(() {
                    _isAgreedPhone = val ?? false;
                  });
                },
              ),
              const SizedBox(height: 8),

              // Checkbox 2: Terms and Privacy Policy Consent
              CheckboxListTile(
                value: _isAgreedPrivacy,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'أوافق وأقر بجميع شروط الاستخدام و ',
                      style: AppFonts.cairoFont(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        );
                      },
                      child: Text(
                        'سياسة الخصوصية الخاصة بالتطبيق',
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ).copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
                onChanged: (val) {
                  setState(() {
                    _isAgreedPrivacy = val ?? false;
                  });
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'إنشاء الحساب الان',
                isLoading: authProvider.isLoading,
                onPressed: (_isAgreedPhone && _isAgreedPrivacy) ? _submitRegister : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneTypeButton(String label, String type) {
    final isSelected = _phoneType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _phoneType = type;
          _phoneController.clear(); // Clear input when type changes to prevent invalid submissions
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppFonts.cairoFont(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    final cleanPhone = value.trim();
    if (_phoneType == 'mobile') {
      final yemeniPhoneRegex = RegExp(r'^(77|73|71|70|78)[0-9]{7}$');
      if (!yemeniPhoneRegex.hasMatch(cleanPhone)) {
        return 'يرجى إدخال رقم هاتف محمول يمني صحيح (مثال: 771234567)';
      }
    } else {
      final landlineRegex = RegExp(r'^[0-9]{6,9}$');
      if (!landlineRegex.hasMatch(cleanPhone)) {
        return 'يرجى إدخال رقم هاتف ثابت صحيح (من 6 إلى 9 أرقام)';
      }
    }
    return null;
  }
}
