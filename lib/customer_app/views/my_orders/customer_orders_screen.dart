import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/order_model.dart';
import '../../providers/customer_auth_provider.dart';
import '../../providers/customer_order_provider.dart';

class CustomerOrdersScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const CustomerOrdersScreen({super.key, this.scrollController});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  int _selectedTab = 0; // 0 = Active/Running, 1 = Past/Completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customer = Provider.of<CustomerAuthProvider>(context, listen: false).currentCustomer;
      if (customer != null) {
        Provider.of<CustomerOrderProvider>(context, listen: false).listenToCustomerOrders(customer.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<CustomerOrderProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Custom pillSegment controller matching Admin app styling
          _buildCustomSegmentedControl(orderProvider),

          // Main View switch with fade transition
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _selectedTab == 0
                  ? _buildActiveOrdersView(orderProvider)
                  : _buildPastOrdersView(orderProvider),
            ),
          ),
        ],
      ),
    );
  }

  /// Pill segmented selector matching the Admin screen segmented design
  Widget _buildCustomSegmentedControl(CustomerOrderProvider orderProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Tab 1: Running/Active
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
                      Icons.directions_run,
                      size: 16,
                      color: _selectedTab == 0 ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'طلباتي الجارية',
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
                        '${orderProvider.myActiveOrders.length}',
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

          // Tab 2: Past Orders
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
                      'الطلبات السابقة',
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
                        '${orderProvider.myPastOrders.length}',
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

  Widget _buildActiveOrdersView(CustomerOrderProvider provider) {
    if (provider.myActiveOrders.isEmpty) {
      return Center(
        key: const ValueKey('customerActiveEmpty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'لا توجد طلبات جارية حالياً ⚡',
              style: AppFonts.cairoFont(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return _buildResponsiveGrid(provider.myActiveOrders);
  }

  Widget _buildPastOrdersView(CustomerOrderProvider provider) {
    if (provider.myPastOrders.isEmpty) {
      return Center(
        key: const ValueKey('customerPastEmpty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'لا توجد طلبات سابقة مكتملة 📜',
              style: AppFonts.cairoFont(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return _buildResponsiveGrid(provider.myPastOrders);
  }

  /// Builds a responsive grid of customer order cards
  Widget _buildResponsiveGrid(List<OrderModel> orders) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 750) {
      return ListView.builder(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (ctx, index) {
          return _buildCustomerOrderCard(orders[index]);
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: leftColumn.map((order) => _buildCustomerOrderCard(order)).toList(),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: rightColumn.map((order) => _buildCustomerOrderCard(order)).toList(),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Modern, beautiful customer order card matching the admin layout
  Widget _buildCustomerOrderCard(OrderModel order) {
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
          // Status strip
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
                // Header: Order number and status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'طلب #${order.orderNumber}',
                          style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withAlpha(40)),
                      ),
                      child: Text(
                        order.statusArabic,
                        style: AppFonts.cairoFont(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 0.8),

                // Delivery Info
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
                          Text(
                            'هاتف التواصل الأساسي: ${order.customerPhone}',
                            style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade700),
                          ),
                          if (order.additionalPhone != null && order.additionalPhone!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'هاتف التواصل البديل: ${order.additionalPhone}',
                              style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stepper reflecting real status colors
                _buildStatusStepper(order.status),
                const SizedBox(height: 12),

                // Meal items table
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
                      'إجمالي الدفع: ${Formatters.formatCurrency(order.totalAmount)}',
                      style: AppFonts.cairoFont(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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

  /// Slim progress stepper
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
            stepLabel = 'معلق';
            stepIcon = Icons.hourglass_empty;
            break;
          case 1:
            stepLabel = 'تحضير';
            stepIcon = Icons.restaurant;
            break;
          case 2:
            stepLabel = 'توصيل';
            stepIcon = Icons.delivery_dining;
            break;
          case 3:
            stepLabel = status == AppConstants.statusCanceled ? 'ملغي' : 'مكتمل';
            stepIcon = status == AppConstants.statusCanceled ? Icons.cancel : Icons.check_circle;
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
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: stepColor.withAlpha(20),
                      shape: BoxShape.circle,
                      border: Border.all(color: stepColor, width: 1.5),
                    ),
                    child: Icon(stepIcon, size: 10, color: stepColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stepLabel,
                    style: AppFonts.cairoFont(
                      fontSize: 8,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? stepColor : Colors.grey.shade600,
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
}
