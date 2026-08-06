import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/notification_model.dart';
import '../../providers/customer_auth_provider.dart';
import '../../providers/customer_notification_provider.dart';

/// Screen displaying general notifications and broadcasts for customer
class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  // 0: الكل, 1: غير المقروءة, 2: المقروءة
  int _subFilter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerAuth = Provider.of<CustomerAuthProvider>(context, listen: false);
      Provider.of<CustomerNotificationProvider>(context, listen: false)
          .fetchNotifications(currentCustomerId: customerAuth.currentCustomer?.id);
    });
  }

  void _showNotificationDetail(BuildContext context, NotificationModel notification) {
    // Mark as read immediately and send read receipt with customer name & phone
    final customerAuth = Provider.of<CustomerAuthProvider>(context, listen: false);
    final customer = customerAuth.currentCustomer;

    Provider.of<CustomerNotificationProvider>(context, listen: false).markAsRead(
      notification.id,
      customerId: customer?.id,
      customerName: customer?.fullName.isNotEmpty == true ? customer!.fullName : (customer?.phone ?? 'عميل التطبيق'),
      customerPhone: customer?.phone ?? '',
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          Formatters.formatDateTime(notification.createdAt),
                          style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'تفاصيل الإشعار:',
                style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                notification.body,
                style: AppFonts.cairoFont(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'إغلاق',
                    style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerNotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = provider.notifications;

    final unreadCount = list.where((n) => !provider.isRead(n.id)).length;
    final readCount = list.where((n) => provider.isRead(n.id)).length;

    List<NotificationModel> displayedList = list;
    if (_subFilter == 1) {
      displayedList = list.where((n) => !provider.isRead(n.id)).toList();
    } else if (_subFilter == 2) {
      displayedList = list.where((n) => provider.isRead(n.id)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مركز الإشعارات 🔔',
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: provider.isLoading && provider.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sub-filter Chips Bar (الكل | غير المقروءة 🔔 | المقروءة)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'الكل (${list.length})',
                        isSelected: _subFilter == 0,
                        onSelected: () => setState(() => _subFilter = 0),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'غير المقروءة 🔔 ($unreadCount)',
                        isSelected: _subFilter == 1,
                        isHighlight: unreadCount > 0,
                        onSelected: () => setState(() => _subFilter = 1),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'المقروءة ($readCount)',
                        isSelected: _subFilter == 2,
                        onSelected: () => setState(() => _subFilter = 2),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: displayedList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.campaign_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _subFilter == 1
                                    ? 'لا توجد إشعارات غير مقروءة 🔔'
                                    : _subFilter == 2
                                        ? 'لا توجد إشعارات مقروءة 📑'
                                        : 'لا توجد إشعارات عامة حالياً 📢',
                                style: AppFonts.cairoFont(fontSize: 15, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () {
                            final customerAuth = Provider.of<CustomerAuthProvider>(context, listen: false);
                            return provider.fetchNotifications(currentCustomerId: customerAuth.currentCustomer?.id);
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: displayedList.length,
                            itemBuilder: (context, index) {
                              final item = displayedList[index];
                              final isRead = provider.isRead(item.id);

                              return GestureDetector(
                                onTap: () => _showNotificationDetail(context, item),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isRead
                                        ? (isDark ? AppColors.darkSurface : Colors.white)
                                        : AppColors.primary.withAlpha(isDark ? 30 : 15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isRead
                                          ? (isDark ? AppColors.darkBorder : Colors.grey.shade200)
                                          : AppColors.primary.withAlpha(80),
                                      width: isRead ? 1 : 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(isDark ? 10 : 4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isRead ? Colors.grey.shade300.withAlpha(100) : AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isRead ? Icons.notifications_none : Icons.notifications_active,
                                          color: isRead ? Colors.grey.shade700 : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.title,
                                                    style: AppFonts.cairoFont(
                                                      fontSize: 14,
                                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                                      color: isRead ? null : AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'جديد',
                                                      style: AppFonts.cairoFont(
                                                        fontSize: 9,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.body,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppFonts.cairoFont(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              Formatters.formatDateTime(item.createdAt),
                                              style: AppFonts.cairoFont(
                                                fontSize: 10,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    bool isHighlight = false,
  }) {
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: AppFonts.cairoFont(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : (isHighlight ? AppColors.danger : Colors.grey.shade800),
        ),
      ),
      backgroundColor: isHighlight ? AppColors.danger.withAlpha(15) : Colors.grey.shade200,
      selectedColor: AppColors.primary,
      onSelected: (_) => onSelected(),
    );
  }
}
