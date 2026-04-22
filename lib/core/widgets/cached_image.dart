/// Reusable cached network image widget with shimmer placeholder
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Cached network image with automatic shimmer placeholder and error handling
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    // Use very conservative pixel ratio to reduce GPU memory pressure
    // Full DPR can exhaust GPU buffers on some devices
    final dpr = (MediaQuery.devicePixelRatioOf(context) * 0.5).clamp(1.0, 1.5);
    
    // Calculate optimal cache dimensions based on explicit or layout size
    // If width/height given, use them. Otherwise cap at screen width for hero images.
    final screenWidth = MediaQuery.sizeOf(context).width;
    
    // Handle unbounded constraints (Infinity) and provide sensible defaults
    final effectiveWidth = width ?? (screenWidth.isFinite ? screenWidth : 800.0);
    final effectiveHeight = height ?? (effectiveWidth * 0.75); // assume 4:3 for unknown
    
    // Safely convert to int only if finite - very reduced limits to prevent GPU exhaustion
    final memWidth = (effectiveWidth.isFinite ? (effectiveWidth * dpr).toInt() : 400).clamp(1, 500);
    final memHeight = (effectiveHeight.isFinite ? (effectiveHeight * dpr).toInt() : 300).clamp(1, 500);
    
    final child = CachedNetworkImage(
      imageUrl: imageUrl,
      width: (width != null && width!.isFinite) ? width : null,
      height: (height != null && height!.isFinite) ? height : null,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 80),
      memCacheWidth: memWidth,
      memCacheHeight: memHeight,
      maxWidthDiskCache: memWidth,
      maxHeightDiskCache: memHeight,
      // Reduce additional image filtering that can trigger GPU allocations
      filterQuality: FilterQuality.medium,
      placeholder: (context, url) => ShimmerPlaceholder(
        width: width,
        height: height,
      ),
      errorWidget: (context, url, error) => ImageErrorPlaceholder(
        width: width,
        height: height,
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }

    return child;
  }
}

/// Avatar with cached network image
class CachedAvatar extends StatelessWidget {
  const CachedAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.fallbackIcon = Icons.person,
  });

  final String? imageUrl;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.primaryLight,
        child: Icon(fallbackIcon, size: size * 0.6, color: AppColors.primary),
      );
    }

    // Avatars are small - cache at 2x size for retina
    final cacheSize = (size * 2).toInt();
    
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      memCacheWidth: cacheSize,
      memCacheHeight: cacheSize,
      maxWidthDiskCache: cacheSize,
      maxHeightDiskCache: cacheSize,
      fadeInDuration: const Duration(milliseconds: 200),
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: size / 2,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: size / 2,
        child: ShimmerPlaceholder(
          width: size,
          height: size,
          shape: BoxShape.circle,
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.primaryLight,
        child: Icon(fallbackIcon, size: size * 0.6, color: AppColors.primary),
      ),
    );
  }
}

/// Shimmer loading placeholder
class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          shape: shape,
        ),
      ),
    );
  }
}

/// Error placeholder for failed image loads
class ImageErrorPlaceholder extends StatelessWidget {
  const ImageErrorPlaceholder({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.broken_image,
        size: (width != null && height != null) 
          ? (width! < height! ? width! : height!) * 0.5 
          : 48,
        color: Colors.grey[400],
      ),
    );
  }
}
