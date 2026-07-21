import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../admin_app/providers/delivery_zone_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../shared/models/delivery_zone_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_auth_provider.dart';
import '../../providers/customer_order_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeliveryZoneProvider>(context, listen: false).fetchDeliveryZones();
      final customer = Provider.of<CustomerAuthProvider>(context, listen: false).currentCustomer;
      if (customer != null && _addressController.text.isEmpty) {
        _addressController.text = customer.address;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _placeOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<CustomerOrderProvider>(context, listen: false);
    final authProvider = Provider.of<CustomerAuthProvider>(context, listen: false);
    final customer = authProvider.currentCustomer;

    if (customer == null) {
      CustomDialog.showErrorSnackBar(context, 'يرجى تسجيل الدخول أولاً لإكمال الطلب');
      return;
    }

    if (cartProvider.itemList.isEmpty) {
      CustomDialog.showErrorSnackBar(context, 'السلة فارغة حالياً');
      return;
    }

    if (cartProvider.selectedZone == null) {
      CustomDialog.showErrorSnackBar(context, 'الرجاء اختيار منطقة التوصيل أولاً');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      CustomDialog.showErrorSnackBar(context, 'الرجاء إدخال مكان توصيل الطلب والعنوان بالتفصيل');
      return;
    }

    final success = await orderProvider.placeOrder(
      customer: customer,
      zone: cartProvider.selectedZone!,
      items: cartProvider.itemList,
      subtotal: cartProvider.subtotal,
      totalAmount: cartProvider.totalAmount,
      deliveryAddress: _addressController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      cartProvider.clearCart();
      CustomDialog.showSuccessSnackBar(
        context,
        'تم إرسال طلبك بنجاح إلى الإدارة! يمكنك متابعة حالة الطلب من شاشة طلباتي.',
      );
    } else if (orderProvider.errorMessage != null) {
      CustomDialog.showErrorSnackBar(context, orderProvider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final zoneProvider = Provider.of<DeliveryZoneProvider>(context);

    return Scaffold(
      body: cartProvider.itemList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.remove_shopping_cart_outlined, size: 70, color: Colors.grey),
                  const SizedBox(height: 14),
                  Text(
                    'سلة التسوق فارغة',
                    style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'العناصر المختارة في السلة',
                    style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartProvider.itemList.length,
                    itemBuilder: (ctx, index) {
                      final item = cartProvider.itemList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName, style: AppFonts.cairoFont(fontWeight: FontWeight.bold)),
                                    Text(
                                      Formatters.formatCurrency(item.price),
                                      style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                                    onPressed: () => cartProvider.decrementItem(item.productId),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                    onPressed: () {
                                      // Increment
                                      cartProvider.addToCart(
                                        // Simple fake or product reconstruction
                                        dynamicProduct(item.productId, item.productName, item.price, item.imageUrl),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 30),
                  Text(
                    'خيارات التوصيل والعنوان',
                    style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<DeliveryZoneModel>(
                    value: cartProvider.selectedZone,
                    decoration: const InputDecoration(
                      labelText: 'اختر منطقة التوصيل (المحددة من الإدارة)',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: zoneProvider.activeZones.map((zone) {
                      return DropdownMenuItem(
                        value: zone,
                        child: Text('${zone.zoneName} (+${Formatters.formatCurrency(zone.deliveryFee)})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      cartProvider.setSelectedZone(val);
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _addressController,
                    labelText: 'عنوان ومكان توصيل الطلب بالتفصيل',
                    hintText: 'ادخل اسم الشارع، المعلم، ورقم البيت...',
                    prefixIcon: Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('مجموع الوجبات:', style: AppFonts.cairoFont(fontSize: 14)),
                            Text(Formatters.formatCurrency(cartProvider.subtotal), style: AppFonts.cairoFont(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('سعر التوصيل:', style: AppFonts.cairoFont(fontSize: 14)),
                            Text(Formatters.formatCurrency(cartProvider.deliveryFee), style: AppFonts.cairoFont(fontSize: 14)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الإجمالي المستحق:', style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              Formatters.formatCurrency(cartProvider.totalAmount),
                              style: AppFonts.cairoFont(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'تأكيد وإرسال الطلب الآن 🚀',
                    onPressed: _placeOrder,
                  ),
                ],
              ),
            ),
    );
  }

  dynamic dynamicProduct(String id, String name, double price, String img) {
    return FakeProduct(id: id, name: name, price: price, img: img);
  }
}

class FakeProduct {
  final String id;
  final String name;
  final double price;
  final String img;
  FakeProduct({required this.id, required this.name, required this.price, required this.img});
  List<String> get images => [img];
}
