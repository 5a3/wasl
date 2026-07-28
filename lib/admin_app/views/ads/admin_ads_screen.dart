import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_cached_image.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/shimmer_loading_list.dart';
import '../../../shared/models/ad_model.dart';
import '../../providers/ad_provider.dart';

class AdminAdsScreen extends StatefulWidget {
  const AdminAdsScreen({super.key});

  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
  @override
  Widget build(BuildContext context) {
    final adProvider = Provider.of<AdProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة الإعلانات والتنبيهات 📢',
          style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_admin_ads',
        backgroundColor: AppColors.primary,
        onPressed: () => _openAddEditAdDialog(null),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إضافة إعلان جديد',
          style: AppFonts.cairoFont(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: adProvider.isLoading && adProvider.ads.isEmpty
          ? const ShimmerLoadingList(itemCount: 6, height: 80)
          : adProvider.ads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.campaign_outlined, size: 70, color: Colors.grey),
                      const SizedBox(height: 14),
                      Text(
                        'لا توجد إعلانات نشطة أو مضافة حالياً',
                        style: AppFonts.cairoFont(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: adProvider.ads.length,
                  itemBuilder: (ctx, index) {
                    final ad = adProvider.ads[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Ad Image Preview
                            CustomCachedImage(
                              imageUrl: ad.imageUrl,
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(12),
                              errorWidget: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                            const SizedBox(width: 14),

                            // Ad Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ad.title,
                                    style: AppFonts.cairoFont(fontSize: 14, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'أنشئ في: ${Formatters.formatDateTime(ad.createdAt)}',
                                    style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),

                            // Controls (Active Switch, Edit, Delete)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      ad.isActive ? 'نشط' : 'موقف',
                                      style: AppFonts.cairoFont(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: ad.isActive ? AppColors.success : AppColors.danger,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Switch(
                                      value: ad.isActive,
                                      activeColor: AppColors.primary,
                                      onChanged: (val) {
                                        adProvider.toggleAdStatus(ad.id, val);
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                                      onPressed: () => _openAddEditAdDialog(ad),
                                      tooltip: 'تعديل',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                      onPressed: () => _confirmDeleteAd(ad),
                                      tooltip: 'حذف',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  /// Dialog to add or edit an Ad
  void _openAddEditAdDialog(AdModel? adToEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdFormBottomSheet(adToEdit: adToEdit),
    );
  }

  /// Confirm Delete Dialog
  void _confirmDeleteAd(AdModel ad) async {
    final confirm = await CustomDialog.showConfirmDialog(
      context: context,
      title: 'حذف الإعلان 📢',
      message: 'هل أنت متأكد من حذف الإعلان "${ad.title}"؟ سيتم حذف الصورة بشكل نهائي من الخادم.',
      confirmColor: AppColors.danger,
    );

    if (confirm == true && mounted) {
      final ok = await Provider.of<AdProvider>(context, listen: false).deleteAd(ad.id, ad.imageUrl);
      if (ok && mounted) {
        CustomDialog.showSuccessSnackBar(context, 'تم حذف الإعلان بنجاح 🗑️');
      }
    }
  }
}

/// Helper stateful widget for modal form sheet
class _AdFormBottomSheet extends StatefulWidget {
  final AdModel? adToEdit;
  const _AdFormBottomSheet({this.adToEdit});

  @override
  State<_AdFormBottomSheet> createState() => _AdFormBottomSheetState();
}

class _AdFormBottomSheetState extends State<_AdFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _urlController; // Alternate web URL input

  dynamic _pickedImage; // File on mobile, Uint8List on web
  bool _isUploading = false;
  bool _isActive = true;

  bool get isEditing => widget.adToEdit != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.adToEdit?.title ?? '');
    _urlController = TextEditingController(text: widget.adToEdit?.imageUrl.startsWith('http') == true ? widget.adToEdit?.imageUrl : '');
    _isActive = widget.adToEdit?.isActive ?? true;
    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    if (_urlController.text.trim().isNotEmpty && _pickedImage != null) {
      setState(() {
        _pickedImage = null;
      });
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedImage = bytes;
          _urlController.clear(); // Clear web url if picker selected
        });
      } else {
        setState(() {
          _pickedImage = File(pickedFile.path);
          _urlController.clear(); // Clear web url if picker selected
        });
      }
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isEditing && _pickedImage == null && _urlController.text.trim().isEmpty) {
      CustomDialog.showErrorSnackBar(context, 'يرجى اختيار صورة من المعرض أو إدخال رابط صورة مباشر');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final adProvider = Provider.of<AdProvider>(context, listen: false);
    bool success;

    // Use picked file or raw text URL
    final dynamic imageToSend = _pickedImage ?? (_urlController.text.trim().isNotEmpty ? _urlController.text.trim() : null);

    if (isEditing) {
      success = await adProvider.updateAd(
        adId: widget.adToEdit!.id,
        title: _titleController.text.trim(),
        imageFile: imageToSend,
        isActive: _isActive,
        existingImageUrl: widget.adToEdit!.imageUrl,
      );
    } else {
      success = await adProvider.addAd(
        title: _titleController.text.trim(),
        imageFile: imageToSend!,
      );
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
      });

      if (success) {
        Navigator.of(context).pop();
        CustomDialog.showSuccessSnackBar(
          context,
          isEditing ? 'تم تعديل الإعلان بنجاح ✅' : 'تم إضافة الإعلان بنجاح ⚡',
        );
      } else if (adProvider.errorMessage != null) {
        CustomDialog.showErrorSnackBar(context, adProvider.errorMessage!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'تعديل الإعلان والتنبيه' : 'إضافة إعلان وتنبيه جديد',
                    style: AppFonts.cairoFont(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title input
              CustomTextField(
                controller: _titleController,
                labelText: 'عنوان الإعلان (الظاهر للعملاء)',
                hintText: 'ادخل عنوان الإعلان الجذاب...',
                prefixIcon: Icons.title,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'يرجى إدخال عنوان الإعلان';
                  if (val.trim().length < 5) return 'يجب أن لا يقل العنوان عن 5 أحرف';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image Selector
              Text(
                'صورة الإعلان الرئيسية 🖼️',
                style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text('اختيار من معرض الصور', style: AppFonts.cairoFont(fontSize: 12)),
                      onPressed: _isUploading ? null : _pickImage,
                    ),
                  ),
                ],
              ),

              // Preview Image
              if (_pickedImage != null || (isEditing && _urlController.text.isEmpty && widget.adToEdit?.imageUrl != null)) ...[
                const SizedBox(height: 12),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _pickedImage != null
                        ? (kIsWeb
                            ? Image.memory(_pickedImage as Uint8List, width: double.infinity, height: 130, fit: BoxFit.cover)
                            : Image.file(_pickedImage as File, width: double.infinity, height: 130, fit: BoxFit.cover))
                        : Image.network(widget.adToEdit!.imageUrl, width: double.infinity, height: 130, fit: BoxFit.cover),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // URL Input Option
              CustomTextField(
                controller: _urlController,
                labelText: 'أو ادخل رابط الصورة المباشر (اختياري)',
                hintText: 'https://example.com/image.jpg',
                prefixIcon: Icons.link,
              ),

              if (isEditing) ...[
                const SizedBox(height: 14),
                SwitchListTile(
                  title: Text(
                    'تنشيط الإعلان فوراً',
                    style: AppFonts.cairoFont(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'تفعيل الإعلان ليظهر مباشرة للعملاء في التطبيق',
                    style: AppFonts.cairoFont(fontSize: 11, color: Colors.grey),
                  ),
                  value: _isActive,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _isActive = val;
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              CustomButton(
                text: _isUploading
                    ? 'جاري حفظ الإعلان والرفع للـ Storage...'
                    : (isEditing ? 'تعديل الإعلان والتنبيه ⚡' : 'إنشاء إعلان وتنبيه 🚀'),
                onPressed: _isUploading ? null : _saveForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
