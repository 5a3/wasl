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
import '../../../shared/models/product_model.dart';
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
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

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
    _phoneController.dispose();
    _noteController.dispose();
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
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      additionalPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      cartProvider.clearCart();
      _phoneController.clear();
      _noteController.clear();
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
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'رقم هاتف تواصل إضافي (اختياري)',
                    hintText: 'رقم بديل للمندوب للتواصل عند الحاجة',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_enabled_outlined,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _noteController,
                    labelText: 'ملاحظات وتفاصيل الطلب (اختياري)',
                    hintText: 'مثال: بدون بصل، صوص زيادة، توصيل سريع...',
                    prefixIcon: Icons.edit_note_outlined,
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
                    text: 'مراجعة وتأكيد الطلب الآن 🚀',
                    onPressed: () => _showOrderConfirmation(cartProvider),
                  ),
                  const SizedBox(height: 80), // Spacing to avoid overlap with floating bottom bar
                ],
              ),
            ),
    );
  }

  ProductModel dynamicProduct(String id, String name, double price, String img) {
    return ProductModel(
      id: id,
      name: name,
      description: '',
      price: price,
      mainCategoryId: '',
      subCategoryId: '',
      images: [img],
      createdAt: DateTime.now(),
    );
  }

  void _showOrderConfirmation(CartProvider cartProvider) {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'تأكيد تفاصيل الطلب النهائي 📋',
                    style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  'ملخص الوجبات والمنتجات:',
                  style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...cartProvider.itemList.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.productName} (x${item.quantity})', style: AppFonts.cairoFont(fontSize: 12)),
                      Text(Formatters.formatCurrency(item.totalPrice), style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
                const Divider(height: 24),
                Text(
                  'تفاصيل التوصيل:',
                  style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildConfirmDetailRow('المنطقة:', cartProvider.selectedZone!.zoneName),
                _buildConfirmDetailRow('العنوان:', _addressController.text.trim()),
                if (_phoneController.text.trim().isNotEmpty)
                  _buildConfirmDetailRow('هاتف بديل:', _phoneController.text.trim()),
                if (_noteController.text.trim().isNotEmpty)
                  _buildConfirmDetailRow('الملاحظات:', _noteController.text.trim()),
                const Divider(height: 24),
                
                // Totals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('سعر التوصيل:', style: AppFonts.cairoFont(fontSize: 13)),
                    Text(Formatters.formatCurrency(cartProvider.deliveryFee), style: AppFonts.cairoFont(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المجموع الإجمالي:', style: AppFonts.cairoFont(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      Formatters.formatCurrency(cartProvider.totalAmount),
                      style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'إرسال وتأكيد الطلب النهائي 🚀',
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _placeOrder();
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'تعديل وإلغاء ❌',
                      style: AppFonts.cairoFont(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(val, style: AppFonts.cairoFont(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
