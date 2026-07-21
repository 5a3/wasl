import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/services/firebase_storage_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/product_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? productToEdit;

  const AddEditProductScreen({super.key, this.productToEdit});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  CategoryModel? _selectedMainCat;
  bool _isAvailable = true;
  bool _isUploading = false;

  final List<dynamic> _pickedImageFiles = []; // File or Uint8List
  List<String> _existingImageUrls = [];

  bool get isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productToEdit?.name ?? '');
    _descController = TextEditingController(text: widget.productToEdit?.description ?? '');
    _priceController = TextEditingController(text: widget.productToEdit?.price.toString() ?? '');
    _isAvailable = widget.productToEdit?.isAvailable ?? true;
    _existingImageUrls = List<String>.from(widget.productToEdit?.images ?? []);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProvider = Provider.of<CategoryProvider>(context, listen: false);
      if (isEditing) {
        final mainIndex = catProvider.mainCategories.indexWhere((c) => c.id == widget.productToEdit!.mainCategoryId);
        if (mainIndex != -1) {
          setState(() {
            _selectedMainCat = catProvider.mainCategories[mainIndex];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedList = await picker.pickMultiImage(limit: 3);
    if (pickedList.isNotEmpty) {
      _pickedImageFiles.clear();
      for (var item in pickedList.take(3)) {
        if (kIsWeb) {
          final bytes = await item.readAsBytes();
          _pickedImageFiles.add(bytes);
        } else {
          _pickedImageFiles.add(File(item.path));
        }
      }
      setState(() {});
    }
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMainCat == null) {
      CustomDialog.showErrorSnackBar(context, 'يرجى اختيار الفئة الرئيسية للمنتج');
      return;
    }

    // New products require at least 1 image
    if (!isEditing && _pickedImageFiles.isEmpty) {
      CustomDialog.showErrorSnackBar(context, 'يرجى اختيار صورة واحدة على الأقل للمنتج');
      return;
    }

    final prodProvider = Provider.of<ProductProvider>(context, listen: false);
    final prodName = _nameController.text.trim();
    final priceVal = double.tryParse(_priceController.text.trim()) ?? 0.0;

    setState(() {
      _isUploading = true;
    });

    try {
      final finalImageUrls = <String>[];
      List<String>? oldImageUrls;

      // If user is editing and picked new images, prepare to delete the old ones
      if (isEditing && _pickedImageFiles.isNotEmpty) {
        oldImageUrls = List<String>.from(_existingImageUrls);
      }

      // 1. Upload newly picked images to Storage folder <category_name>/<product_name>_index.jpg
      for (int i = 0; i < _pickedImageFiles.length; i++) {
        final url = await FirebaseStorageService.uploadProductImage(
          imageFile: _pickedImageFiles[i],
          categoryName: _selectedMainCat!.name,
          productName: prodName,
          imageIndex: i + 1,
        );
        finalImageUrls.add(url);
      }

      // If no new images picked during edit, retain existing image URLs
      if (finalImageUrls.isEmpty && isEditing) {
        finalImageUrls.addAll(_existingImageUrls);
      }

      bool ok = false;
      if (isEditing) {
        ok = await prodProvider.editProduct(
          id: widget.productToEdit!.id,
          name: prodName,
          description: _descController.text,
          price: priceVal,
          mainCategoryId: _selectedMainCat!.id,
          subCategoryId: _selectedMainCat!.id,
          images: finalImageUrls,
          isAvailable: _isAvailable,
        );
      } else {
        ok = await prodProvider.addProduct(
          name: prodName,
          description: _descController.text,
          price: priceVal,
          mainCategoryId: _selectedMainCat!.id,
          subCategoryId: _selectedMainCat!.id,
          images: finalImageUrls,
          isAvailable: _isAvailable,
        );
      }

      if (!mounted) return;

      if (ok) {
        // Delete the old replaced product images from Firebase Storage now that editing is fully completed
        if (oldImageUrls != null) {
          for (final url in oldImageUrls) {
            if (url.isNotEmpty) {
              await FirebaseStorageService.deleteImage(url);
            }
          }
        }

        if (!mounted) return;

        CustomDialog.showSuccessSnackBar(
          context,
          isEditing ? 'تم تعديل المنتج بنجاح' : 'تم إضافة المنتج وحفظ الصور بمجلد ${_selectedMainCat!.name}/',
        );
        Navigator.of(context).pop();
      } else if (prodProvider.errorMessage != null) {
        CustomDialog.showErrorSnackBar(context, prodProvider.errorMessage!);
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.showErrorSnackBar(context, 'خطأ في العملية: ${e.toString()}');
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
    final catProvider = Provider.of<CategoryProvider>(context);
    final mainCats = catProvider.mainCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'تعديل بيانات المنتج وسعره وتوفره' : 'إدخال بيانات الوجبة/العصير وصورها',
                style: AppFonts.cairoFont(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _nameController,
                labelText: 'اسم المنتج / الوجبة',
                hintText: 'مثال: عصير مانجو طازج، برجر لحم...',
                prefixIcon: Icons.fastfood_outlined,
                validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال اسم المنتج' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _descController,
                labelText: 'وصف المنتج بالتفصيل',
                hintText: 'مثال: طازج ومصنوع يومياً بدون مواد حافظة...',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _priceController,
                labelText: 'السعر (بالريال اليمني)',
                hintText: 'مثال: 1500',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money_outlined,
                validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال السعر' : null,
              ),
               const SizedBox(height: 14),
              DropdownButtonFormField<CategoryModel>(
                value: _selectedMainCat,
                decoration: const InputDecoration(
                  labelText: 'اختر الفئة التابع لها المنتج',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: mainCats.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.name))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedMainCat = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              Text(
                'صور المنتج (أقصى حد 3 صور تُحفظ بمجلد الفئة):',
                style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.photo_library, color: Colors.black),
                label: Text(
                  'اختيار صور من المعرض (حتى 3 صور)',
                  style: AppFonts.cairoFont(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                onPressed: _isUploading ? null : _pickImages,
              ),
              const SizedBox(height: 12),
              // Live Previews of selected or existing images
              if (_pickedImageFiles.isNotEmpty || _existingImageUrls.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._pickedImageFiles.map((file) => Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Image.memory(file, fit: BoxFit.cover)
                              : Image.file(file, fit: BoxFit.cover),
                        ),
                      )),
                      if (_pickedImageFiles.isEmpty)
                        ..._existingImageUrls.map((url) => Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(url, fit: BoxFit.cover),
                          ),
                        )),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('حالة توفر المنتج في القائمة', style: AppFonts.cairoFont(fontSize: 15, fontWeight: FontWeight.bold)),
                subtitle: Text(_isAvailable ? 'متوفر حالياً للعملاء 🟢' : 'غير متوفر مؤقتاً 🔴', style: AppFonts.cairoFont(fontSize: 12)),
                value: _isAvailable,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    _isAvailable = val;
                  });
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: isEditing ? 'حفظ التعديلات' : 'إضافة المنتج',
                isLoading: _isUploading,
                onPressed: _saveProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
