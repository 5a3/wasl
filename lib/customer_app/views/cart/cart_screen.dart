import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../admin_app/providers/delivery_zone_provider.dart';
import '../../../admin_app/providers/payment_method_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../shared/models/delivery_zone_model.dart';
import '../../../shared/models/payment_method_model.dart';
import '../../../shared/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_auth_provider.dart';
import '../../providers/customer_order_provider.dart';
import '../../../shared/providers/store_provider.dart';

class CartScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback? onOrderPlaced;
  final VoidCallback? onGoToMenu;

  const CartScreen({
    super.key,
    this.scrollController,
    this.onOrderPlaced,
    this.onGoToMenu,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMethodModel? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeliveryZoneProvider>(context, listen: false).fetchDeliveryZones();
      Provider.of<PaymentMethodProvider>(context, listen: false).fetchPaymentMethods();
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
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    if (!storeProvider.isOpen) {
      CustomDialog.showErrorSnackBar(context, 'المحل مغلق حالياً 🔴 لا يمكن إرسال الطلبات الآن.');
      return;
    }

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
      paymentMethod: _selectedPaymentMethod,
      storeId: cartProvider.currentStoreId,
      storeName: cartProvider.currentStoreName,
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
      widget.onOrderPlaced?.call();
    } else if (orderProvider.errorMessage != null) {
      CustomDialog.showErrorSnackBar(context, orderProvider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final zoneProvider = Provider.of<DeliveryZoneProvider>(context);
    final storeProvider = Provider.of<StoreProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: cartProvider.itemList.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'سلة التسوق فارغة 🛒',
                      style: AppFonts.cairoFont(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لم تقم بإضافة أي وجبات أو أطباق شهية إلى سلتك بعد.',
                      textAlign: TextAlign.center,
                      style: AppFonts.cairoFont(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.restaurant_menu_rounded, size: 20),
                      label: Text(
                        'تصفح الوجبات واطلب الآن 🍽️',
                        style: AppFonts.cairoFont(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        if (widget.onGoToMenu != null) {
                          widget.onGoToMenu!.call();
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              controller: widget.scrollController,
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
                  Builder(
                    builder: (context) {
                      final storeZones = zoneProvider.getZonesByStore(cartProvider.currentStoreId).where((z) => z.isActive).toList();
                      final selectedZone = cartProvider.selectedZone;
                      final validZone = (selectedZone != null && storeZones.any((z) => z.id == selectedZone.id))
                          ? storeZones.firstWhere((z) => z.id == selectedZone.id)
                          : null;

                      return DropdownButtonFormField<DeliveryZoneModel>(
                        isExpanded: true,
                        value: validZone,
                        decoration: const InputDecoration(
                          labelText: 'اختر منطقة التوصيل (المحددة لهذا المطعم)',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        items: storeZones.map((zone) {
                          return DropdownMenuItem(
                            value: zone,
                            child: Text(
                              '${zone.zoneName} (+${Formatters.formatCurrency(zone.deliveryFee)})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          cartProvider.setSelectedZone(val);
                        },
                      );
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
                  const SizedBox(height: 18),
                  Text(
                    'طريقة ووسيلة الدفع 💳',
                    style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Consumer<PaymentMethodProvider>(
                    builder: (ctx, pmProvider, _) {
                      final activeMethods = pmProvider.getPaymentMethodsByStore(cartProvider.currentStoreId).where((m) => m.isActive).toList();

                      if (pmProvider.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (activeMethods.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: Text(
                            'طريقة الدفع الافتراضية: الدفع نقداً عند الاستلام 💵',
                            style: AppFonts.cairoFont(fontSize: 13, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      // Auto-select first active method if null
                      if (_selectedPaymentMethod == null || !activeMethods.any((m) => m.id == _selectedPaymentMethod!.id)) {
                        _selectedPaymentMethod = activeMethods.first;
                      }

                      return Column(
                        children: activeMethods.map((method) {
                          final isSelected = _selectedPaymentMethod?.id == method.id;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withAlpha(15) : (isDark ? AppColors.darkSurface : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: RadioListTile<String>(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              value: method.id,
                              groupValue: _selectedPaymentMethod?.id,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _selectedPaymentMethod = method;
                                });
                              },
                              title: Text(
                                method.name,
                                style: AppFonts.cairoFont(fontSize: 13.5, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (method.accountNumber.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'رقم الحساب/المحفظة للتحويل: ${method.accountNumber}',
                                      style: AppFonts.cairoFont(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                  if (method.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      method.description,
                                      style: AppFonts.cairoFont(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
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
                  if (!storeProvider.isOpen) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'المحل مغلق حالياً 🔴 (${storeProvider.closedReason ?? "لا يمكن استقبال الطلبات الآن"})',
                              style: AppFonts.cairoFont(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'المحل مغلق حالياً - لا يمكن إتمام الطلب 🔴',
                      onPressed: null,
                      backgroundColor: Colors.grey.shade400,
                    ),
                  ] else ...[
                    CustomButton(
                      text: 'مراجعة وتأكيد الطلب الآن 🚀',
                      onPressed: () => _showOrderConfirmation(cartProvider),
                    ),
                  ],
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.only(
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
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
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
                _buildConfirmDetailRow(context, 'طريقة الدفع:', _selectedPaymentMethod?.name ?? 'الدفع عند الاستلام 💵'),
                _buildConfirmDetailRow(context, 'المنطقة:', cartProvider.selectedZone!.zoneName),
                _buildConfirmDetailRow(context, 'العنوان:', _addressController.text.trim()),
                if (_phoneController.text.trim().isNotEmpty)
                  _buildConfirmDetailRow(context, 'هاتف بديل:', _phoneController.text.trim()),
                if (_noteController.text.trim().isNotEmpty)
                  _buildConfirmDetailRow(context, 'الملاحظات:', _noteController.text.trim()),
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

  Widget _buildConfirmDetailRow(BuildContext context, String label, String val) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.cairoFont(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade700, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(val, style: AppFonts.cairoFont(fontSize: 12, color: isDark ? AppColors.darkTextPrimary : Colors.black87)),
          ),
        ],
      ),
    );
  }
}
