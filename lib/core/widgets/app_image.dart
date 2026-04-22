/// CYKEL — Unified Image Loading System
/// 
/// This file provides a complete, production-ready image system with:
/// - Fast loading via cached_network_image
/// - Shimmer placeholders
/// - Automatic error handling
/// - Memory-optimized caching
/// - Support for thumbnails
/// 
/// Usage Guide:
/// 
/// For regular images:
///   AppImage(url: imageUrl, width: 200, height: 150)
/// 
/// For avatars:
///   AppAvatar(url: photoUrl, size: 40)
/// 
/// For DecorationImage:
///   AppImage.decorationImage(url: imageUrl)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'cached_image.dart';

/// Main image component - handles all network image loading
/// Uses thumbnails when available, falls back gracefully
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? url;
  final String? thumbnailUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    // Validate URL
    final validUrl = _getValidUrl();
    
    if (validUrl == null) {
      return _buildEmptyState();
    }

    return CachedImage(
      imageUrl: validUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }

  /// Get valid image URL, preferring thumbnail for small images
  String? _getValidUrl() {
    // Prefer thumbnail for small images
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      // Use thumbnail if image is small (< 200px)
      if ((width != null && width! < 200) || (height != null && height! < 200)) {
        return thumbnailUrl;
      }
    }
    
    // Fall back to main URL
    if (url != null && url!.isNotEmpty) {
      return url;
    }
    
    return null;
  }

  Widget _buildEmptyState() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_not_supported,
        size: (width != null && height != null) 
          ? (width! < height! ? width! : height!) * 0.5 
          : 48,
        color: Colors.grey[400],
      ),
    );
  }

  /// Create a DecorationImage for use in BoxDecoration
  static DecorationImage? decorationImage({
    required String? url,
    String? thumbnailUrl,
    BoxFit fit = BoxFit.cover,
    bool preferThumbnail = false,
  }) {
    String? validUrl;
    
    // Choose URL based on preference
    if (preferThumbnail && thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      validUrl = thumbnailUrl;
    } else if (url != null && url.isNotEmpty) {
      validUrl = url;
    } else if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      validUrl = thumbnailUrl;
    }
    
    if (validUrl == null) {
      return null;
    }
    
    return DecorationImage(
      image: CachedNetworkImageProvider(
        validUrl,
        maxHeight: preferThumbnail ? 400 : 1024,
        maxWidth: preferThumbnail ? 400 : 1024,
      ),
      fit: fit,
    );
  }

  /// Get an ImageProvider for use in CircleAvatar.backgroundImage
  static ImageProvider? provider({
    required String? url,
    String? thumbnailUrl,
    bool preferThumbnail = false,
    int maxSize = 200,
  }) {
    String? validUrl;
    
    // Choose URL based on preference
    if (preferThumbnail && thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      validUrl = thumbnailUrl;
    } else if (url != null && url.isNotEmpty) {
      validUrl = url;
    } else if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      validUrl = thumbnailUrl;
    }
    
    if (validUrl == null) {
      return null;
    }
    
    return CachedNetworkImageProvider(
      validUrl,
      maxHeight: maxSize,
      maxWidth: maxSize,
    );
  }
}

/// Avatar component with built-in fallbacks
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.url,
    this.thumbnailUrl,
    this.size = 40,
    this.fallbackText,
    this.fallbackIcon = Icons.person,
  });

  final String? url;
  final String? thumbnailUrl;
  final double size;
  final String? fallbackText;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    // Prefer thumbnail if provided, otherwise use main URL
    final displayUrl = thumbnailUrl ?? url;
    
    // If no valid URL, show fallback
    if (displayUrl == null || displayUrl.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        child: fallbackText != null
            ? Text(
                fallbackText!,
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(fallbackIcon, size: size * 0.6),
      );
    }
    
    // Use existing CachedAvatar component with display URL (thumbnail or full)
    return CachedAvatar(
      imageUrl: displayUrl,
      size: size,
      fallbackIcon: fallbackIcon,
    );
  }
}

/// Thumbnail-optimized image for lists and grids
class ThumbnailImage extends StatelessWidget {
  const ThumbnailImage({
    super.key,
    required this.url,
    this.thumbnailUrl,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? url;
  final String? thumbnailUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    // Always prefer thumbnail for small images
    final imageUrl = (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
        ? thumbnailUrl!
        : url;
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius,
        ),
        child: Icon(
          Icons.image,
          size: width * 0.5,
          color: Colors.grey[400],
        ),
      );
    }
    
    return CachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }
}

/// Helper functions for safe image URL handling
class ImageUrlHelper {
  /// Check if URL is valid and not empty
  static bool isValid(String? url) {
    return url != null && url.isNotEmpty && url.startsWith('http');
  }

  /// Get first valid URL from a list
  static String? firstValid(List<String?> urls) {
    for (final url in urls) {
      if (isValid(url)) return url;
    }
    return null;
  }

  /// Choose between thumbnail and full URL based on size
  static String? selectBySize({
    required String? url,
    required String? thumbnailUrl,
    required double? width,
    required double? height,
  }) {
    // Use thumbnail for small images
    if (isValid(thumbnailUrl) &&
        ((width != null && width < 200) || (height != null && height < 200))) {
      return thumbnailUrl;
    }
    
    // Fall back to full URL
    if (isValid(url)) return url;
    
    // Last resort thumbnail
    if (isValid(thumbnailUrl)) return thumbnailUrl;
    
    return null;
  }
}
