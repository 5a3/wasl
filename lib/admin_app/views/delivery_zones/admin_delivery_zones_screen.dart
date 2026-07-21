import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../providers/delivery_zone_provider.dart';

class AdminDeliveryZonesScreen extends StatefulWidget {
  const AdminDeliveryZonesScreen({super.key});

  @override
  State<AdminDeliveryZonesScreen> createState() => _AdminDeliveryZonesScreenState();
}

class _AdminDeliveryZonesScreenState extends State<AdminDeliveryZonesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeliveryZoneProvider>(context, listen: false).fetchDeliveryZones();
    });
  }

  void _showAddZoneDialog() {
    final zoneNameController = TextEditingController();
    final feeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final zoneProvider = Provider.of<DeliveryZoneProvider>(context, listen: false);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'إضافة منطقة/خدمة توصيل',
            textAlign: TextAlign.center,
            style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: zoneNameController,
                labelText: 'اسم المنطقة أو الخدمة',
                hintText: 'مثال: داخل حريضة، خارج حريضة - منطقة أ...',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: feeController,
                labelText: 'سعر التوصيل (بالريال اليمني)',
                hintText: 'مثال: 500',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (zoneNameController.text.trim().isEmpty || feeController.text.trim().isEmpty) return;
                final ok = await zoneProvider.addDeliveryZone(
                  zoneName: zoneNameController.text,
                  deliveryFee: double.tryParse(feeController.text) ?? 0.0,
                );
                if (ok) {
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) CustomDialog.showSuccessSnackBar(context, 'تم إضافة منطقة التوصيل بنجاح');
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final zoneProvider = Provider.of<DeliveryZoneProvider>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showAddZoneDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة منطقة توصيل',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: zoneProvider.isLoading
          ? const LoadingIndicator(message: 'جاري جلب خدمات ومناطق التوصيل...')
          : zoneProvider.zones.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد مناطق توصيل مضافة حالياً',
                    style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: zoneProvider.zones.length,
                  itemBuilder: (ctx, index) {
                    final zone = zoneProvider.zones[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.location_on, color: Colors.white),
                        ),
                        title: Text(
                          zone.zoneName,
                          style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'سعر التوصيل: ${Formatters.formatCurrency(zone.deliveryFee)}',
                          style: AppFonts.cairoFont(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
