import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/order_model.dart';
import '../../../core/constants/admin_permissions.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/order_management_provider.dart';
import 'order_receipt_dialog.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = Active, 1 = Completed

  @override
  void initState() {
    super.initState();
    
    // Set up scroll controller for lazy loading completed orders
    _scrollController.addListener(() {
      final provider = Provider.of<OrderManagementProvider>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        provider.fetchNextCompletedPage();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderManagementProvider>(context, listen: false).listenToAllOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showReceipt(OrderModel order) {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.ordersPrintReceipt)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية طباعة الفواتير والإيصالات 🔒');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => OrderReceiptDialog(order: order),
    );
  }

  void _deleteOrderConfirm(OrderModel order, OrderManagementProvider provider) async {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.ordersDelete)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية حذف الطلبات 🔒');
      return;
    }

    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'حذف الطلب نهائياً',
      message: 'هل أنت متأكد من حذف الطلب رقم #${order.orderNumber} بشكل نهائي من النظام؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'حذف الآن',
      confirmColor: AppColors.danger,
    );
    if (confirm == true) {
      final ok = await provider.deleteOrder(order.id);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم حذف الطلب بنجاح 🗑️');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderManagementProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Responsive Search Bar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث برقم الطلب، الهاتف، أو الاسم...',
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
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withAlpha(40)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withAlpha(20)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),

          // Custom sliding segmented pill selector (iOS style switch - always visible!)
          _buildCustomSegmentedControl(orderProvider),

          // Main View Logic (Active Orders vs Completed Orders with instant local search filtering)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _selectedTab == 0
                  ? _buildActiveOrdersTab(orderProvider)
                  : _buildCompletedOrdersTab(orderProvider),
            ),
          ),
        ],
      ),
    );
  }

  /// Gorgeous sliding pill segment control
  Widget _buildCustomSegmentedControl(OrderManagementProvider orderProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Tab 1: Active Orders
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(30),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.electric_bolt,
                      size: 16,
                      color: _selectedTab == 0 ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'الطلبات المباشرة',
                      style: AppFonts.cairoFont(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 0 ? Colors.white : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.white.withAlpha(50) : (isDark ? AppColors.darkSurfaceLight : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${orderProvider.activeOrders.length}',
                        style: AppFonts.cairoFont(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _selectedTab == 0 ? Colors.white : (isDark ? AppColors.darkTextPrimary : Colors.grey.shade800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab 2: Completed History
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(30),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: _selectedTab == 1 ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'سجل الطلبات',
                      style: AppFonts.cairoFont(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 1 ? Colors.white : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.white.withAlpha(50) : (isDark ? AppColors.darkSurfaceLight : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        orderProvider.isLoadingCompleted && orderProvider.completedOrders.isEmpty
                            ? '...'
                            : '${orderProvider.completedOrders.length}',
                        style: AppFonts.cairoFont(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _selectedTab == 1 ? Colors.white : (isDark ? AppColors.darkTextPrimary : Colors.grey.shade800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Instant memory filter for the currently selected tab (0 extra reads, 0ms lag!)
  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    final q = _searchQuery.trim().toLowerCase().replaceAll('#', '');
    if (q.isEmpty) return orders;

    final digits = _searchQuery.replaceAll(RegExp(r'[^0-9]'), '');

    return orders.where((o) {
      final oNumClean = o.orderNumber.toLowerCase();
      final pClean = o.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final addPhoneClean = (o.additionalPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');

      // Match Order Number (e.g. W-12345 or 12345 or #12345)
      if (oNumClean.contains(q) || 
          (digits.isNotEmpty && oNumClean.contains(digits))) {
        return true;
      }
      // Match Customer Phone or Additional Phone (e.g. 771234567, 0771234567, +967771234567)
      if (o.customerPhone.contains(q) || 
          (digits.length >= 3 && (pClean.contains(digits) || addPhoneClean.contains(digits)))) {
        return true;
      }
      // Match Customer Name, Address, or Zone
      if (o.customerName.toLowerCase().contains(q) ||
          o.deliveryAddress.toLowerCase().contains(q) ||
          o.deliveryZoneName.toLowerCase().contains(q)) {
        return true;
      }

      return false;
    }).toList();
  }

  Widget _buildActiveOrdersTab(OrderManagementProvider provider) {
    if (provider.isLoadingActive) {
      return const LoadingIndicator(message: 'جاري الاستماع للطلبات النشطة...');
    }

    final filtered = _filterOrders(provider.activeOrders);

    if (filtered.isEmpty) {
      return Center(
        key: ValueKey('activeEmpty_${_searchQuery.isNotEmpty}'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_searchQuery.isNotEmpty ? Icons.search_off_outlined : Icons.restaurant_menu_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'لا توجد نتائج مطابقة لـ "$_searchQuery" في الطلبات المباشرة 🔍' 
                  : 'لا توجد طلبات نشطة حالياً ⚡',
              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: const ValueKey('activeList'),
      color: AppColors.primary,
      onRefresh: () async {
        provider.listenToActiveOrders();
      },
      child: _buildResponsiveGrid(filtered, provider, isCompleted: false),
    );
  }

  Widget _buildCompletedOrdersTab(OrderManagementProvider provider) {
    if (provider.isLoadingCompleted && provider.completedOrders.isEmpty) {
      return const LoadingIndicator(message: 'جاري تحميل سجل الطلبات...');
    }

    final filtered = _filterOrders(provider.completedOrders);

    if (filtered.isEmpty) {
      return Center(
        key: ValueKey('completedEmpty_${_searchQuery.isNotEmpty}'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_searchQuery.isNotEmpty ? Icons.search_off_outlined : Icons.history_toggle_off, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'لا توجد نتائج مطابقة لـ "$_searchQuery" في سجل الطلبات 📦' 
                  : 'سجل الطلبات فارغ حالياً 📦',
              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: const ValueKey('completedList'),
      color: AppColors.primary,
      onRefresh: () async {
        await provider.refreshCompletedOrders();
      },
      child: _buildResponsiveGrid(filtered, provider, isCompleted: true),
    );
  }

  Widget _buildResponsiveGrid(List<OrderModel> orders, OrderManagementProvider provider, {required bool isCompleted}) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 750) {
      return ListView.builder(
        controller: isCompleted ? _scrollController : null,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: orders.length + (isCompleted && provider.hasMoreCompleted ? 1 : 0),
        itemBuilder: (ctx, index) {
          if (isCompleted && index == orders.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          return _buildOrderCard(orders[index], provider);
        },
      );
    } else {
      final leftColumn = <OrderModel>[];
      final rightColumn = <OrderModel>[];

      for (int i = 0; i < orders.length; i++) {
        if (i % 2 == 0) {
          leftColumn.add(orders[i]);
        } else {
          rightColumn.add(orders[i]);
        }
      }

      return SingleChildScrollView(
        controller: isCompleted ? _scrollController : null,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: leftColumn.map((order) => _buildOrderCard(order, provider)).toList(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: rightColumn.map((order) => _buildOrderCard(order, provider)).toList(),
                  ),
                ),
              ],
            ),
            if (isCompleted && provider.hasMoreCompleted)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
          ],
        ),
      );
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return Icons.hourglass_top_rounded;
      case AppConstants.statusAcceptedPreparing:
        return Icons.soup_kitchen_rounded;
      case AppConstants.statusDelivering:
        return Icons.delivery_dining;
      case AppConstants.statusDelivered:
        return Icons.task_alt_rounded;
      case AppConstants.statusCanceled:
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline;
    }
  }

  /// Refined and styled Order Card
  Widget _buildOrderCard(OrderModel order, OrderManagementProvider provider) {
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

    final statusIcon = _getStatusIcon(order.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Color.alphaBlend(statusColor.withAlpha(15), AppColors.darkSurface)
            : Color.alphaBlend(statusColor.withAlpha(10), Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withAlpha(70), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Strip Accent
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Order Number & (Status Badge + Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Prominent Visual Status Circle for illiterate users & admin
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(30),
                              shape: BoxShape.circle,
                              border: Border.all(color: statusColor.withAlpha(100), width: 1.5),
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'طلب #${order.orderNumber}',
                                  style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  Formatters.formatDateTime(order.createdAt),
                                  style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                order.statusArabic,
                                style: AppFonts.cairoFont(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete Button with tooltip
                        GestureDetector(
                          onTap: () => _deleteOrderConfirm(order, provider),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withAlpha(15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 0.8),

                // Customer Name, Phone, and Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${order.customerName} (${order.customerPhone})',
                        style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.copy, size: 14, color: AppColors.primary),
                      tooltip: 'نسخ رقم الهاتف',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.customerPhone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم نسخ رقم الهاتف: ${order.customerPhone}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'منطقة التوصيل: ${order.deliveryZoneName}\nالعنوان التفصيلي: ${order.deliveryAddress}',
                        style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.content_copy_outlined, size: 14, color: AppColors.primary),
                      tooltip: 'نسخ العنوان الكامل',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: 'المنطقة: ${order.deliveryZoneName} - العنوان: ${order.deliveryAddress}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ العنوان الكامل'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Contact Phone Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'هاتف التواصل الأساسي: ${order.customerPhone}',
                                style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade700),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: order.customerPhone));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم نسخ الهاتف الأساسي: ${order.customerPhone}'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.copy, size: 12, color: AppColors.primary),
                              ),
                            ],
                          ),
                          if (order.additionalPhone != null && order.additionalPhone!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'هاتف التواصل البديل: ${order.additionalPhone}',
                                  style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: order.additionalPhone!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم نسخ الهاتف البديل: ${order.additionalPhone}'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.copy, size: 12, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Slim Stepper
                _buildStatusStepper(order.status),
                const SizedBox(height: 12),

                // Meal items clean list
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceLight : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'x${item.quantity} (${Formatters.formatCurrency(item.totalPrice)})',
                                  style: AppFonts.cairoFont(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Pricing Breakdown Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('مجموع الوجبات:', style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade600)),
                          Text(Formatters.formatCurrency(order.subtotal), style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('رسوم التوصيل:', style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade600)),
                          Text(Formatters.formatCurrency(order.deliveryFee), style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Notes
                if (order.note != null && order.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50.withAlpha(isDark ? 25 : 255),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200.withAlpha(120)),
                    ),
                    child: Text(
                      'ملاحظات الطلب: ${order.note}',
                      style: AppFonts.cairoFont(fontSize: 11, color: isDark ? Colors.amber.shade100 : Colors.amber.shade900),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Footer Row: Date & Final Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.formatDateTime(order.createdAt),
                      style: AppFonts.cairoFont(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      'الإجمالي: ${Formatters.formatCurrency(order.totalAmount)}',
                      style: AppFonts.cairoFont(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 0.8),

                // Action Buttons: Print bill & Dropdown status changer
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.print, size: 14, color: Colors.white),
                        label: Text(
                          'طباعة الفاتورة 📄',
                          style: AppFonts.cairoFont(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _showReceipt(order),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Dropdown changer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withAlpha(100), width: 1.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: order.status,
                          style: AppFonts.cairoFont(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
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
        ],
      ),
    );
  }

  /// Slimmer visual progress stepper
  Widget _buildStatusStepper(String status) {
    final steps = [
      AppConstants.statusPending,
      AppConstants.statusAcceptedPreparing,
      AppConstants.statusDelivering,
      AppConstants.statusDelivered,
    ];

    int currentStepIndex = steps.indexOf(status);
    if (status == AppConstants.statusCanceled) {
      currentStepIndex = 3;
    }

    return Row(
      children: List.generate(steps.length, (index) {
        final isDone = index <= currentStepIndex;
        final isCurrent = index == currentStepIndex;

        Color stepColor = Colors.grey.shade300;
        if (isDone) {
          switch (index) {
            case 0:
              stepColor = AppColors.pending;
              break;
            case 1:
              stepColor = AppColors.warning;
              break;
            case 2:
              stepColor = AppColors.info;
              break;
            case 3:
              stepColor = status == AppConstants.statusCanceled ? AppColors.danger : AppColors.success;
              break;
          }
        }

        String stepLabel = '';
        IconData stepIcon = Icons.circle;

        switch (index) {
          case 0:
            stepLabel = 'معلق ⏳';
            stepIcon = Icons.hourglass_top_rounded;
            break;
          case 1:
            stepLabel = 'تحضير 🍳';
            stepIcon = Icons.soup_kitchen_rounded;
            break;
          case 2:
            stepLabel = 'توصيل 🛵';
            stepIcon = Icons.delivery_dining;
            break;
          case 3:
            stepLabel = status == AppConstants.statusCanceled ? 'ملغي ❌' : 'مكتمل ✅';
            stepIcon = status == AppConstants.statusCanceled ? Icons.cancel_rounded : Icons.task_alt_rounded;
            break;
        }

        Color connectorColor = Colors.grey.shade300;
        if (index < currentStepIndex) {
          switch (index) {
            case 0:
              connectorColor = AppColors.pending;
              break;
            case 1:
              connectorColor = AppColors.warning;
              break;
            case 2:
              connectorColor = AppColors.info;
              break;
          }
        }

        return Expanded(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(isCurrent ? 6 : 4),
                    decoration: BoxDecoration(
                      color: isDone ? stepColor.withAlpha(isCurrent ? 40 : 20) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone ? stepColor : Colors.grey.shade300,
                        width: isCurrent ? 2.5 : 1.5,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: stepColor.withAlpha(80),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      stepIcon,
                      size: isCurrent ? 16 : 13,
                      color: isDone ? stepColor : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stepLabel,
                    style: AppFonts.cairoFont(
                      fontSize: isCurrent ? 9.5 : 8.5,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? stepColor : (isDone ? Colors.black87 : Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 1.5,
                    margin: const EdgeInsets.only(bottom: 10),
                    color: connectorColor,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _changeStatus(String orderId, String newStatus, OrderManagementProvider provider) async {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null) {
      if (newStatus == AppConstants.statusAcceptedPreparing && !admin.hasPermission(AdminPermissions.ordersAcceptPrepare)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية تحويل الطلب للتجهيز والتحضير 🍳🔒');
        return;
      }
      if (newStatus == AppConstants.statusDelivering && !admin.hasPermission(AdminPermissions.ordersSendDelivery)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية تحويل الطلب للتوصيل مع المندوب 🛵🔒');
        return;
      }
      if (newStatus == AppConstants.statusDelivered && !admin.hasPermission(AdminPermissions.ordersMarkCompleted)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية إكمال وتسليم الطلب ✅🔒');
        return;
      }
      if (newStatus == AppConstants.statusCanceled && !admin.hasPermission(AdminPermissions.ordersCancel)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية إلغاء ورفض الطلبات ❌🔒');
        return;
      }
    }

    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'تعديل حالة الطلب',
      message: 'هل أنت متأكد من تغيير حالة الطلب؟ سيتم نقل الطلبات المكتملة أو الملغاة فوراً إلى سجل الطلبات القديمة.',
    );
    if (confirm == true) {
      final ok = await provider.updateOrderStatus(orderId, newStatus);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم تعديل حالة الطلب بنجاح ⚡');
      }
    }
  }
}
