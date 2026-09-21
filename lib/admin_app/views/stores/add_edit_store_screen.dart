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
import '../../../shared/models/store_model.dart';
import '../../providers/vendor_store_provider.dart';

class AddEditStoreScreen extends StatefulWidget {
  final StoreModel? storeToEdit;

  const AddEditStoreScreen({super.key, this.storeToEdit});

  @override
  State<AddEditStoreScreen> createState() => _AddEditStoreScreenState();
}

class _AddEditStoreScreenState extends State<AddEditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _ratingController;
  bool _isOpen = true;
  bool _isSaving = false;

  dynamic _pickedLogoFile;
  String? _pickedLogoName;

  dynamic _pickedCoverFile;
  String? _pickedCoverName;

  bool get isEditing => widget.storeToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.storeToEdit?.name ?? '');
    _phoneController = TextEditingController(text: widget.storeToEdit?.phone ?? '');
    _addressController = TextEditingController(text: widget.storeToEdit?.address ?? '');
    _descriptionController = TextEditingController(text: widget.storeToEdit?.description ?? '');
    _ratingController = TextEditingController(text: (widget.storeToEdit?.rating ?? 5.0).toString());
    _isOpen = widget.storeToEdit?.isOpen ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedLogoFile = bytes;
          _pickedLogoName = picked.name;
        });
      } else {
        setState(() {
          _pickedLogoFile = File(picked.path);
          _pickedLogoName = picked.name;
        });
      }
    }
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedCoverFile = bytes;
          _pickedCoverName = picked.name;
        });
      } else {
        setState(() {
          _pickedCoverFile = File(picked.path);
          _pickedCoverName = picked.name;
        });
      }
    }
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = Provider.of<VendorStoreProvider>(context, listen: false);
    final storeName = _nameController.text.trim();

    try {
      String logoUrl = widget.storeToEdit?.logoUrl ?? '';
      String? oldLogoUrl;

      if (_pickedLogoFile != null) {
        if (isEditing && logoUrl.isNotEmpty) {
          oldLogoUrl = logoUrl;
        }
        logoUrl = await FirebaseStorageService.uploadStoreLogo(
          imageFile: _pickedLogoFile,
          storeName: storeName,
        );
      }

      String coverUrl = widget.storeToEdit?.coverUrl ?? '';
      String? oldCoverUrl;

      if (_pickedCoverFile != null) {
        if (isEditing && coverUrl.isNotEmpty) {
          oldCoverUrl = coverUrl;
        }
        coverUrl = await FirebaseStorageService.uploadStoreCover(
          imageFile: _pickedCoverFile,
          storeName: storeName,
        );
      }

      final store = StoreModel(
        id: widget.storeToEdit?.id ?? '',
        name: storeName,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        logoUrl: logoUrl,
        coverUrl: coverUrl,
        rating: double.tryParse(_ratingController.text.trim()) ?? 5.0,
        isOpen: _isOpen,
        createdAt: widget.storeToEdit?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (isEditing) {
        success = await provider.updateStore(store);
      } else {
        success = await provider.addStore(store);
      }

      if (!mounted) return;

      if (success) {
        // Delete old replaced images from Firebase Storage
        if (oldLogoUrl != null && oldLogoUrl.isNotEmpty) {
          await FirebaseStorageService.deleteImage(oldLogoUrl);
        }
        if (oldCoverUrl != null && oldCoverUrl.isNotEmpty) {
          await FirebaseStorageService.deleteImage(oldCoverUrl);
        }

        if (!mounted) return;

        CustomDialog.showSuccessSnackBar(
          context,
          isEditing ? 'تم تعديل بيانات المطعم بنجاح' : 'تم إضافة المطعم وحفظ الصّور في المجلد stores/ بنجاح',
        );
        Navigator.of(context).pop();
      } else {
        CustomDialog.showErrorSnackBar(context, provider.error ?? 'حدث خطأ أثناء الحفظ');
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.showErrorSnackBar(context, 'خطأ الرفع: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل مطعم / متجر' : 'إضافة مطعم جديد',
          style: AppFonts.cairoFont(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Cover Section (صورة الغلاف)
              Text(
                'صورة الغلاف / الخلفية (Cover):',
                style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isSaving ? null : _pickCover,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: _pickedCoverFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: kIsWeb
                              ? Image.memory(_pickedCoverFile, fit: BoxFit.cover, width: double.infinity)
                              : Image.file(_pickedCoverFile, fit: BoxFit.cover, width: double.infinity),
                        )
                      : (widget.storeToEdit?.coverUrl != null && widget.storeToEdit!.coverUrl!.isNotEmpty
                          ? CustomCachedImage(
                              imageUrl: widget.storeToEdit!.coverUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              borderRadius: BorderRadius.circular(14),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.landscape, size: 40, color: AppColors.primary),
                                const SizedBox(height: 8),
                                Text(
                                  'اضغط هنا لاختيار صورة الغلاف من المعرض',
                                  style: AppFonts.cairoFont(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )),
                ),
              ),
              if (_pickedCoverName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'غلاف مختار: $_pickedCoverName',
                  style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 20),

              // Store Logo Section (صورة الشعار)
              Text(
                'صورة الشعار (Logo):',
                style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _isSaving ? null : _pickLogo,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: _pickedLogoFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: kIsWeb
                                  ? Image.memory(_pickedLogoFile, fit: BoxFit.cover)
                                  : Image.file(_pickedLogoFile, fit: BoxFit.cover),
                            )
                          : (widget.storeToEdit?.logoUrl != null && widget.storeToEdit!.logoUrl!.isNotEmpty
                              ? CustomCachedImage(
                                  imageUrl: widget.storeToEdit!.logoUrl!,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(14),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 30, color: AppColors.primary),
                                    SizedBox(height: 4),
                                    Text('الشعار', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ],
                                )),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _pickedLogoName != null
                          ? 'الشعار المختار: $_pickedLogoName'
                          : 'اضغط على المربع لاختيار شعار المطعم من المعرض.',
                      style: AppFonts.cairoFont(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _nameController,
                labelText: 'اسم المطعم / المتجر *',
                hintText: 'مثال: مطعم الأمازون',
                prefixIcon: Icons.store,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المطعم' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: 'رقم هاتف التواصل',
                hintText: '77XXXXXXX',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                labelText: 'عنوان المطعم / الموقع',
                hintText: 'مثال: صنعاء - حدة - الشارع العام',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'وصف المطعم',
                hintText: 'أفضل الوجبات السريعة والمشاوي...',
                maxLines: 3,
                prefixIcon: Icons.description,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _ratingController,
                labelText: 'التقييم الابتدائي (من 5)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.star,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                activeColor: AppColors.primary,
                title: Text(
                  'حالة المطعم (مفتوح لاستقبال الطلبات)',
                  style: AppFonts.cairoFont(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _isOpen ? 'المطعم يظهر كمفتوح للعملاء' : 'المطعم يظهر كمغلق حالياً',
                  style: AppFonts.cairoFont(fontSize: 12, color: Colors.grey),
                ),
                value: _isOpen,
                onChanged: (val) => setState(() => _isOpen = val),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: isEditing ? 'تعديل البيانات' : 'حفظ وإضافة المطعم',
                isLoading: _isSaving,
                onPressed: _saveStore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

