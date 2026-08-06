import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/constants/admin_permissions.dart';
import '../../../shared/models/notification_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/notification_provider.dart';

/// Screen for Admin to write, broadcast, view per-customer read receipts, and multi-select delete notifications
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminNotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final provider = Provider.of<AdminNotificationProvider>(context, listen: false);
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    final admin = authProvider.currentAdmin;

    if (admin != null && !admin.hasPermission(AdminPermissions.notificationsSendAll)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('عذراً، حسابك لا يمتلك صلاحية إرسال إشعارات جماعية للعملاء 🔒', style: AppFonts.cairoFont(color: Colors.white)),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final adminName = authProvider.currentAdmin?.fullName ?? 'إدارة التطبيق';

    final success = await provider.sendNotification(
      title: _titleController.text,
      body: _bodyController.text,
      sentBy: adminName,
    );

    if (!mounted) return;

    if (success) {
      _titleController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.successMessage ?? 'تم إرسال الإشعار بنجاح',
            style: AppFonts.cairoFont(color: Colors.white),
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage!,
            style: AppFonts.cairoFont(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    provider.clearMessages();
  }

  Future<void> _confirmDeleteAll() async {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.notificationsDelete)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('عذراً، حسابك لا يمتلك صلاحية حذف الإشعارات 🔒', style: AppFonts.cairoFont(color: Colors.white)), backgroundColor: AppColors.danger),
      );
      return;
    }

    final provider = Provider.of<AdminNotificationProvider>(context, listen: false);
    if (provider.notifications.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف جميع الإشعارات', style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
        content: Text(
          'هل أنت تأكد من مسح جميع الإشعارات السابقة (${provider.notifications.length}) نهائياً من النظام والقاعدة؟',
          style: AppFonts.cairoFont(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('إلغاء', style: AppFonts.cairoFont()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('مسح الكل', style: AppFonts.cairoFont(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await provider.deleteAllNotifications();
      if (mounted && success) {
        setState(() {
          _selectedIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم مسح جميع الإشعارات بنجاح', style: AppFonts.cairoFont(color: Colors.white)),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.notificationsDelete)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('عذراً، حسابك لا يمتلك صلاحية حذف الإشعارات 🔒', style: AppFonts.cairoFont(color: Colors.white)), backgroundColor: AppColors.danger),
      );
      return;
    }

    final provider = Provider.of<AdminNotificationProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف الإشعارات المحددة', style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
        content: Text(
          'هل أنت تأكد من حذف الإشعارات المحددة عدد (${_selectedIds.length})؟',
          style: AppFonts.cairoFont(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('إلغاء', style: AppFonts.cairoFont()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('حذف المحددة', style: AppFonts.cairoFont(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await provider.deleteSelectedNotifications(_selectedIds.toList());
      if (mounted && success) {
        setState(() {
          _selectedIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الإشعارات المحددة بنجاح', style: AppFonts.cairoFont(color: Colors.white)),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showReadReceiptsModal(BuildContext context, NotificationModel notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تقرير قراء واستلام الإشعار 📊',
                          style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade700.withAlpha(60)),
                    ),
                    child: Text(
                      '${notification.readReceipts.length} قراءات',
                      style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              Expanded(
                child: notification.readReceipts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility_off_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'لم يقم أي عميل بقراءة الإشعار حتى الآن',
                              style: AppFonts.cairoFont(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: notification.readReceipts.length,
                        itemBuilder: (ctx, index) {
                          final receipt = notification.readReceipts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface.withAlpha(200) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary.withAlpha(30),
                                  child: Text(
                                    receipt.customerName.isNotEmpty ? receipt.customerName[0] : 'ع',
                                    style: AppFonts.cairoFont(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        receipt.customerName,
                                        style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      if (receipt.customerPhone.isNotEmpty)
                                        Text(
                                          'هاتف: ${receipt.customerPhone}',
                                          style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  Formatters.formatDateTime(receipt.readAt),
                                  style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'إغلاق التقرير',
                    style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminNotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIds.isNotEmpty
              ? 'محدد (${_selectedIds.length})'
              : 'إدارة إشعارات التطبيق 🔔',
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
              tooltip: 'حذف المحددة',
              onPressed: _confirmDeleteSelected,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'إلغاء التحديد',
              onPressed: () {
                setState(() {
                  _selectedIds.clear();
                });
              },
            ),
          ] else if (provider.notifications.isNotEmpty) ...[
            TextButton.icon(
              icon: const Icon(Icons.delete_forever_outlined, color: AppColors.danger, size: 18),
              label: Text(
                'مسح الكل',
                style: AppFonts.cairoFont(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: _confirmDeleteAll,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compose Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(25),
                    AppColors.primary.withAlpha(5),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.campaign_outlined, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إرسال إشعار عام للعملاء',
                              style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'مستهدف: جميع أجهزة المستخدمين (Topic: all_customers)',
                              style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _titleController,
                    labelText: 'عنوان الإشعار *',
                    hintText: 'مثال: خصم 20% على جميع الوجبات اليوم! 🍕',
                    prefixIcon: Icons.title_outlined,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _bodyController,
                    labelText: 'نص ومحتوى الإشعار *',
                    hintText: 'اكتب تفاصيل الإشعار أو العرض هنا...',
                    prefixIcon: Icons.message_outlined,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'إرسال وبث الإشعار الآن 🚀',
                    isLoading: provider.isLoading,
                    onPressed: provider.isLoading ? null : _sendNotification,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سجل الإشعارات المرسلة 📋',
                  style: AppFonts.cairoFont(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (provider.notifications.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedIds.length == provider.notifications.length) {
                              _selectedIds.clear();
                            } else {
                              _selectedIds.addAll(provider.notifications.map((n) => n.id));
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _selectedIds.length == provider.notifications.length
                                ? 'إلغاء تحديد الكل'
                                : 'تحديد الكل',
                            style: AppFonts.cairoFont(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.notifications.length}',
                        style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Notification List
            if (provider.isLoading && provider.notifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.notifications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد إشعارات مرسلة بعد',
                        style: AppFonts.cairoFont(fontSize: 14, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.notifications.length,
                itemBuilder: (ctx, index) {
                  final n = provider.notifications[index];
                  final isSelected = _selectedIds.contains(n.id);
                  return _buildNotificationCard(n, provider, isDark, isSelected);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
    AdminNotificationProvider provider,
    bool isDark,
    bool isSelected,
  ) {
    final readCount = notification.readReceipts.length;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          if (isSelected) {
            _selectedIds.remove(notification.id);
          } else {
            _selectedIds.add(notification.id);
          }
        });
      },
      onTap: () {
        if (_selectedIds.isNotEmpty) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(notification.id);
            } else {
              _selectedIds.add(notification.id);
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(isDark ? 40 : 20)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 15 : 5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedIds.isNotEmpty)
                  Checkbox(
                    value: isSelected,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(notification.id);
                        } else {
                          _selectedIds.remove(notification.id);
                        }
                      });
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade700.withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 11, color: Colors.green),
                                const SizedBox(width: 3),
                                Text(
                                  'تم البث للجميع',
                                  style: AppFonts.cairoFont(fontSize: 9, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            notification.sentBy,
                            style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey.shade500),
                          ),
                          const Spacer(),
                          Icon(Icons.access_time, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            Formatters.formatDateTime(notification.createdAt),
                            style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_selectedIds.isEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('حذف الإشعار', style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
                          content: Text('هل أنت تأكد من حذف هذا الإشعار من السجل والقاعدة؟', style: AppFonts.cairoFont()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text('إلغاء', style: AppFonts.cairoFont()),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text('حذف', style: AppFonts.cairoFont(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        await provider.deleteNotification(notification.id);
                      }
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Read Receipts Report Button
            InkWell(
              onTap: () => _showReadReceiptsModal(context, notification),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'تمت القراءة بواسطة ($readCount) عميل 👁️',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.cairoFont(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض التقرير التفصيلي',
                          style: AppFonts.cairoFont(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
