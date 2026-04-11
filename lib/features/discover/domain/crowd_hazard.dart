/// CYKEL — Crowd-reported hazard domain model.
///
/// Users can report road conditions during navigation.
/// Reports expire after [kCrowdHazardTtlHours] hours to stay relevant.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const kCrowdHazardTtlHours = 8;

// ── Report Status lifecycle ───────────────────────────────────────────────────

/// Full lifecycle a crowd-sourced hazard goes through.
///
/// Municipalities or automated rules can advance the status.
/// Citizens see this so reports never feel like they vanish.
enum ReportStatus {
  /// Freshly reported, not yet verified by other users.
  reported,

  /// Two or more other riders have confirmed the hazard is still present.
  confirmed,

  /// A municipal admin has acknowledged the report and flagged it for review.
  underReview,

  /// The hazard has been cleared — either by dismissals or admin action.
  resolved,
}

extension ReportStatusX on ReportStatus {
  /// Human-readable label shown in UI badges.
  String label(BuildContext context) => switch (this) {
        ReportStatus.reported    => context.l10n.statusReported,
        ReportStatus.confirmed   => context.l10n.statusConfirmed,
        ReportStatus.underReview => context.l10n.statusUnderReview,
        ReportStatus.resolved    => context.l10n.statusResolved,
      };

  Color get color => switch (this) {
        ReportStatus.reported    => const Color(0xFF9E9E9E), // grey
        ReportStatus.confirmed   => const Color(0xFFFF9800), // amber
        ReportStatus.underReview => const Color(0xFF2196F3), // blue
        ReportStatus.resolved    => const Color(0xFF4CAF50), // green
      };

  IconData get icon => switch (this) {
        ReportStatus.reported    => Icons.flag_outlined,
        ReportStatus.confirmed   => Icons.check_circle_outline,
        ReportStatus.underReview => Icons.policy_outlined,
        ReportStatus.resolved    => Icons.task_alt_rounded,
      };

  static ReportStatus fromString(String? s) => switch (s) {
        'confirmed'   => ReportStatus.confirmed,
        'underReview' => ReportStatus.underReview,
        'resolved'    => ReportStatus.resolved,
        _             => ReportStatus.reported,
      };
}

enum CrowdHazardType {
  roadDamage,   // potholes / broken tarmac
  accident,     // active accident / debris from collision
  debris,       // glass, gravel, leaves
  roadClosed,   // blocked / construction
  badSurface,   // slippery / unpaved section
  flooding,     // standing water
}

/// Three-tier severity that riders assign when submitting a hazard.
enum HazardSeverity {
  /// FYI – minor nuisance; safe to continue.
  info,

  /// Caution advised – slow down.
  caution,

  /// Danger – hazard poses real risk; avoid if possible.
  danger,
}

extension HazardSeverityX on HazardSeverity {
  Color get color => switch (this) {
        HazardSeverity.info    => const Color(0xFF2196F3), // blue
        HazardSeverity.caution => const Color(0xFFFF9800), // amber
        HazardSeverity.danger  => const Color(0xFFF44336), // red
      };

  String label(BuildContext context) => switch (this) {
        HazardSeverity.info    => context.l10n.severityInfo,
        HazardSeverity.caution => context.l10n.severityCaution,
        HazardSeverity.danger  => context.l10n.severityDanger,
      };
}

class CrowdHazardReport {
  CrowdHazardReport({
    required this.id,
    required this.type,
    required this.lat,
    required this.lng,
    required this.reportedBy,
    required this.reportedAt,
    this.upvotes = 0,
    this.severity = HazardSeverity.caution,
    this.confirmCount = 0,
    this.dismissCount = 0,
    this.status = ReportStatus.reported,
    DateTime? expiresAt,
  }) : expiresAt = expiresAt ?? _defaultExpiry(reportedAt);

  final String          id;
  final CrowdHazardType type;
  final double          lat;
  final double          lng;
  final String          reportedBy;
  final DateTime        reportedAt;
  final int             upvotes;
  final HazardSeverity  severity;
  final int             confirmCount;
  final int             dismissCount;
  final ReportStatus    status;
  final DateTime        expiresAt;

  static DateTime _defaultExpiry(DateTime base) =>
      base.add(const Duration(hours: kCrowdHazardTtlHours));

  LatLng get position => LatLng(lat, lng);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Credibility score 0–100 derived from confirm/dismiss votes.
  ///
  /// Formula: 50 + (confirms − dismisses) × 10, clamped to [0, 100].
  /// A report with zero votes starts at 50 (neutral).
  /// Each net confirmation adds 10 points; each net dismissal subtracts 10.
  int get credibilityScore {
    if (status == ReportStatus.resolved) return 0;
    final net = confirmCount - dismissCount;
    return (50 + net * 10).clamp(0, 100);
  }

  // ── Firestore serialisation ────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'type':         type.name,
        'lat':          lat,
        'lng':          lng,
        'reportedBy':   reportedBy,
        'reportedAt':   Timestamp.fromDate(reportedAt),
        'upvotes':      upvotes,
        'severity':     severity.name,
        'confirmCount': confirmCount,
        'dismissCount': dismissCount,
        'status':       status.name,
        'expiresAt':    Timestamp.fromDate(expiresAt),
      };

  /// Integration-ready export format suitable for city API consumption.
  ///
  /// Uses generic field names and ISO-8601 timestamps so external systems
  /// can consume this without knowledge of CYKEL internals.
  Map<String, dynamic> toApiJson() => {
        'id':               id,
        'source':           'cykel_crowd_report',
        'category':         'hazard',
        'subtype':          type.name,
        'severity':         severity.name,
        'status':           status.name,
        'credibility':      credibilityScore,
        'location': {
          'lat': lat,
          'lng': lng,
        },
        'votes': {
          'upvotes':      upvotes,
          'confirmations': confirmCount,
          'dismissals':   dismissCount,
        },
        'timestamps': {
          'reported':  reportedAt.toIso8601String(),
          'expires':   expiresAt.toIso8601String(),
        },
      };

  factory CrowdHazardReport.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    final reportedAt = (m['reportedAt'] as Timestamp).toDate();
    return CrowdHazardReport(
      id:           doc.id,
      type:         CrowdHazardType.values.firstWhere(
                      (e) => e.name == m['type'],
                      orElse: () => CrowdHazardType.debris),
      lat:          (m['lat'] as num).toDouble(),
      lng:          (m['lng'] as num).toDouble(),
      reportedBy:   m['reportedBy'] as String? ?? '',
      reportedAt:   reportedAt,
      upvotes:      (m['upvotes'] as num?)?.toInt() ?? 0,
      severity:     HazardSeverity.values.firstWhere(
                      (e) => e.name == (m['severity'] as String? ?? ''),
                      orElse: () => HazardSeverity.caution),
      confirmCount: (m['confirmCount'] as num?)?.toInt() ?? 0,
      dismissCount: (m['dismissCount'] as num?)?.toInt() ?? 0,
      status:       ReportStatusX.fromString(m['status'] as String?),
      expiresAt:    m['expiresAt'] != null
                      ? (m['expiresAt'] as Timestamp).toDate()
                      : null,
    );
  }
}
