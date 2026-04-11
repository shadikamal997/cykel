/// CYKEL — Manage Photos Screen
/// Lets the provider view current logo/cover/gallery and replace or
/// add images. Uploads go through [ProviderService], URLs are persisted
/// back to the provider document.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/provider_service.dart';
import '../domain/provider_model.dart';
import '../providers/provider_providers.dart';

class ManagePhotosScreen extends ConsumerStatefulWidget {
  const ManagePhotosScreen({super.key});

  @override
  ConsumerState<ManagePhotosScreen> createState() =>
      _ManagePhotosScreenState();
}

class _ManagePhotosScreenState extends ConsumerState<ManagePhotosScreen> {
  bool _busy = false;
  static const _maxGallery = 8;

  Future<XFile?> _pick() async {
    final picker = ImagePicker();
    return picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
  }

  Future<void> _changeLogo(CykelProvider provider) async {
    final file = await _pick();
    if (file == null) return;
    await _upload(
      provider,
      action: () async {
        final url = await ref
            .read(providerServiceProvider)
            .uploadSingleImage(provider.userId, file);
        await ref
            .read(providerServiceProvider)
            .updateProvider(provider.copyWith(logoUrl: url));
      },
    );
  }

  Future<void> _changeCover(CykelProvider provider) async {
    final file = await _pick();
    if (file == null) return;
    await _upload(
      provider,
      action: () async {
        final url = await ref
            .read(providerServiceProvider)
            .uploadSingleImage(provider.userId, file);
        await ref
            .read(providerServiceProvider)
            .updateProvider(provider.copyWith(coverPhotoUrl: url));
      },
    );
  }

  Future<void> _addGalleryImage(CykelProvider provider) async {
    if (provider.galleryUrls.length >= _maxGallery) return;
    final file = await _pick();
    if (file == null) return;
    await _upload(
      provider,
      action: () async {
        final url = await ref
            .read(providerServiceProvider)
            .uploadSingleImage(provider.userId, file);
        final updated = List<String>.from(provider.galleryUrls)..add(url);
        await ref
            .read(providerServiceProvider)
            .updateProvider(provider.copyWith(galleryUrls: updated));
      },
    );
  }

  Future<void> _removeGalleryImage(CykelProvider provider, int index) async {
    await _upload(
      provider,
      action: () async {
        final updated = List<String>.from(provider.galleryUrls)
          ..removeAt(index);
        await ref
            .read(providerServiceProvider)
            .updateProvider(provider.copyWith(galleryUrls: updated));
      },
    );
  }

  Future<void> _upload(
    CykelProvider provider, {
    required Future<void> Function() action,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.photosSaved),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.changesSaveError(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(myProviderProvider);
    final l10n = context.l10n;

    if (provider == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.managePhotosTitle)),
        body: Center(child: Text(l10n.noProviderFound)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.managePhotosTitle, style: AppTextStyles.headline3),
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // ── Logo ───────────────────────────────────────────────
                Text(l10n.currentLogo, style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                _PhotoCard(
                  url: provider.logoUrl,
                  placeholder: Icons.image_outlined,
                  aspectRatio: 1,
                  actionLabel: l10n.changeLogo,
                  onAction: () => _changeLogo(provider),
                ),
                const SizedBox(height: 24),

                // ── Cover ──────────────────────────────────────────────
                Text(l10n.currentCover, style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                _PhotoCard(
                  url: provider.coverPhotoUrl,
                  placeholder: Icons.photo_outlined,
                  aspectRatio: 16 / 9,
                  actionLabel: l10n.changeCover,
                  onAction: () => _changeCover(provider),
                ),
                const SizedBox(height: 24),

                // ── Gallery ────────────────────────────────────────────
                Row(
                  children: [
                    Text(l10n.currentGallery,
                        style: AppTextStyles.labelMedium),
                    const Spacer(),
                    Text(
                      '${provider.galleryUrls.length} / $_maxGallery',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (provider.galleryUrls.isEmpty)
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      l10n.analyticsNoData,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                if (provider.galleryUrls.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(provider.galleryUrls.length, (i) {
                      return _GalleryTile(
                        url: provider.galleryUrls[i],
                        onRemove: () =>
                            _removeGalleryImage(provider, i),
                      );
                    }),
                  ),
                const SizedBox(height: 12),
                if (provider.galleryUrls.length < _maxGallery)
                  OutlinedButton.icon(
                    onPressed: () => _addGalleryImage(provider),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(l10n.addPhotos),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─── Photo Card ─────────────────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.url,
    required this.placeholder,
    required this.aspectRatio,
    required this.actionLabel,
    required this.onAction,
  });

  final String? url;
  final IconData placeholder;
  final double aspectRatio;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: url != null
                ? Image.network(
                    url!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(placeholder,
                          size: 40, color: AppColors.textSecondary),
                    ),
                  )
                : Center(
                    child: Icon(placeholder,
                        size: 40, color: AppColors.textSecondary),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: Text(actionLabel),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }
}

// ─── Gallery Tile ───────────────────────────────────────────────────────────

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.url, required this.onRemove});
  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = (MediaQuery.sizeOf(context).width - 56) / 3;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filled(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 14),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.9),
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                minimumSize: const Size(24, 24),
                padding: EdgeInsets.zero,
              ),
              tooltip: l10n.removePhoto,
            ),
          ),
        ],
      ),
    );
  }
}
