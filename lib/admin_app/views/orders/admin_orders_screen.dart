import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/order_model.dart';
import '../../providers/order_management_provider.dart';
import 'order_receipt_dialog.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderManagementProvider>(context, listen: false).listenToAllOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    if (_searchQuery.trim().isEmpty) return orders;
    final query = _searchQuery.trim().toLowerCase();
    return orders.where((o) =>
      o.orderNumber.toLowerCase().contains(query) ||
      o.customerName.toLowerCase().contains(query) ||
      o.customerPhone.toLowerCase().contains(query) ||
      o.deliveryAddress.toLowerCase().contains(query)
    ).toList();
  }

  void _showReceipt(OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => OrderReceiptDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderManagementProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Search Bar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث برقم الطلب، اسم العميل، رقم الهاتف أو العنوان...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Custom Animated Tab Container Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(50),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.primary,
              labelStyle: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: AppFonts.cairoFont(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: Text('الطلبات المباشرة ⚡', overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${orderProvider.activeOrders.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: Text('سجل الطلبات 📦', overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${orderProvider.completedOrders.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      return const LoadingIndicator(message: 'جاري الاستماع للطلبات المباشرة الحية...');
    }

    final filtered = _filterOrders(provider.activeOrders);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'لا توجد نتائج مطابقة للبحث' : 'لا توجد طلبات جارية حالياً ⚡',
              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (ctx, index) {
        final order = filtered[index];
        return _buildOrderCard(order, provider);
      },
    );
  }

  Widget _buildCompletedOrdersList(OrderManagementProvider provider) {
    if (provider.isLoadingCompleted) {
      return const LoadingIndicator(message: 'جاري تحميل سجل الطلبات القديمة...');
    }

    final filtered = _filterOrders(provider.completedOrders);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'لا توجد نتائج مطابقة' : 'لا توجد طلبات قديمة مكتملة في السجل 📦',
              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (ctx, index) {
        final order = filtered[index];
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
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showReceipt(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'طلب #${order.orderNumber}',
                        style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withAlpha(80)),
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
                style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'منطقة التوصيل: ${order.deliveryZoneName} - العنوان: ${order.deliveryAddress}',
                style: AppFonts.cairoFont(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'الوجبات: ${order.items.map((i) => "${i.productName} (x${i.quantity})").join("، ")}',
                style: AppFonts.cairoFont(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatDateTime(order.createdAt),
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
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.print, size: 16, color: Colors.white),
                    label: Text(
                      'استعراض الفاتورة السند 📄',
                      style: AppFonts.cairoFont(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showReceipt(order),
                  ),

                  // Dropdown Order Status Changer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: order.status,
                        style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        items: const [
                          DropdownMenuItem(value: AppConstants.statusPending, child: Text(AppConstants.statusPendingAr)),
                          DropdownMenuItem(value: AppConstants.statusAcceptedPreparing, child: Text(AppConstants.statusAcceptedPreparingAr)),
                          DropdownMenuItem(value: AppConstants.statusDelivering, child: Text(AppConstants.statusDeliveringAr)),
                          DropdownMenuItem(value: AppConstants.statusDelivered, child: Text(AppConstants.statusDeliveredAr)),
                          DropdownMenuItem(value: AppConstants.statusCanceled, child: Text(AppConstants.statusCanceledAr)),
                        ],
                        onChanged: (newStatus) {
                          if (newStatus != null && newStatus != order.status) {
                            _changeStatus(order.id, newStatus, provider);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeStatus(String orderId, String newStatus, OrderManagementProvider provider) async {
    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'تعديل حالة الطلب',
      message: 'هل أنت تأكد من تغيير حالة الطلب الآن؟ عند التوصيل أو الإلغاء سيتم النقل فوراً لسجل الطلبات القديمة.',
    );
    if (confirm == true) {
      final ok = await provider.updateOrderStatus(orderId, newStatus);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم تعديل حالة الطلب ونقله بنجاح ⚡');
      }
    }
  }
}
