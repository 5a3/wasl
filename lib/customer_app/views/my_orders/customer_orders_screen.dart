import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/order_model.dart';
import '../../providers/customer_auth_provider.dart';
import '../../providers/customer_order_provider.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customer = Provider.of<CustomerAuthProvider>(context, listen: false).currentCustomer;
      if (customer != null) {
        Provider.of<CustomerOrderProvider>(context, listen: false).listenToCustomerOrders(customer.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<CustomerOrderProvider>(context);

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
              Tab(text: 'طلباتي الجارية ⚡'),
              Tab(text: 'الطلبات السابقة 📜'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(orderProvider.myActiveOrders, 'لا توجد طلبات جارية حالياً'),
                _buildOrdersList(orderProvider.myPastOrders, 'لا توجد طلبات سابقة مكتملة'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, String emptyMsg) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          emptyMsg,
          style: AppFonts.cairoFont(fontSize: 15, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, index) {
        final order = orders[index];
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
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.statusArabic,
                        style: AppFonts.cairoFont(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'الوجبات: ${order.items.map((i) => "${i.productName} (x${i.quantity})").join("، ")}',
                  style: AppFonts.cairoFont(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'التوصيل إلى: ${order.deliveryZoneName} - ${order.deliveryAddress}',
                  style: AppFonts.cairoFont(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
