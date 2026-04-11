/// CYKEL — Infrastructure Feedback domain model (Phase 4)
///
/// Riders can report cycling-infrastructure issues to municipal authorities
/// (or just inform other riders). Reports are stored in `infrastructure_reports`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'crowd_hazard.dart' show ReportStatus, ReportStatusX;

enum InfrastructureIssueType {
  missingLane,       // No cycle lane on this road
  brokenPavement,    // Cracked / sunken paving
  poorLighting,      // Dangerous at night
  lackingSignage,    // Missing cycling signs / directions
  blockedLane,       // Parked cars / obstacles in cycle lane
  missingRamp,       // No kerb ramp / dropped kerb
  other,
}

class InfrastructureReport {
  const InfrastructureReport({
    required this.id,
    required this.type,
    required this.lat,
    required this.lng,
    required this.reportedBy,
    required this.reportedAt,
    this.description = '',
    this.status = ReportStatus.reported,
  });

  final String                id;
  final InfrastructureIssueType type;
  final double                lat;
  final double                lng;
  final String                reportedBy;
  final DateTime              reportedAt;
  final String                description;
  final ReportStatus          status;

  LatLng get position => LatLng(lat, lng);

  Map<String, dynamic> toFirestore() => {
        'type':        type.name,
        'lat':         lat,
        'lng':         lng,
        'reportedBy':  reportedBy,
        'reportedAt':  Timestamp.fromDate(reportedAt),
        'description': description,
        'status':      status.name,
      };

  /// Integration-ready export format for city API / open data consumption.
  Map<String, dynamic> toApiJson() => {
        'id':          id,
        'source':      'cykel_infrastructure_report',
        'category':    'infrastructure',
        'subtype':     type.name,
        'status':      status.name,
        'description': description,
        'location': {
          'lat': lat,
          'lng': lng,
        },
        'timestamps': {
          'reported': reportedAt.toIso8601String(),
        },
      };

  factory InfrastructureReport.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return InfrastructureReport(
      id:          doc.id,
      type:        InfrastructureIssueType.values.firstWhere(
                     (e) => e.name == (m['type'] as String? ?? ''),
                     orElse: () => InfrastructureIssueType.other),
      lat:         (m['lat'] as num).toDouble(),
      lng:         (m['lng'] as num).toDouble(),
      reportedBy:  m['reportedBy'] as String? ?? '',
      reportedAt:  (m['reportedAt'] as Timestamp).toDate(),
      description: m['description'] as String? ?? '',
      status:      ReportStatusX.fromString(m['status'] as String?),
    );
  }
}
