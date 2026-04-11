/// CYKEL — Offline Maps Service
/// Download and manage offline map tiles

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/offline_map.dart';

// ─── Offline Maps Service ─────────────────────────────────────────────────────

class OfflineMapsService {
  OfflineMapsService();

  static const _regionsKey = 'offline_map_regions';
  static const _settingsKey = 'offline_map_settings';
  
  final _regionsController = StreamController<List<MapRegion>>.broadcast();
  final _downloadProgressController = StreamController<MapRegion>.broadcast();
  
  List<MapRegion> _regions = [];
  bool _isDownloading = false;
  String? _currentDownloadId;

  Stream<List<MapRegion>> get regionsStream => _regionsController.stream;
  Stream<MapRegion> get downloadProgressStream => _downloadProgressController.stream;

  // ─── Initialize ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final regionsJson = prefs.getString(_regionsKey);
    
    if (regionsJson != null) {
      final list = jsonDecode(regionsJson) as List;
      _regions = list.map((e) => MapRegion.fromJson(e as Map<String, dynamic>)).toList();
      _regionsController.add(_regions);
    }
  }

  // ─── Get Regions ────────────────────────────────────────────────────────────

  List<MapRegion> getRegions() => List.unmodifiable(_regions);

  Future<MapRegion?> getRegion(String id) async {
    return _regions.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Region not found'),
    );
  }

  // ─── Download Region ────────────────────────────────────────────────────────

  Future<void> downloadRegion({
    required String name,
    required LatLngBounds bounds,
    List<int>? zoomLevels,
  }) async {
    final settings = await getSettings();
    final levels = zoomLevels ?? settings.defaultZoomLevels;
    
    // Calculate tile count
    final tileCount = _calculateTileCount(bounds, levels);
    final estimatedSize = tileCount * 15000; // ~15KB per tile average

    final region = MapRegion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      bounds: bounds,
      zoomLevels: levels,
      status: DownloadStatus.pending,
      tileCount: tileCount,
      sizeBytes: estimatedSize,
    );

    _regions.add(region);
    await _saveRegions();
    _regionsController.add(_regions);

    // Start download
    await _startDownload(region);
  }

  Future<void> downloadPredefinedRegion(PredefinedRegion predefined) async {
    await downloadRegion(
      name: predefined.name,
      bounds: predefined.bounds,
    );
  }

  Future<void> _startDownload(MapRegion region) async {
    if (_isDownloading) {
      // Queue the download
      return;
    }

    _isDownloading = true;
    _currentDownloadId = region.id;

    // Update status to downloading
    _updateRegion(region.id, (r) => r.copyWith(status: DownloadStatus.downloading));

    try {
      final dir = await _getMapTilesDirectory();
      final regionDir = Directory('${dir.path}/${region.id}');
      await regionDir.create(recursive: true);

      int downloadedTiles = 0;
      int totalSize = 0;

      // Generate all tile coordinates
      final tiles = _generateTileCoordinates(region.bounds, region.zoomLevels);

      for (final tile in tiles) {
        if (_currentDownloadId != region.id) {
          // Download was paused or cancelled
          break;
        }

        // Simulate tile download (in real app, would download from tile server)
        // For demo purposes, we create placeholder files
        final tileFile = File('${regionDir.path}/${tile.z}_${tile.x}_${tile.y}.png');
        
        // In production, you'd download from a tile server like:
        // https://tile.openstreetmap.org/{z}/{x}/{y}.png
        // But for this demo, we simulate the download
        await Future.delayed(const Duration(milliseconds: 10)); // Simulate network delay
        
        // Create empty placeholder (in real app, write actual tile data)
        if (!await tileFile.exists()) {
          await tileFile.writeAsBytes([]);
        }

        downloadedTiles++;
        totalSize += 15000; // Simulated ~15KB per tile

        final progress = downloadedTiles / region.tileCount;
        _updateRegion(region.id, (r) => r.copyWith(
          progress: progress,
          downloadedTiles: downloadedTiles,
          sizeBytes: totalSize,
        ));

        // Emit progress
        final updated = _regions.firstWhere((r) => r.id == region.id);
        _downloadProgressController.add(updated);
      }

      // Mark as completed
      _updateRegion(region.id, (r) => r.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedAt: DateTime.now(),
      ));

    } catch (e) {
      _updateRegion(region.id, (r) => r.copyWith(
        status: DownloadStatus.failed,
        error: e.toString(),
      ));
    } finally {
      _isDownloading = false;
      _currentDownloadId = null;
    }
  }

  // ─── Pause/Resume/Delete ────────────────────────────────────────────────────

  Future<void> pauseDownload(String regionId) async {
    if (_currentDownloadId == regionId) {
      _currentDownloadId = null;
      _updateRegion(regionId, (r) => r.copyWith(status: DownloadStatus.paused));
    }
  }

  Future<void> resumeDownload(String regionId) async {
    final region = _regions.firstWhere((r) => r.id == regionId);
    if (region.status == DownloadStatus.paused) {
      await _startDownload(region);
    }
  }

  Future<void> deleteRegion(String regionId) async {
    // Stop if currently downloading
    if (_currentDownloadId == regionId) {
      _currentDownloadId = null;
      _isDownloading = false;
    }

    // Delete files
    final dir = await _getMapTilesDirectory();
    final regionDir = Directory('${dir.path}/$regionId');
    if (await regionDir.exists()) {
      await regionDir.delete(recursive: true);
    }

    // Remove from list
    _regions.removeWhere((r) => r.id == regionId);
    await _saveRegions();
    _regionsController.add(_regions);
  }

  // ─── Settings ───────────────────────────────────────────────────────────────

  Future<OfflineSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_settingsKey);
    if (json == null) return const OfflineSettings();
    return OfflineSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> updateSettings(OfflineSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  // ─── Storage Info ───────────────────────────────────────────────────────────

  Future<int> getTotalStorageUsed() async {
    int total = 0;
    for (final region in _regions) {
      if (region.status == DownloadStatus.completed) {
        total += region.sizeBytes;
      }
    }
    return total;
  }

  Future<int> getAvailableStorage() async {
    final settings = await getSettings();
    final used = await getTotalStorageUsed();
    return (settings.maxStorageMB * 1024 * 1024) - used;
  }

  // ─── Check if Tile is Cached ────────────────────────────────────────────────

  Future<bool> isTileCached(int x, int y, int z) async {
    final dir = await _getMapTilesDirectory();
    
    for (final region in _regions) {
      if (region.status != DownloadStatus.completed) continue;
      if (!region.zoomLevels.contains(z)) continue;

      final tileFile = File('${dir.path}/${region.id}/${z}_${x}_$y.png');
      if (await tileFile.exists()) {
        return true;
      }
    }
    return false;
  }

  Future<File?> getCachedTile(int x, int y, int z) async {
    final dir = await _getMapTilesDirectory();
    
    for (final region in _regions) {
      if (region.status != DownloadStatus.completed) continue;
      if (!region.zoomLevels.contains(z)) continue;

      final tileFile = File('${dir.path}/${region.id}/${z}_${x}_$y.png');
      if (await tileFile.exists()) {
        return tileFile;
      }
    }
    return null;
  }

  // ─── Helper Methods ─────────────────────────────────────────────────────────

  Future<Directory> _getMapTilesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tilesDir = Directory('${appDir.path}/map_tiles');
    if (!await tilesDir.exists()) {
      await tilesDir.create(recursive: true);
    }
    return tilesDir;
  }

  Future<void> _saveRegions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_regions.map((r) => r.toJson()).toList());
    await prefs.setString(_regionsKey, json);
  }

  void _updateRegion(String id, MapRegion Function(MapRegion) update) {
    final index = _regions.indexWhere((r) => r.id == id);
    if (index != -1) {
      _regions[index] = update(_regions[index]);
      _saveRegions();
      _regionsController.add(_regions);
    }
  }

  int _calculateTileCount(LatLngBounds bounds, List<int> zoomLevels) {
    int count = 0;
    for (final z in zoomLevels) {
      final tiles = _generateTileCoordinates(bounds, [z]);
      count += tiles.length;
    }
    return count;
  }

  List<_TileCoord> _generateTileCoordinates(LatLngBounds bounds, List<int> zoomLevels) {
    final tiles = <_TileCoord>[];
    
    for (final z in zoomLevels) {
      final minTile = _latLngToTile(bounds.southwest, z);
      final maxTile = _latLngToTile(bounds.northeast, z);

      for (int x = minTile.x; x <= maxTile.x; x++) {
        for (int y = maxTile.y; y <= minTile.y; y++) {
          tiles.add(_TileCoord(x, y, z));
        }
      }
    }
    
    return tiles;
  }

  _TileCoord _latLngToTile(LatLng latLng, int zoom) {
    final n = math.pow(2, zoom).toInt();
    final x = ((latLng.longitude + 180) / 360 * n).floor();
    final latRad = latLng.latitude * math.pi / 180;
    final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor();
    return _TileCoord(x, y, zoom);
  }

  void dispose() {
    _regionsController.close();
    _downloadProgressController.close();
  }
}

class _TileCoord {
  const _TileCoord(this.x, this.y, this.z);
  final int x;
  final int y;
  final int z;
}

// ─── Providers ────────────────────────────────────────────────────────────────

final offlineMapsServiceProvider = Provider<OfflineMapsService>((ref) {
  final service = OfflineMapsService();
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream of downloaded regions
final offlineRegionsProvider = StreamProvider<List<MapRegion>>((ref) {
  final service = ref.watch(offlineMapsServiceProvider);
  // Initial emit
  Future.microtask(() {
    final regions = service.getRegions();
    if (regions.isNotEmpty) {
      // Will be updated via stream
    }
  });
  return service.regionsStream;
});

/// Download progress for active downloads
final downloadProgressProvider = StreamProvider<MapRegion>((ref) {
  return ref.watch(offlineMapsServiceProvider).downloadProgressStream;
});

/// Offline settings
final offlineSettingsProvider = FutureProvider<OfflineSettings>((ref) async {
  return ref.watch(offlineMapsServiceProvider).getSettings();
});

/// Total storage used
final offlineStorageUsedProvider = FutureProvider<int>((ref) async {
  return ref.watch(offlineMapsServiceProvider).getTotalStorageUsed();
});
