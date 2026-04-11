/// CYKEL — Theft Alert Domain Models
/// Bike theft reporting and alert network

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── Theft Report Status ──────────────────────────────────────────────────────

enum TheftReportStatus {
  /// Active theft report
  active,
  /// Bike has been recovered
  recovered,
  /// Report expired/closed
  closed,
}

extension TheftReportStatusExt on TheftReportStatus {
  String get displayName {
    switch (this) {
      case TheftReportStatus.active:
        return 'Aktiv';
      case TheftReportStatus.recovered:
        return 'Fundet';
      case TheftReportStatus.closed:
        return 'Lukket';
    }
  }

  String get icon {
    switch (this) {
      case TheftReportStatus.active:
        return '🚨';
      case TheftReportStatus.recovered:
        return '✅';
      case TheftReportStatus.closed:
        return '❌';
    }
  }
}

// ─── Theft Report Model ───────────────────────────────────────────────────────

class TheftReport {
  const TheftReport({
    required this.id,
    required this.userId,
    required this.bikeId,
    required this.bikeName,
    required this.bikeDescription,
    required this.location,
    required this.reportedAt,
    required this.status,
    this.bikePhotoUrl,
    this.additionalNotes,
    this.contactInfo,
    this.lastSeenAt,
    this.frameNumber,
    this.cityArea,
    this.sightings = const [],
    this.recoveredAt,
  });

  final String id;
  final String userId;
  final String bikeId;
  final String bikeName;
  final String bikeDescription;
  final LatLng location;
  final DateTime reportedAt;
  final TheftReportStatus status;
  final String? bikePhotoUrl;
  final String? additionalNotes;
  final String? contactInfo;
  final DateTime? lastSeenAt;
  final String? frameNumber;
  final String? cityArea;
  final List<TheftSighting> sightings;
  final DateTime? recoveredAt;

  /// How many hours ago the theft was reported
  int get hoursAgo => DateTime.now().difference(reportedAt).inHours;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'bikeId': bikeId,
    'bikeName': bikeName,
    'bikeDescription': bikeDescription,
    'location': GeoPoint(location.latitude, location.longitude),
    'reportedAt': Timestamp.fromDate(reportedAt),
    'status': status.name,
    'bikePhotoUrl': bikePhotoUrl,
    'additionalNotes': additionalNotes,
    'contactInfo': contactInfo,
    'lastSeenAt': lastSeenAt != null ? Timestamp.fromDate(lastSeenAt!) : null,
    'frameNumber': frameNumber,
    'cityArea': cityArea,
    'recoveredAt': recoveredAt != null ? Timestamp.fromDate(recoveredAt!) : null,
  };

  factory TheftReport.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final geoPoint = data['location'] as GeoPoint;
    
    return TheftReport(
      id: doc.id,
      userId: data['userId'] as String,
      bikeId: data['bikeId'] as String,
      bikeName: data['bikeName'] as String,
      bikeDescription: data['bikeDescription'] as String,
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
      reportedAt: (data['reportedAt'] as Timestamp).toDate(),
      status: TheftReportStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TheftReportStatus.active,
      ),
      bikePhotoUrl: data['bikePhotoUrl'] as String?,
      additionalNotes: data['additionalNotes'] as String?,
      contactInfo: data['contactInfo'] as String?,
      lastSeenAt: (data['lastSeenAt'] as Timestamp?)?.toDate(),
      frameNumber: data['frameNumber'] as String?,
      cityArea: data['cityArea'] as String?,
      recoveredAt: (data['recoveredAt'] as Timestamp?)?.toDate(),
    );
  }

  TheftReport copyWith({
    TheftReportStatus? status,
    List<TheftSighting>? sightings,
    DateTime? recoveredAt,
  }) {
    return TheftReport(
      id: id,
      userId: userId,
      bikeId: bikeId,
      bikeName: bikeName,
      bikeDescription: bikeDescription,
      location: location,
      reportedAt: reportedAt,
      status: status ?? this.status,
      bikePhotoUrl: bikePhotoUrl,
      additionalNotes: additionalNotes,
      contactInfo: contactInfo,
      lastSeenAt: lastSeenAt,
      frameNumber: frameNumber,
      cityArea: cityArea,
      sightings: sightings ?? this.sightings,
      recoveredAt: recoveredAt ?? this.recoveredAt,
    );
  }
}

// ─── Theft Sighting Model ─────────────────────────────────────────────────────

class TheftSighting {
  const TheftSighting({
    required this.id,
    required this.reportId,
    required this.reporterId,
    required this.location,
    required this.reportedAt,
    this.notes,
    this.photoUrl,
  });

  final String id;
  final String reportId;
  final String reporterId;
  final LatLng location;
  final DateTime reportedAt;
  final String? notes;
  final String? photoUrl;

  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'reporterId': reporterId,
    'location': GeoPoint(location.latitude, location.longitude),
    'reportedAt': Timestamp.fromDate(reportedAt),
    'notes': notes,
    'photoUrl': photoUrl,
  };

  factory TheftSighting.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final geoPoint = data['location'] as GeoPoint;
    
    return TheftSighting(
      id: doc.id,
      reportId: data['reportId'] as String,
      reporterId: data['reporterId'] as String,
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
      reportedAt: (data['reportedAt'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }
}

// ─── Theft Alert Settings ─────────────────────────────────────────────────────

class TheftAlertSettings {
  const TheftAlertSettings({
    this.enabled = true,
    this.radiusKm = 5.0,
    this.notifyNewThefts = true,
    this.notifySightings = true,
    this.notifyRecoveries = true,
  });

  final bool enabled;
  final double radiusKm;
  final bool notifyNewThefts;
  final bool notifySightings;
  final bool notifyRecoveries;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'radiusKm': radiusKm,
    'notifyNewThefts': notifyNewThefts,
    'notifySightings': notifySightings,
    'notifyRecoveries': notifyRecoveries,
  };

  factory TheftAlertSettings.fromJson(Map<String, dynamic>? data) {
    if (data == null) return const TheftAlertSettings();
    return TheftAlertSettings(
      enabled: data['enabled'] as bool? ?? true,
      radiusKm: (data['radiusKm'] as num?)?.toDouble() ?? 5.0,
      notifyNewThefts: data['notifyNewThefts'] as bool? ?? true,
      notifySightings: data['notifySightings'] as bool? ?? true,
      notifyRecoveries: data['notifyRecoveries'] as bool? ?? true,
    );
  }

  TheftAlertSettings copyWith({
    bool? enabled,
    double? radiusKm,
    bool? notifyNewThefts,
    bool? notifySightings,
    bool? notifyRecoveries,
  }) {
    return TheftAlertSettings(
      enabled: enabled ?? this.enabled,
      radiusKm: radiusKm ?? this.radiusKm,
      notifyNewThefts: notifyNewThefts ?? this.notifyNewThefts,
      notifySightings: notifySightings ?? this.notifySightings,
      notifyRecoveries: notifyRecoveries ?? this.notifyRecoveries,
    );
  }
}
