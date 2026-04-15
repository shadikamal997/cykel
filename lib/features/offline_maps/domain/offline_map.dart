/// CYKEL — Offline Maps Domain Models
/// Downloaded map regions for offline navigation

import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── Download Status ──────────────────────────────────────────────────────────

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed;

  String get displayName {
    switch (this) {
      case DownloadStatus.pending:
        return 'Afventer';
      case DownloadStatus.downloading:
        return 'Downloader';
      case DownloadStatus.paused:
        return 'Sat på pause';
      case DownloadStatus.completed:
        return 'Downloadet';
      case DownloadStatus.failed:
        return 'Fejlet';
    }
  }

  String get icon {
    switch (this) {
      case DownloadStatus.pending:
        return '⏳';
      case DownloadStatus.downloading:
        return '📥';
      case DownloadStatus.paused:
        return '⏸️';
      case DownloadStatus.completed:
        return '✅';
      case DownloadStatus.failed:
        return '❌';
    }
  }
}

// ─── Map Region ───────────────────────────────────────────────────────────────

class MapRegion {
  const MapRegion({
    required this.id,
    required this.name,
    required this.bounds,
    required this.zoomLevels,
    required this.status,
    this.downloadedAt,
    this.sizeBytes = 0,
    this.progress = 0,
    this.tileCount = 0,
    this.downloadedTiles = 0,
    this.error,
  });

  final String id;
  final String name;
  final LatLngBounds bounds;
  final List<int> zoomLevels; // e.g., [12, 13, 14, 15, 16]
  final DownloadStatus status;
  final DateTime? downloadedAt;
  final int sizeBytes;
  final double progress; // 0.0 - 1.0
  final int tileCount;
  final int downloadedTiles;
  final String? error;

  LatLng get center => LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bounds': {
          'northeast': {
            'lat': bounds.northeast.latitude,
            'lng': bounds.northeast.longitude,
          },
          'southwest': {
            'lat': bounds.southwest.latitude,
            'lng': bounds.southwest.longitude,
          },
        },
        'zoomLevels': zoomLevels,
        'status': status.name,
        'downloadedAt': downloadedAt?.toIso8601String(),
        'sizeBytes': sizeBytes,
        'progress': progress,
        'tileCount': tileCount,
        'downloadedTiles': downloadedTiles,
        'error': error,
      };

  factory MapRegion.fromJson(Map<String, dynamic> json) {
    final boundsJson = json['bounds'] as Map<String, dynamic>;
    final ne = boundsJson['northeast'] as Map<String, dynamic>;
    final sw = boundsJson['southwest'] as Map<String, dynamic>;

    return MapRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      bounds: LatLngBounds(
        northeast: LatLng((ne['lat'] as num).toDouble(), (ne['lng'] as num).toDouble()),
        southwest: LatLng((sw['lat'] as num).toDouble(), (sw['lng'] as num).toDouble()),
      ),
      zoomLevels: List<int>.from(json['zoomLevels'] as List),
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.pending,
      ),
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : null,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      tileCount: json['tileCount'] as int? ?? 0,
      downloadedTiles: json['downloadedTiles'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }

  MapRegion copyWith({
    String? id,
    String? name,
    LatLngBounds? bounds,
    List<int>? zoomLevels,
    DownloadStatus? status,
    DateTime? downloadedAt,
    int? sizeBytes,
    double? progress,
    int? tileCount,
    int? downloadedTiles,
    String? error,
  }) {
    return MapRegion(
      id: id ?? this.id,
      name: name ?? this.name,
      bounds: bounds ?? this.bounds,
      zoomLevels: zoomLevels ?? this.zoomLevels,
      status: status ?? this.status,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      progress: progress ?? this.progress,
      tileCount: tileCount ?? this.tileCount,
      downloadedTiles: downloadedTiles ?? this.downloadedTiles,
      error: error,
    );
  }
}

// ─── Offline Settings ─────────────────────────────────────────────────────────

class OfflineSettings {
  const OfflineSettings({
    this.autoDownloadOnWifi = false,
    this.maxStorageMB = 500,
    this.defaultZoomLevels = const [12, 13, 14, 15],
    this.downloadRouteBuffer = true,
    this.routeBufferKm = 1.0,
  });

  final bool autoDownloadOnWifi;
  final int maxStorageMB;
  final List<int> defaultZoomLevels;
  final bool downloadRouteBuffer;
  final double routeBufferKm;

  Map<String, dynamic> toJson() => {
        'autoDownloadOnWifi': autoDownloadOnWifi,
        'maxStorageMB': maxStorageMB,
        'defaultZoomLevels': defaultZoomLevels,
        'downloadRouteBuffer': downloadRouteBuffer,
        'routeBufferKm': routeBufferKm,
      };

  factory OfflineSettings.fromJson(Map<String, dynamic> json) {
    return OfflineSettings(
      autoDownloadOnWifi: json['autoDownloadOnWifi'] as bool? ?? false,
      maxStorageMB: json['maxStorageMB'] as int? ?? 500,
      defaultZoomLevels: List<int>.from(json['defaultZoomLevels'] as List? ?? [12, 13, 14, 15]),
      downloadRouteBuffer: json['downloadRouteBuffer'] as bool? ?? true,
      routeBufferKm: (json['routeBufferKm'] as num?)?.toDouble() ?? 1.0,
    );
  }

  OfflineSettings copyWith({
    bool? autoDownloadOnWifi,
    int? maxStorageMB,
    List<int>? defaultZoomLevels,
    bool? downloadRouteBuffer,
    double? routeBufferKm,
  }) {
    return OfflineSettings(
      autoDownloadOnWifi: autoDownloadOnWifi ?? this.autoDownloadOnWifi,
      maxStorageMB: maxStorageMB ?? this.maxStorageMB,
      defaultZoomLevels: defaultZoomLevels ?? this.defaultZoomLevels,
      downloadRouteBuffer: downloadRouteBuffer ?? this.downloadRouteBuffer,
      routeBufferKm: routeBufferKm ?? this.routeBufferKm,
    );
  }
}

// ─── Predefined Regions ───────────────────────────────────────────────────────

class PredefinedRegion {
  const PredefinedRegion({
    required this.id,
    required this.name,
    required this.bounds,
    required this.estimatedSizeMB,
    required this.description,
    this.subRegions = const [],
  });

  final String id;
  final String name;
  final LatLngBounds bounds;
  final int estimatedSizeMB;
  final String description;
  final List<PredefinedRegion> subRegions;
}

// Denmark and major cities
final predefinedRegions = [
  PredefinedRegion(
    id: 'copenhagen',
    name: 'København',
    bounds: LatLngBounds(
      northeast: const LatLng(55.7500, 12.6500),
      southwest: const LatLng(55.6000, 12.4500),
    ),
    estimatedSizeMB: 85,
    description: 'Hele København inkl. Frederiksberg',
  ),
  PredefinedRegion(
    id: 'aarhus',
    name: 'Aarhus',
    bounds: LatLngBounds(
      northeast: const LatLng(56.2000, 10.2500),
      southwest: const LatLng(56.1000, 10.1000),
    ),
    estimatedSizeMB: 45,
    description: 'Aarhus by',
  ),
  PredefinedRegion(
    id: 'odense',
    name: 'Odense',
    bounds: LatLngBounds(
      northeast: const LatLng(55.4500, 10.4500),
      southwest: const LatLng(55.3500, 10.3000),
    ),
    estimatedSizeMB: 35,
    description: 'Odense by',
  ),
  PredefinedRegion(
    id: 'aalborg',
    name: 'Aalborg',
    bounds: LatLngBounds(
      northeast: const LatLng(57.0800, 10.0000),
      southwest: const LatLng(56.9800, 9.8500),
    ),
    estimatedSizeMB: 30,
    description: 'Aalborg by',
  ),
  PredefinedRegion(
    id: 'denmark_all',
    name: 'Hele Danmark',
    bounds: LatLngBounds(
      northeast: const LatLng(57.7500, 15.2000),
      southwest: const LatLng(54.5000, 8.0000),
    ),
    estimatedSizeMB: 950,
    description: 'Alle danske regioner',
  ),
];
