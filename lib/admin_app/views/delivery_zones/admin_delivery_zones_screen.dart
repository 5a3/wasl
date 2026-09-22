import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/admin_permissions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/delivery_zone_model.dart';
import '../../../shared/models/store_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/delivery_zone_provider.dart';
import '../../providers/vendor_store_provider.dart';

class AdminDeliveryZonesScreen extends StatefulWidget {
  const AdminDeliveryZonesScreen({super.key});

  @override
  State<AdminDeliveryZonesScreen> createState() => _AdminDeliveryZonesScreenState();
}

class _AdminDeliveryZonesScreenState extends State<AdminDeliveryZonesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeliveryZoneProvider>(context, listen: false).fetchDeliveryZones();
      Provider.of<VendorStoreProvider>(context, listen: false).fetchStores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrEditZoneDialog([DeliveryZoneModel? zoneToEdit]) {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    final isEditing = zoneToEdit != null;

    if (isEditing) {
      if (admin != null && !admin.hasPermission(AdminPermissions.deliveryZonesEdit)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية تعديل مناطق التوصيل 🔒');
        return;
      }
    } else {
      if (admin != null && !admin.hasPermission(AdminPermissions.deliveryZonesAdd)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية إضافة مناطق توصيل جديدة 🔒');
        return;
      }
    }

    final zoneNameController = TextEditingController(text: zoneToEdit?.zoneName ?? '');
    final feeController = TextEditingController(text: zoneToEdit?.deliveryFee.toString() ?? '');
    String? selectedStoreId = zoneToEdit?.storeId;
    String? selectedStoreName = zoneToEdit?.storeName;

    showDialog(
      context: context,
      builder: (ctx) {
        final zoneProvider = Provider.of<DeliveryZoneProvider>(context, listen: false);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'تعديل منطقة/خدمة التوصيل' : 'إضافة منطقة/خدمة توصيل',
                textAlign: TextAlign.center,
                style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer<VendorStoreProvider>(
                      builder: (context, storeProv, _) {
                        final stores = storeProv.stores;
                        final hasMatch = stores.any((s) => s.id == selectedStoreId);
                        return DropdownButtonFormField<String?>(
                          value: hasMatch ? selectedStoreId : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'المطعم التابع له خيار التوصيل *',
                            labelStyle: AppFonts.cairoFont(fontSize: 13),
                            prefixIcon: const Icon(Icons.storefront, color: AppColors.primary),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'جميع المطاعم (عام)',
                                style: AppFonts.cairoFont(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ...stores.map((s) => DropdownMenuItem<String?>(
                                  value: s.id,
                                  child: Text(
                                    s.name,
                                    style: AppFonts.cairoFont(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: (val) {
                            if (val == null) {
                              setDialogState(() {
                                selectedStoreId = null;
                                selectedStoreName = null;
                              });
                              return;
                            }
                            final st = stores.where((s) => s.id == val);
                            setDialogState(() {
                              selectedStoreId = val;
                              selectedStoreName = st.isNotEmpty ? st.first.name : null;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: zoneNameController,
                      labelText: 'اسم المنطقة أو الخدمة',
                      hintText: 'مثال: داخل المدينة، الحي الماورائي...',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: feeController,
                      labelText: 'سعر التوصيل للمطعم المختار (بالريال اليمني)',
                      hintText: 'مثال: 500',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
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
                        storeId: selectedStoreId,
                        storeName: selectedStoreName,
                      );
                    } else {
                      ok = await zoneProvider.addDeliveryZone(
                        zoneName: name,
                        deliveryFee: fee,
                        storeId: selectedStoreId,
                        storeName: selectedStoreName,
                      );
                    }

                    if (ok) {
                      if (ctx.mounted) {
                        CustomDialog.showSuccessSnackBar(
                          ctx,
                          isEditing ? 'تم تعديل منطقة التوصيل بنجاح' : 'تم إضافة منطقة التوصيل بنجاح',
                        );
                        Navigator.of(ctx).pop();
                      }
                    }
                  },
                  child: Text(
                    isEditing ? 'تعديل' : 'حفظ',
                    style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(DeliveryZoneModel zone) async {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.deliveryZonesDelete)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية حذف مناطق التوصيل 🔒');
      return;
    }

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
    final admin = Provider.of<AdminAuthProvider>(context).currentAdmin;

    return Scaffold(
      floatingActionButton: (admin != null && admin.hasPermission(AdminPermissions.deliveryZonesAdd))
          ? FloatingActionButton.extended(
              heroTag: 'fab_admin_delivery_zones',
              backgroundColor: AppColors.primary,
              onPressed: () => _showAddOrEditZoneDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'إضافة منطقة توصيل',
                style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Consumer2<DeliveryZoneProvider, VendorStoreProvider>(
        builder: (context, zoneProvider, storeProvider, _) {
          final allZones = zoneProvider.zones;
          final stores = storeProvider.stores;

          // Filter by selected store
          final filteredZones = allZones.where((z) {
            if (_selectedStoreId != null && _selectedStoreId!.isNotEmpty) {
              return z.storeId == _selectedStoreId;
            }
            return true;
          }).toList();

          // Group delivery zones by storeId
          final Map<String?, List<DeliveryZoneModel>> groupedZones = {};
          for (var zone in filteredZones) {
            final key = zone.storeId;
            groupedZones.putIfAbsent(key, () => []).add(zone);
          }

          return Column(
            children: [
              // Search & Store Filter Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        zoneProvider.setSearchQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم منطقة التوصيل...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
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
                    const SizedBox(height: 8),
                    // Store Filter Dropdown
                    DropdownButtonFormField<String?>(
                      value: stores.any((s) => s.id == _selectedStoreId) ? _selectedStoreId : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'فرز مناطق التوصيل بحسب المطعم',
                        labelStyle: AppFonts.cairoFont(fontSize: 13),
                        prefixIcon: const Icon(Icons.storefront, color: AppColors.primary, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'عرض جميع المطاعم (${allZones.length} منطقة)',
                            style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...stores.map((s) {
                          final count = allZones.where((z) => z.storeId == s.id).length;
                          return DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(
                              '${s.name} ($count منطقة توصيل)',
                              style: AppFonts.cairoFont(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedStoreId = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: zoneProvider.isLoading
                    ? const LoadingIndicator(message: 'جاري جلب خدمات ومناطق التوصيل...')
                    : filteredZones.isEmpty
                        ? Center(
                            child: Text(
                              zoneProvider.searchQuery.isNotEmpty
                                  ? 'لا توجد نتائج مطابقة'
                                  : 'لا توجد مناطق توصيل مضافة لهذا المطعم',
                              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: groupedZones.keys.length,
                            itemBuilder: (ctx, index) {
                              final storeId = groupedZones.keys.elementAt(index);
                              final zonesInGroup = groupedZones[storeId]!;

                              StoreModel? store;
                              if (storeId != null) {
                                final matches = stores.where((s) => s.id == storeId);
                                if (matches.isNotEmpty) store = matches.first;
                              }

                              final storeTitle = store != null
                                  ? store.name
                                  : (zonesInGroup.first.storeName ?? 'مناطق توصيل عامة (جميع المطاعم)');

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppColors.primary.withAlpha(40)),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withAlpha(20),
                                    child: const Icon(Icons.two_wheeler, color: AppColors.primary, size: 20),
                                  ),
                                  title: Text(
                                    storeTitle,
                                    style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  subtitle: Text(
                                    '${zonesInGroup.length} مناطق توصيل خاصة بالمحل',
                                    style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  children: zonesInGroup.map((zone) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: const CircleAvatar(
                                          backgroundColor: AppColors.primary,
                                          radius: 18,
                                          child: Icon(Icons.location_on, color: Colors.white, size: 18),
                                        ),
                                        title: Text(
                                          zone.zoneName,
                                          style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          'سعر التوصيل: ${Formatters.formatCurrency(zone.deliveryFee)}',
                                          style: AppFonts.cairoFont(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (admin != null && admin.hasPermission(AdminPermissions.deliveryZonesEdit))
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                                                onPressed: () => _showAddOrEditZoneDialog(zone),
                                              ),
                                            if (admin != null && admin.hasPermission(AdminPermissions.deliveryZonesDelete))
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                                onPressed: () => _confirmDelete(zone),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
