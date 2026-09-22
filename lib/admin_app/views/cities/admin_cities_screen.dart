import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/admin_permissions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/city_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/city_provider.dart';

class AdminCitiesScreen extends StatefulWidget {
  const AdminCitiesScreen({super.key});

  @override
  State<AdminCitiesScreen> createState() => _AdminCitiesScreenState();
}

class _AdminCitiesScreenState extends State<AdminCitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CityProvider>(context, listen: false).fetchCities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrEditCityDialog([CityModel? cityToEdit]) {
    final isEditing = cityToEdit != null;
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;

    if (isEditing) {
      if (admin != null && !admin.hasPermission(AdminPermissions.citiesEdit)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية تعديل المدن 🔒');
        return;
      }
    } else {
      if (admin != null && !admin.hasPermission(AdminPermissions.citiesAdd)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية إضافة مدن جديدة 🔒');
        return;
      }
    }

    final cityController = TextEditingController(text: cityToEdit?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final cityProvider = Provider.of<CityProvider>(context, listen: false);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'تعديل اسم المدينة' : 'إضافة مدينة جديدة',
            textAlign: TextAlign.center,
            style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: cityController,
                labelText: 'اسم المدينة *',
                hintText: 'مثال: حريضة، حورة، القطن...',
                prefixIcon: Icons.location_city,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = cityController.text.trim();
                if (name.isEmpty) {
                  CustomDialog.showErrorSnackBar(ctx, 'يرجى كتابة اسم المدينة');
                  return;
                }

                bool ok = false;
                if (isEditing) {
                  ok = await cityProvider.editCity(cityToEdit.id, name);
                } else {
                  ok = await cityProvider.addCity(name);
                }

                if (ok) {
                  if (ctx.mounted) {
                    CustomDialog.showSuccessSnackBar(
                      ctx,
                      isEditing ? 'تم تعديل اسم المدينة بنجاح' : 'تم إضافة المدينة بنجاح',
                    );
                    Navigator.of(ctx).pop();
                  }
                } else {
                  if (ctx.mounted) {
                    CustomDialog.showErrorSnackBar(
                      ctx,
                      cityProvider.errorMessage ?? 'حدث خطأ أثناء الحفظ',
                    );
                  }
                }
              },
              child: Text(
                isEditing ? 'تعديل' : 'إضافة',
                style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(CityModel city) async {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (admin != null && !admin.hasPermission(AdminPermissions.citiesDelete)) {
      CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية حذف المدن 🔒');
      return;
    }

    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'حذف المدينة',
      message: 'هل أنت تأكد من حذف مدينة "${city.name}"؟',
      confirmColor: AppColors.danger,
    );

    if (confirm == true && mounted) {
      final ok = await Provider.of<CityProvider>(context, listen: false).deleteCity(city.id);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم حذف المدينة بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة المدن 🏙️',
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_admin_cities',
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddOrEditCityDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة مدينة جديدة',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<CityProvider>(
        builder: (context, cityProvider, _) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    cityProvider.setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم المدينة...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: cityProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              cityProvider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: cityProvider.isLoading
                    ? const LoadingIndicator(message: 'جاري جلب قائمة المدن...')
                    : cityProvider.cities.isEmpty
                        ? Center(
                            child: Text(
                              cityProvider.searchQuery.isNotEmpty
                                  ? 'لا توجد نتائج مطابقة'
                                  : 'لا توجد مدن مضافة حالياً. قم بإضافة أول مدينة!',
                              style: AppFonts.cairoFont(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: cityProvider.cities.length,
                            itemBuilder: (ctx, index) {
                              final city = cityProvider.cities[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Icon(Icons.location_city, color: Colors.white),
                                  ),
                                  title: Text(
                                    city.name,
                                    style: AppFonts.cairoFont(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppColors.info),
                                        onPressed: () => _showAddOrEditCityDialog(city),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                        onPressed: () => _confirmDelete(city),
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
