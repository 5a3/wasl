import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Premium Cached Image Widget with Shimmer loading placeholders
class CustomCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  const CustomCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final clipBorderRadius = borderRadius ?? BorderRadius.circular(12);

    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: clipBorderRadius,
        child: Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: errorWidget ?? const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: clipBorderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorListener: (error) {
          debugPrint('CustomCachedImage error for $imageUrl: $error');
          // If cached file was purged by OS cache manager or missing on disk, evict stale entry
          if (error.toString().contains('PathNotFoundException') ||
              error.toString().contains('No such file') ||
              error.toString().contains('libCachedImageData')) {
            CachedNetworkImage.evictFromCache(imageUrl);
          }
        },
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: width,
            height: height,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: errorWidget ?? const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}
