import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/product_model.dart';
import '../providers/cart_provider.dart';

/// Helper class to handle Cart operations safely, preventing cross-store additions
class CartHelper {
  /// Safely attempts to add a product to cart.
  /// If the cart contains items from a different store, prompts the user for confirmation first.
  static Future<bool> checkAndAddToCart({
    required BuildContext context,
    required ProductModel product,
    CategoryModel? category,
    bool showSnackBarOnSuccess = true,
  }) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (cartProvider.isFromDifferentStore(product)) {
      final currentStore = cartProvider.currentStoreName ?? 'مطعم آخر';
      final newStore = product.storeName ?? 'المطعم الجديد';

      final confirm = await CustomDialog.showConfirmDialog(
        context: context,
        title: 'تنبيه: سلة من مطعم آخر 🛒',
        message: 'لديك منتجات من مطعم "$currentStore" في السلة. هل تريد تفريغ السلة وإضافة هذا المنتج من "$newStore"؟',
        confirmText: 'تفريغ السلة والإضافة',
        cancelText: 'إلغاء',
        confirmColor: AppColors.primary,
      );

      if (confirm == true) {
        cartProvider.clearCart();
        cartProvider.addToCart(product, category: category);
        if (context.mounted && showSnackBarOnSuccess) {
          CustomDialog.showSuccessSnackBar(
            context,
            'تم تفريغ السلة والبدء بطلب جديد لمنتج ${product.name} 🍔',
          );
        }
        return true;
      }
      return false;
    } else {
      cartProvider.addToCart(product, category: category);
      if (context.mounted && showSnackBarOnSuccess) {
        CustomDialog.showSuccessSnackBar(
          context,
          'تم إضافة ${product.name} إلى السلة 🍔',
        );
      }
      return true;
    }
  }
}
