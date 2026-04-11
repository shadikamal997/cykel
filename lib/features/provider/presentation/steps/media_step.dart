/// CYKEL — Provider Onboarding: Step 5 – Media (Photos)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MediaStep extends StatelessWidget {
  const MediaStep({
    super.key,
    required this.logoFile,
    required this.onLogoChanged,
    required this.coverFile,
    required this.onCoverChanged,
    required this.galleryFiles,
    required this.onGalleryChanged,
  });

  final XFile? logoFile;
  final ValueChanged<XFile?> onLogoChanged;
  final XFile? coverFile;
  final ValueChanged<XFile?> onCoverChanged;
  final List<XFile> galleryFiles;
  final ValueChanged<List<XFile>> onGalleryChanged;

  static const _maxGallery = 8;

  Future<void> _pickImage(
    BuildContext context, {
    required ValueChanged<XFile> onPicked,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) onPicked(picked);
  }

  void _addToGallery(XFile file) {
    if (galleryFiles.length >= _maxGallery) return;
    onGalleryChanged([...galleryFiles, file]);
  }

  void _removeFromGallery(int index) {
    final copy = List<XFile>.from(galleryFiles)..removeAt(index);
    onGalleryChanged(copy);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(l10n.mediaTitle, style: AppTextStyles.headline3),
        const SizedBox(height: 20),

        // Logo
        Text(l10n.logoLabel, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        _ImageSlot(
          file: logoFile,
          hint: l10n.logoHint,
          icon: Icons.image_outlined,
          onTap: () => _pickImage(context, onPicked: (f) => onLogoChanged(f)),
          onRemove: () => onLogoChanged(null),
        ),
        const SizedBox(height: 24),

        // Cover photo
        Text(l10n.coverPhotoLabel, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        _ImageSlot(
          file: coverFile,
          hint: l10n.tapToUpload,
          icon: Icons.photo_outlined,
          aspectRatio: 16 / 9,
          onTap: () =>
              _pickImage(context, onPicked: (f) => onCoverChanged(f)),
          onRemove: () => onCoverChanged(null),
        ),
        const SizedBox(height: 24),

        // Gallery
        Row(
          children: [
            Text(l10n.galleryLabel, style: AppTextStyles.labelMedium),
            const Spacer(),
            Text(
              '${galleryFiles.length} / $_maxGallery',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(galleryFiles.length, (i) {
              return _GalleryThumbnail(
                file: galleryFiles[i],
                onRemove: () => _removeFromGallery(i),
              );
            }),
            if (galleryFiles.length < _maxGallery)
              _AddGalleryButton(
                onTap: () =>
                    _pickImage(context, onPicked: _addToGallery),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Image Slot ───────────────────────────────────────────────────────────────

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({
    required this.file,
    required this.hint,
    required this.icon,
    required this.onTap,
    required this.onRemove,
    this.aspectRatio = 1,
  });

  final XFile? file;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (file != null) {
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(file!.path),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        file!.name,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filled(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 16),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.9),
                foregroundColor: Colors.white,
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
              ),
              tooltip: l10n.removePhoto,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                hint,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gallery Thumbnail ────────────────────────────────────────────────────────

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({
    required this.file,
    required this.onRemove,
  });

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(file.path),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.image_rounded,
                    color: AppColors.primary, size: 28),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Gallery Button ───────────────────────────────────────────────────────

class _AddGalleryButton extends StatelessWidget {
  const _AddGalleryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined,
            color: AppColors.textSecondary, size: 28),
      ),
    );
  }
}
