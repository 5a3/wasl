import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/delivery_zone_model.dart';
import '../../providers/delivery_zone_provider.dart';

class AdminDeliveryZonesScreen extends StatefulWidget {
  const AdminDeliveryZonesScreen({super.key});

  @override
  State<AdminDeliveryZonesScreen> createState() => _AdminDeliveryZonesScreenState();
}

class _AdminDeliveryZonesScreenState extends State<AdminDeliveryZonesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeliveryZoneProvider>(context, listen: false).fetchDeliveryZones();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrEditZoneDialog([DeliveryZoneModel? zoneToEdit]) {
    final isEditing = zoneToEdit != null;
    final zoneNameController = TextEditingController(text: zoneToEdit?.zoneName ?? '');
    final feeController = TextEditingController(text: zoneToEdit?.deliveryFee.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final zoneProvider = Provider.of<DeliveryZoneProvider>(context, listen: false);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'تعديل منطقة/خدمة التوصيل' : 'إضافة منطقة/خدمة توصيل',
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
                final name = zoneNameController.text.trim();
                final fee = double.tryParse(feeController.text.trim()) ?? 0.0;

                if (name.isEmpty) return;

                bool ok = false;
                if (isEditing) {
                  ok = await zoneProvider.editDeliveryZone(
                    id: zoneToEdit.id,
                    zoneName: name,
                    deliveryFee: fee,
                  );
                } else {
                  ok = await zoneProvider.addDeliveryZone(
                    zoneName: name,
                    deliveryFee: fee,
                  );
                }

                if (ok) {
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    CustomDialog.showSuccessSnackBar(
                      context,
                      isEditing ? 'تم تعديل منطقة التوصيل بنجاح' : 'تم إضافة منطقة التوصيل بنجاح',
                    );
                  }
                }
              },
              child: Text(isEditing ? 'تعديل' : 'حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(DeliveryZoneModel zone) async {
    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'حذف منطقة التوصيل',
      message: 'هل أنت تأكد من حذف منطقة "${zone.zoneName}"؟',
      confirmColor: AppColors.danger,
    );

    if (confirm == true && mounted) {
      final ok = await Provider.of<DeliveryZoneProvider>(context, listen: false).deleteDeliveryZone(zone.id);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم حذف منطقة التوصيل بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_admin_delivery_zones',
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddOrEditZoneDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة منطقة توصيل',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<DeliveryZoneProvider>(
        builder: (context, zoneProvider, _) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    zoneProvider.setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم منطقة التوصيل...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: zoneProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              zoneProvider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: zoneProvider.isLoading
                    ? const LoadingIndicator(message: 'جاري جلب خدمات ومناطق التوصيل...')
                    : zoneProvider.zones.isEmpty
                        ? Center(
                            child: Text(
                              zoneProvider.searchQuery.isNotEmpty ? 'لا توجد نتائج مطابقة' : 'لا توجد مناطق توصيل مضافة حالياً',
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
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppColors.info),
                                        onPressed: () => _showAddOrEditZoneDialog(zone),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                        onPressed: () => _confirmDelete(zone),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
