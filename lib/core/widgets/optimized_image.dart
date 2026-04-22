/// CYKEL — Optimized Image Widgets with Caching

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Cached network image with loading and error states
class OptimizedNetworkImage extends StatelessWidget {
  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      height: height,
      width: width,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            color: shimmerBase,
            child: const SizedBox.shrink(),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
      memCacheHeight: height != null ? (height! * 2).toInt() : null,
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
      maxHeightDiskCache: 1024,
      maxWidthDiskCache: 1024,
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

/// Cached circular avatar image
class OptimizedAvatarImage extends StatelessWidget {
  const OptimizedAvatarImage({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.backgroundColor,
  });

  final String imageUrl;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[200],
      backgroundImage: CachedNetworkImageProvider(
        imageUrl,
        maxHeight: (radius * 4).toInt(),
        maxWidth: (radius * 4).toInt(),
      ),
      onBackgroundImageError: (error, stackTrace) {},
    );
  }
}

/// Cached image provider for use in DecorationImage, etc.
class OptimizedImageProvider extends CachedNetworkImageProvider {
  const OptimizedImageProvider(
    super.url, {
    super.maxHeight = 1024,
    super.maxWidth = 1024,
  });
}
