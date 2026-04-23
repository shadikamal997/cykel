import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/offline_map.dart';
import 'offline_maps_provider.dart';

class LocalTileProvider implements TileProvider {
  const LocalTileProvider(this._service);

  final OfflineMapsService _service;

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) return TileProvider.noTile;
    final file = await _service.getCachedTile(x, y, zoom);
    if (file == null) return TileProvider.noTile;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return TileProvider.noTile;
    return Tile(256, 256, bytes);
  }
}

/// Streams true when the device has no internet (checked every 5 s).
final isOfflineProvider = StreamProvider<bool>((ref) async* {
  while (true) {
    try {
      final result = await InternetAddress.lookup('tile.openstreetmap.org')
          .timeout(const Duration(seconds: 3));
      yield result.isEmpty || result.first.rawAddress.isEmpty;
    } catch (_) {
      yield true;
    }
    await Future.delayed(const Duration(seconds: 5));
  }
});

/// True when at least one region has been fully downloaded.
final hasOfflineTilesProvider = Provider<bool>((ref) {
  final regions = ref.watch(offlineRegionsProvider);
  return regions.whenOrNull(
        data: (list) => list.any((r) => r.status == DownloadStatus.completed),
      ) ??
      false;
});
