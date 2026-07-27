import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سياسة الخصوصية والشروط',
          style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel_outlined,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'شروط الاستخدام وسياسة الخصوصية',
                style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            Center(
              child: Text(
                'تطبيق وصل لي لتوصيل المأكولات السريعة والعصائر',
                style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            _buildSectionTitle('1. المسؤولية القانونية للهوية ورقم الهاتف:'),
            _buildSectionBody(
              'يقر المستخدم بأن رقم الهاتف (المحمول أو الثابت) المدخل أثناء تسجيل الحساب هو رقم خاص به ويقع تحت حيازته الشخصية والقانونية. '
              'يمنع منعاً باتاً التسجيل بأرقام هاتف وهمية أو عائدة لأشخاص آخرين دون تفويض رسمي. '
              'في حال ثبوت عدم ملكية الرقم للمستخدم، فإن إدارة التطبيق تخلي مسؤوليتها تماماً ويتحمل المستخدم وحده كافة المسؤوليات والتبعات القانونية والقضائية الناتجة عن ذلك.',
            ),
            const SizedBox(height: 18),

            _buildSectionTitle('2. إدارة وأرشيف السندات والطلبات (مهم):'),
            _buildSectionBody(
              'تمتلك إدارة تطبيق "وصل لي" الأحقية والصلاحية الكاملة والمطلقة لإجراء عمليات الصيانة الدورية وقاعدة البيانات، '
              'والتي تشمل حذف أو أرشفة السندات والطلبات والتقارير المالية والتشغيلية القديمة من النظام، '
              'سواءً كان ذلك بشكل أسبوعي، شهري، أو لأي فترة زمنية تراها الإدارة مناسبة لأغراض تحسين الأداء وحجم البيانات.',
            ),
            const SizedBox(height: 18),

            _buildSectionTitle('3. جمع البيانات واستخدامها:'),
            _buildSectionBody(
              'يقوم التطبيق بجمع معلومات محدودة لتقديم الخدمة وتشمل: الاسم الكامل، رقم الهاتف، وعنوان التوصيل التفصيلي. '
              'تُستخدم هذه البيانات فقط لضمان دقة تحضير وتوصيل الوجبات والتواصل مع العميل عند الحاجة. '
              'تلتزم إدارة التطبيق بعدم بيع أو مشاركة هذه البيانات مع أي جهة خارجية خارج نظام التوصيل والتشغيل المعتمد.',
            ),
            const SizedBox(height: 18),

            _buildSectionTitle('4. أمان الحسابات وكلمات المرور:'),
            _buildSectionBody(
              'يتحمل العميل المسؤولية الكاملة عن سرية كلمة المرور الخاصة بحسابه وأي أنشطة تتم من خلال الحساب. '
              'يتوجب على العميل إبلاغ إدارة التطبيق فوراً في حال الشك بوجود اختراق أو استخدام غير مصرح به لحسابه.',
            ),
            const SizedBox(height: 18),

            _buildSectionTitle('5. التعديلات على الشروط والسياسات:'),
            _buildSectionBody(
              'تحتفظ إدارة التطبيق بالحق في تحديث شروط الاستخدام وسياسة الخصوصية هذه في أي وقت. '
              'يعتبر استمرارك في استخدام التطبيق بعد إجراء التعديلات موافقة صريحة وقبولاً تاماً بالشروط المحدثة.',
            ),
            const SizedBox(height: 30),
            
            Center(
              child: Text(
                'آخر تحديث: يوليو 2026',
                style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade800, height: 1.6),
    );
  }
}
