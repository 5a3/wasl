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
  late TextEditingController _urlController;

  CategoryModel? _selectedMainCategory;
  dynamic _pickedImageFile;
  String? _pickedImageName;
  bool _isUploading = false;

  bool get isEditing => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
    _urlController = TextEditingController(text: widget.categoryToEdit?.imageUrl ?? '');

    if (isEditing && widget.categoryToEdit?.parentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final catProvider = Provider.of<CategoryProvider>(context, listen: false);
        final parentIndex = catProvider.mainCategories.indexWhere((c) => c.id == widget.categoryToEdit!.parentId);
        if (parentIndex != -1) {
          setState(() {
            _selectedMainCategory = catProvider.mainCategories[parentIndex];
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    final categoryName = _nameController.text.trim();
    final catProvider = Provider.of<CategoryProvider>(context, listen: false);

    setState(() {
      _isUploading = true;
    });

    try {
      String imageUrl = _urlController.text.trim();

      // If user picked a new file, upload to main/<categoryName>/<categoryName>_<timestamp>.jpg
      if (_pickedImageFile != null) {
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
          parentId: _selectedMainCategory?.id,
          imageUrl: imageUrl,
        );
      } else {
        ok = await catProvider.addCategory(
          name: categoryName,
          parentId: _selectedMainCategory?.id,
          imageUrl: imageUrl,
        );
      }

      if (!mounted) return;

      if (ok) {
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
    final catProvider = Provider.of<CategoryProvider>(context);
    final mainCats = catProvider.mainCategories
        .where((c) => c.id != widget.categoryToEdit?.id)
        .toList();

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
              DropdownButtonFormField<CategoryModel?>(
                value: _selectedMainCategory,
                decoration: const InputDecoration(
                  labelText: 'الفئة الرئيسية (اتركه فارغاً إذا كانت فئة أصلية)',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('فئة رئيسية أصلية'),
                  ),
                  ...mainCats.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name),
                      )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedMainCategory = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              Text(
                'صورة الفئة (تخزن في المجلد main/اسم_الفئة/):',
                style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
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
                      : (_urlController.text.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(_urlController.text, fit: BoxFit.cover, width: double.infinity),
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
              const SizedBox(height: 16),
              CustomTextField(
                controller: _urlController,
                labelText: 'أو ادخل رابط صورة مباشر (URL)',
                hintText: 'https://example.com/image.jpg',
                prefixIcon: Icons.link_outlined,
              ),
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
