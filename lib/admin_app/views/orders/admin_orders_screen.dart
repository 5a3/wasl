import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/order_model.dart';
import '../../providers/order_management_provider.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OrderManagementProvider>(context, listen: false);
      provider.listenToActiveOrders();
      provider.fetchCompletedOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderManagementProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle: AppFonts.cairoFont(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'الطلبات النشطة والجارية ⚡'),
              Tab(text: 'سجل الطلبات القديمة 📦'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveOrdersList(orderProvider),
                _buildCompletedOrdersList(orderProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersList(OrderManagementProvider provider) {
    if (provider.isLoadingActive) {
      return const LoadingIndicator(message: 'جاري الاستماع للطلبات النشطة المباشرة...');
    }

    if (provider.activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'لا توجد طلبات جارية حالياً',
              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.activeOrders.length,
      itemBuilder: (ctx, index) {
        final order = provider.activeOrders[index];
        return _buildOrderCard(order, provider);
      },
    );
  }

  Widget _buildCompletedOrdersList(OrderManagementProvider provider) {
    if (provider.isLoadingCompleted) {
      return const LoadingIndicator(message: 'جاري تحميل سجل الطلبات القديمة...');
    }

    if (provider.completedOrders.isEmpty) {
      return Center(
        child: Text(
          'لا توجد طلبات مكتملة سابقة',
          style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.completedOrders.length,
      itemBuilder: (ctx, index) {
        final order = provider.completedOrders[index];
        return _buildOrderCard(order, provider, isCompleted: true);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, OrderManagementProvider provider, {bool isCompleted = false}) {
    Color statusColor;
    switch (order.status) {
      case AppConstants.statusPending:
        statusColor = AppColors.pending;
        break;
      case AppConstants.statusAcceptedPreparing:
        statusColor = AppColors.warning;
        break;
      case AppConstants.statusDelivering:
        statusColor = AppColors.info;
        break;
      case AppConstants.statusDelivered:
        statusColor = AppColors.success;
        break;
      default:
        statusColor = AppColors.danger;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب #${order.orderNumber}',
                  style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusArabic,
                    style: AppFonts.cairoFont(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              'العميل: ${order.customerName} (${order.customerPhone})',
              style: AppFonts.cairoFont(fontSize: 14),
            ),
            Text(
              'منطقة التوصيل: ${order.deliveryZoneName} - العنوان: ${order.deliveryAddress}',
              style: AppFonts.cairoFont(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'العناصر: ${order.items.map((i) => "${i.productName} (x${i.quantity})").join("، ")}',
              style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'التاريخ: ${Formatters.formatDateTime(order.createdAt)}',
                  style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  'الإجمالي: ${Formatters.formatCurrency(order.totalAmount)}',
                  style: AppFonts.cairoFont(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (order.status == AppConstants.statusPending)
                    Expanded(
                      child: CustomButton(
                        text: 'استلام وقيد التحضير 🍳',
                        height: 40,
                        backgroundColor: AppColors.warning,
                        onPressed: () => _updateStatus(order.id, AppConstants.statusAcceptedPreparing, provider),
                      ),
                    ),
                  if (order.status == AppConstants.statusAcceptedPreparing)
                    Expanded(
                      child: CustomButton(
                        text: 'في الطريق مع المندوب 🛵',
                        height: 40,
                        backgroundColor: AppColors.info,
                        onPressed: () => _updateStatus(order.id, AppConstants.statusDelivering, provider),
                      ),
                    ),
                  if (order.status == AppConstants.statusDelivering)
                    Expanded(
                      child: CustomButton(
                        text: 'تأكيد التسليم تم التوصيل ✅',
                        height: 40,
                        backgroundColor: AppColors.success,
                        onPressed: () => _updateStatus(order.id, AppConstants.statusDelivered, provider),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
                    tooltip: 'إلغاء الطلب',
                    onPressed: () => _updateStatus(order.id, AppConstants.statusCanceled, provider),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateStatus(String orderId, String status, OrderManagementProvider provider) async {
    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'تغيير حالة الطلب',
      message: 'هل أنت تأكد من تغيير حالة الطلب الآن؟',
    );
    if (confirm == true) {
      final ok = await provider.updateOrderStatus(orderId, status);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم تحديث حالة الطلب بنجاح');
      }
    }
  }
}
