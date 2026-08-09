import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/services/firebase_storage_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/constants/admin_permissions.dart';
import '../../../shared/models/category_model.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/category_provider.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final CategoryModel? categoryToEdit;

  const AddEditCategoryScreen({super.key, this.categoryToEdit});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _discountValueController;

  dynamic _pickedImageFile;
  String? _pickedImageName;
  bool _isUploading = false;
  bool _hasDiscount = false;
  String _discountType = 'percentage';

  bool get isEditing => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
    _discountValueController = TextEditingController(
      text: widget.categoryToEdit != null && widget.categoryToEdit!.discountValue > 0
          ? widget.categoryToEdit!.discountValue.toString()
          : '',
    );
    _hasDiscount = widget.categoryToEdit?.hasDiscount ?? false;
    _discountType = widget.categoryToEdit?.discountType ?? 'percentage';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImageFile = bytes;
          _pickedImageName = picked.name;
        });
      } else {
        setState(() {
          _pickedImageFile = File(picked.path);
          _pickedImageName = picked.name;
        });
      }
    }
  }

  void _saveCategory() async {
    final admin = Provider.of<AdminAuthProvider>(context, listen: false).currentAdmin;
    if (isEditing) {
      if (admin != null && !admin.hasPermission(AdminPermissions.categoriesEdit)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية تعديل الفئات 🔒');
        return;
      }
    } else {
      if (admin != null && !admin.hasPermission(AdminPermissions.categoriesAdd)) {
        CustomDialog.showErrorSnackBar(context, 'عذراً، حسابك لا يمتلك صلاحية إضافة فئات جديدة 🔒');
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    // A category image is strictly required when creating a new category
    if (!isEditing && _pickedImageFile == null) {
      CustomDialog.showErrorSnackBar(context, 'يرجى اختيار صورة للفئة أولاً');
      return;
    }

    final categoryName = _nameController.text.trim();
    final discountVal = _hasDiscount ? (double.tryParse(_discountValueController.text.trim()) ?? 0.0) : 0.0;
    final catProvider = Provider.of<CategoryProvider>(context, listen: false);

    setState(() {
      _isUploading = true;
    });

    try {
      String imageUrl = widget.categoryToEdit?.imageUrl ?? '';
      String? oldImageUrl;

      // If user picked a new file, upload to Firebase Storage
      if (_pickedImageFile != null) {
        if (isEditing && imageUrl.isNotEmpty) {
          oldImageUrl = imageUrl;
        }
        imageUrl = await FirebaseStorageService.uploadCategoryImage(
          imageFile: _pickedImageFile,
          categoryName: categoryName,
        );
      }

      bool ok = false;
      if (isEditing) {
        ok = await catProvider.editCategory(
          id: widget.categoryToEdit!.id,
          name: categoryName,
          parentId: null,
          imageUrl: imageUrl,
          hasDiscount: _hasDiscount,
          discountType: _discountType,
          discountValue: discountVal,
        );
      } else {
        ok = await catProvider.addCategory(
          name: categoryName,
          parentId: null,
          imageUrl: imageUrl,
          hasDiscount: _hasDiscount,
          discountType: _discountType,
          discountValue: discountVal,
        );
      }

      if (!mounted) return;

      if (ok) {
        // Delete the old replaced image from Firebase Storage since the new one successfully saved
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await FirebaseStorageService.deleteImage(oldImageUrl);
        }

        if (!mounted) return;

        CustomDialog.showSuccessSnackBar(
          context,
          isEditing
              ? 'تم تعديل الفئة وحفظ البيانات بنجاح'
              : 'تم إضافة الفئة بنجاح وحفظ الصورة بمجلد main/$categoryName/',
        );
        Navigator.of(context).pop();
      } else if (catProvider.errorMessage != null) {
        CustomDialog.showErrorSnackBar(context, catProvider.errorMessage!);
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.showErrorSnackBar(context, 'خطأ الرفع: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل الفئة' : 'إضافة فئة جديدة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'تعديل بيانات وصورة الفئة' : 'إدخال تفاصيل الفئة وصورتها في السيرفر',
                style: AppFonts.cairoFont(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _nameController,
                labelText: 'اسم الفئة',
                hintText: 'مثال: عصائر طازجة، وجبات سريعة...',
                prefixIcon: Icons.category_outlined,
                validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال اسم الفئة' : null,
              ),
              const SizedBox(height: 16),
              // Category Discount Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hasDiscount ? AppColors.primary.withAlpha(15) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hasDiscount ? AppColors.primary : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'تفعيل عرض / خصم شامل على جميع منتجات هذه الفئة 💥',
                        style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _hasDiscount ? 'سيتم تطبيق الخصم تلقائياً على كل الوجبات بالقسم 🟢' : 'بدون خصم شامل للفئة',
                        style: AppFonts.cairoFont(fontSize: 12),
                      ),
                      value: _hasDiscount,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _hasDiscount = val;
                        });
                      },
                    ),
                    if (_hasDiscount) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _discountType,
                              decoration: const InputDecoration(
                                labelText: 'نوع الخصم',
                                prefixIcon: Icon(Icons.local_offer_outlined),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'percentage', child: Text('نسبة %', overflow: TextOverflow.ellipsis)),
                                DropdownMenuItem(value: 'fixed', child: Text('مبلغ ر.ي', overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _discountType = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: CustomTextField(
                              controller: _discountValueController,
                              labelText: _discountType == 'percentage' ? 'نسبة الخصم (%)' : 'مبلغ الخصم (ر.ي)',
                              hintText: _discountType == 'percentage' ? 'مثال: 15' : 'مثال: 300',
                              keyboardType: TextInputType.number,
                              prefixIcon: _discountType == 'percentage' ? Icons.percent : Icons.money_off_outlined,
                              validator: (val) {
                                if (!_hasDiscount) return null;
                                if (val == null || val.trim().isEmpty) return 'ادخل قيمة الخصم';
                                final numVal = double.tryParse(val.trim());
                                if (numVal == null || numVal <= 0) return 'قيمة غير صحيحة';
                                if (_discountType == 'percentage' && numVal > 100) return 'النسبة لا تتجاوز 100%';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'صورة الفئة (تخزن في المجلد main/اسم_الفئة/):',
                style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: _pickedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: kIsWeb
                              ? Image.memory(_pickedImageFile, fit: BoxFit.cover, width: double.infinity)
                              : Image.file(_pickedImageFile, fit: BoxFit.cover, width: double.infinity),
                        )
                      : (widget.categoryToEdit != null && widget.categoryToEdit!.imageUrl.isNotEmpty
                          ? CustomCachedImage(
                              imageUrl: widget.categoryToEdit!.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              borderRadius: BorderRadius.circular(14),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
                                const SizedBox(height: 8),
                                Text(
                                  'اضغط هنا لاختيار صورة الفئة من المعرض',
                                  style: AppFonts.cairoFont(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )),
                ),
              ),
              if (_pickedImageName != null) ...[
                const SizedBox(height: 6),
                Text(
                  'الصورة المختارة: $_pickedImageName',
                  style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                text: isEditing ? 'حفظ التعديلات' : 'إضافة الفئة',
                isLoading: _isUploading,
                onPressed: _saveCategory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
