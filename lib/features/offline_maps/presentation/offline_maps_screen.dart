/// CYKEL — Offline Maps Screen
/// Download and manage offline map regions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/subscription_providers.dart';
import '../data/offline_maps_provider.dart';
import '../domain/offline_map.dart';

class OfflineMapsScreen extends ConsumerStatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  ConsumerState<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends ConsumerState<OfflineMapsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!ref.watch(isPremiumProvider)) {
      return PremiumGateScreen(
        screenTitle: l10n.offlineMapsTitle,
        featureDescription: 'Download maps to your device and navigate without an internet connection.',
        child: const SizedBox.shrink(),
      );
    }

    final regionsAsync = ref.watch(offlineRegionsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(l10n.offlineMapsTitle),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Storage info card
          SliverToBoxAdapter(
            child: _StorageInfoCard(),
          ),

          // Downloaded regions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                l10n.downloadedRegions,
                style: AppTextStyles.headline3,
              ),
            ),
          ),

          regionsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('${l10n.errorPrefix}: $e')),
            ),
            data: (regions) {
              if (regions.isEmpty) {
                return const SliverToBoxAdapter(
                  child: _EmptyRegionsCard(),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _RegionCard(
                    region: regions[index],
                    onDelete: () => _deleteRegion(regions[index]),
                    onPause: () => _pauseDownload(regions[index]),
                    onResume: () => _resumeDownload(regions[index]),
                  ),
                  childCount: regions.length,
                ),
              );
            },
          ),

          // Predefined regions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                l10n.availableRegions,
                style: AppTextStyles.headline3,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.downloadMapsForOfflineNav,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PredefinedRegionCard(
                region: predefinedRegions[index],
                onDownload: () => _downloadPredefined(predefinedRegions[index]),
              ),
              childCount: predefinedRegions.length,
            ),
          ),

          // Custom region button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _showCustomRegionPicker(context),
                icon: const Icon(Icons.add_location_alt),
                label: Text(l10n.downloadCustomRegion),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _OfflineSettingsSheet(),
    );
  }

  Future<void> _deleteRegion(MapRegion region) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteOfflineMaps),
        content: Text(l10n.confirmDeleteRegion(region.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(offlineMapsServiceProvider).deleteRegion(region.id);
    }
  }

  Future<void> _pauseDownload(MapRegion region) async {
    await ref.read(offlineMapsServiceProvider).pauseDownload(region.id);
  }

  Future<void> _resumeDownload(MapRegion region) async {
    await ref.read(offlineMapsServiceProvider).resumeDownload(region.id);
  }

  Future<void> _downloadPredefined(PredefinedRegion region) async {
    final l10n = AppLocalizations.of(context);
    await ref.read(offlineMapsServiceProvider).downloadPredefinedRegion(region);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.startingDownload(region.name))),
      );
    }
  }

  void _showCustomRegionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CustomRegionPicker(),
    );
  }
}

// ─── Storage Info Card ────────────────────────────────────────────────────────

class _StorageInfoCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(offlineSettingsProvider);
    final usedAsync = ref.watch(offlineStorageUsedProvider);

    final settings = settingsAsync.valueOrNull ?? const OfflineSettings();
    final used = usedAsync.valueOrNull ?? 0;
    final maxBytes = settings.maxStorageMB * 1024 * 1024;
    final progress = maxBytes > 0 ? used / maxBytes : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: context.colors.textPrimary),
              const SizedBox(width: 8),
              Text(l10n.storage, style: AppTextStyles.headline3),
            ],
          ),
          const SizedBox(height: 12),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.colors.border,
              valueColor: AlwaysStoppedAnimation(
                context.colors.textPrimary.withValues(alpha: progress > 0.9 ? 1.0 : 0.7),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatBytes(used),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${settings.maxStorageMB} MB',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─── Empty Regions Card ───────────────────────────────────────────────────────

class _EmptyRegionsCard extends StatelessWidget {
  const _EmptyRegionsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          const Text('📍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            l10n.noDownloadedMaps,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.downloadMapsToUseOffline,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Region Card ──────────────────────────────────────────────────────────────

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.region,
    required this.onDelete,
    required this.onPause,
    required this.onResume,
  });

  final MapRegion region;
  final VoidCallback onDelete;
  final VoidCallback onPause;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _statusColor(context, region.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  region.status.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(region.name, style: AppTextStyles.bodyMedium),
            subtitle: Text(
              _getSubtitle(l10n),
              style: AppTextStyles.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            trailing: _buildTrailingButton(),
          ),

          if (region.status == DownloadStatus.downloading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: region.progress,
                      backgroundColor: context.colors.border,
                      valueColor: AlwaysStoppedAnimation(context.colors.textPrimary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(region.progress * 100).toInt()}% - ${region.downloadedTiles}/${region.tileCount} tiles',
                    style: AppTextStyles.caption.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getSubtitle(AppLocalizations l10n) {
    switch (region.status) {
      case DownloadStatus.completed:
        return '${region.sizeFormatted} • ${l10n.downloaded} ${_formatDate(region.downloadedAt)}';
      case DownloadStatus.downloading:
        return l10n.downloading;
      case DownloadStatus.paused:
        return l10n.percentDownloaded((region.progress * 100).toInt());
      case DownloadStatus.failed:
        return region.error ?? l10n.downloadError;
      case DownloadStatus.pending:
        return l10n.pending;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _statusColor(BuildContext context, DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return context.colors.textPrimary;
      case DownloadStatus.downloading:
        return context.colors.textPrimary.withValues(alpha: 0.9);
      case DownloadStatus.paused:
        return context.colors.textPrimary.withValues(alpha: 0.6);
      case DownloadStatus.failed:
        return context.colors.textPrimary.withValues(alpha: 0.5);
      case DownloadStatus.pending:
        return context.colors.textSecondary;
    }
  }

  Widget? _buildTrailingButton() {
    switch (region.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.pause),
          onPressed: onPause,
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: onResume,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onResume,
        );
      default:
        return null;
    }
  }
}

// ─── Predefined Region Card ───────────────────────────────────────────────────

class _PredefinedRegionCard extends StatelessWidget {
  const _PredefinedRegionCard({
    required this.region,
    required this.onDownload,
  });

  final PredefinedRegion region;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.colors.textPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(Icons.map_outlined, color: context.colors.textPrimary),
          ),
        ),
        title: Text(region.name, style: AppTextStyles.bodyMedium),
        subtitle: Text(
          '${region.description} • ~${region.estimatedSizeMB} MB',
          style: AppTextStyles.caption.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        trailing: IconButton.filled(
          onPressed: onDownload,
          icon: const Icon(Icons.download, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: context.colors.textPrimary,
            foregroundColor: context.colors.background,
          ),
        ),
      ),
    );
  }
}

// ─── Custom Region Picker ─────────────────────────────────────────────────────

class _CustomRegionPicker extends ConsumerStatefulWidget {
  const _CustomRegionPicker();

  @override
  ConsumerState<_CustomRegionPicker> createState() => _CustomRegionPickerState();
}

class _CustomRegionPickerState extends ConsumerState<_CustomRegionPicker> {
  final _nameController = TextEditingController();
  GoogleMapController? _mapController;
  LatLngBounds? _selectedBounds;

  // Default to Copenhagen
  static const _initialPosition = CameraPosition(
    target: LatLng(55.6761, 12.5683),
    zoom: 11,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(l10n.selectRegion, style: AppTextStyles.headline3),
              const SizedBox(height: 8),
              Text(
                l10n.selectRegionOnMap,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Name input
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.regionName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Map
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: _initialPosition,
                    onMapCreated: (controller) => _mapController = controller,
                    onCameraIdle: _onCameraIdle,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Download button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedBounds == null ? null : _download,
                  icon: const Icon(Icons.download),
                  label: Text(l10n.downloadRegion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.textPrimary,
                    foregroundColor: context.colors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onCameraIdle() async {
    if (_mapController == null) return;
    final bounds = await _mapController!.getVisibleRegion();
    setState(() => _selectedBounds = bounds);
  }

  Future<void> _download() async {
    if (_selectedBounds == null) return;

    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterRegionName)),
      );
      return;
    }

    await ref.read(offlineMapsServiceProvider).downloadRegion(
      name: name,
      bounds: _selectedBounds!,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.startingDownload(name))),
      );
    }
  }
}

// ─── Settings Sheet ───────────────────────────────────────────────────────────

class _OfflineSettingsSheet extends ConsumerWidget {
  const _OfflineSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(offlineSettingsProvider);
    final settings = settingsAsync.valueOrNull ?? const OfflineSettings();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(l10n.offlineSettings, style: AppTextStyles.headline3),
          const SizedBox(height: 24),

          SwitchListTile(
            title: Text(l10n.autoDownloadOnWifi),
            subtitle: Text(l10n.autoDownloadOnWifiDesc),
            value: settings.autoDownloadOnWifi,
            onChanged: (value) => _updateSettings(
              ref, 
              settings.copyWith(autoDownloadOnWifi: value),
            ),
          ),

          SwitchListTile(
            title: Text(l10n.downloadRouteBuffer),
            subtitle: Text(l10n.downloadRouteBufferDesc),
            value: settings.downloadRouteBuffer,
            onChanged: (value) => _updateSettings(
              ref, 
              settings.copyWith(downloadRouteBuffer: value),
            ),
          ),

          ListTile(
            title: Text(l10n.maxStorage),
            subtitle: Text('${settings.maxStorageMB} MB'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.maxStorageMB.toDouble(),
                min: 100,
                max: 2000,
                divisions: 19,
                onChanged: (value) => _updateSettings(
                  ref,
                  settings.copyWith(maxStorageMB: value.toInt()),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Clear all button
          Center(
            child: TextButton.icon(
              onPressed: () => _clearAll(context, ref),
              icon: Icon(Icons.delete_sweep, color: context.colors.textPrimary),
              label: Text(
                l10n.deleteAllOfflineMaps,
                style: TextStyle(color: context.colors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSettings(WidgetRef ref, OfflineSettings settings) async {
    await ref.read(offlineMapsServiceProvider).updateSettings(settings);
    ref.invalidate(offlineSettingsProvider);
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteAllOfflineMapsConfirm),
        content: Text(l10n.deleteAllOfflineMapsDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(offlineMapsServiceProvider);
      final regions = service.getRegions();
      for (final region in regions) {
        await service.deleteRegion(region.id);
      }
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.allOfflineMapsDeleted)),
        );
      }
    }
  }
}
