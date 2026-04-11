/// CYKEL — Bike Maintenance Models
/// Domain models for tracking bike maintenance and service reminders

import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of maintenance that can be tracked
enum MaintenanceType {
  /// Chain lubrication/replacement
  chain,
  /// Tire replacement/repair
  tires,
  /// Brake pad replacement
  brakePads,
  /// Brake cable adjustment
  brakeCables,
  /// Gear cable adjustment
  gearCables,
  /// Battery service (e-bike)
  battery,
  /// General tune-up
  tuneUp,
  /// Wheel truing
  wheelTrue,
  /// Light check/replacement
  lights,
  /// Full service at shop
  fullService,
  /// Other custom maintenance
  other,
}

extension MaintenanceTypeX on MaintenanceType {
  /// Display name
  String get displayName {
    switch (this) {
      case MaintenanceType.chain:
        return 'Kæde';
      case MaintenanceType.tires:
        return 'Dæk';
      case MaintenanceType.brakePads:
        return 'Bremseklodser';
      case MaintenanceType.brakeCables:
        return 'Bremsekabler';
      case MaintenanceType.gearCables:
        return 'Gearkabler';
      case MaintenanceType.battery:
        return 'Batteri';
      case MaintenanceType.tuneUp:
        return 'Justering';
      case MaintenanceType.wheelTrue:
        return 'Hjulretning';
      case MaintenanceType.lights:
        return 'Lygter';
      case MaintenanceType.fullService:
        return 'Fuld service';
      case MaintenanceType.other:
        return 'Andet';
    }
  }

  /// Recommended interval in km
  int get recommendedIntervalKm {
    switch (this) {
      case MaintenanceType.chain:
        return 500; // Lubricate every 500km
      case MaintenanceType.tires:
        return 5000; // Check/replace every 5000km
      case MaintenanceType.brakePads:
        return 2000;
      case MaintenanceType.brakeCables:
        return 3000;
      case MaintenanceType.gearCables:
        return 3000;
      case MaintenanceType.battery:
        return 5000;
      case MaintenanceType.tuneUp:
        return 1000;
      case MaintenanceType.wheelTrue:
        return 2000;
      case MaintenanceType.lights:
        return 1000;
      case MaintenanceType.fullService:
        return 3000;
      case MaintenanceType.other:
        return 1000;
    }
  }

  /// Icon code point
  int get iconCodePoint {
    switch (this) {
      case MaintenanceType.chain:
        return 0xe900; // Custom or use existing
      case MaintenanceType.tires:
        return 0xe531; // tire_repair
      case MaintenanceType.brakePads:
        return 0xe1c3; // no_crash
      case MaintenanceType.brakeCables:
        return 0xe1c3;
      case MaintenanceType.gearCables:
        return 0xe8b8; // settings
      case MaintenanceType.battery:
        return 0xe1a4; // battery_full
      case MaintenanceType.tuneUp:
        return 0xe869; // build
      case MaintenanceType.wheelTrue:
        return 0xea3b; // trip_origin
      case MaintenanceType.lights:
        return 0xe518; // lightbulb
      case MaintenanceType.fullService:
        return 0xe8b8; // settings
      case MaintenanceType.other:
        return 0xe8b8;
    }
  }
}

/// A single maintenance record
class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.bikeId,
    required this.type,
    required this.date,
    required this.kmAtService,
    this.notes,
    this.cost,
    this.shopName,
    this.nextServiceKm,
    this.createdAt,
  });

  final String id;
  final String bikeId;
  final MaintenanceType type;
  final DateTime date;
  final double kmAtService;
  final String? notes;
  final double? cost;
  final String? shopName;
  final double? nextServiceKm;
  final DateTime? createdAt;

  /// Distance until next service is due
  double kmUntilService(double currentKm) {
    final next = nextServiceKm ?? (kmAtService + type.recommendedIntervalKm);
    return next - currentKm;
  }

  /// Whether service is overdue
  bool isOverdue(double currentKm) => kmUntilService(currentKm) < 0;

  /// Whether service is due soon (within 100km)
  bool isDueSoon(double currentKm) => kmUntilService(currentKm) < 100;

  Map<String, dynamic> toJson() => {
    'id': id,
    'bikeId': bikeId,
    'type': type.name,
    'date': Timestamp.fromDate(date),
    'kmAtService': kmAtService,
    'notes': notes,
    'cost': cost,
    'shopName': shopName,
    'nextServiceKm': nextServiceKm,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
  };

  factory MaintenanceRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MaintenanceRecord(
      id: doc.id,
      bikeId: data['bikeId'] as String,
      type: MaintenanceType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => MaintenanceType.other,
      ),
      date: (data['date'] as Timestamp).toDate(),
      kmAtService: (data['kmAtService'] as num).toDouble(),
      notes: data['notes'] as String?,
      cost: (data['cost'] as num?)?.toDouble(),
      shopName: data['shopName'] as String?,
      nextServiceKm: (data['nextServiceKm'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Summary of maintenance status for a bike
class MaintenanceStatus {
  const MaintenanceStatus({
    required this.bikeId,
    required this.totalKm,
    required this.records,
  });

  final String bikeId;
  final double totalKm;
  final List<MaintenanceRecord> records;

  /// Get the most recent record for each type
  Map<MaintenanceType, MaintenanceRecord> get latestByType {
    final map = <MaintenanceType, MaintenanceRecord>{};
    for (final record in records) {
      final existing = map[record.type];
      if (existing == null || record.date.isAfter(existing.date)) {
        map[record.type] = record;
      }
    }
    return map;
  }

  /// Get overdue maintenance items
  List<MaintenanceRecord> get overdueItems {
    return latestByType.values
        .where((r) => r.isOverdue(totalKm))
        .toList()
      ..sort((a, b) => a.kmUntilService(totalKm).compareTo(b.kmUntilService(totalKm)));
  }

  /// Get items due soon
  List<MaintenanceRecord> get dueSoonItems {
    return latestByType.values
        .where((r) => r.isDueSoon(totalKm) && !r.isOverdue(totalKm))
        .toList()
      ..sort((a, b) => a.kmUntilService(totalKm).compareTo(b.kmUntilService(totalKm)));
  }

  /// Get types that have never been serviced
  List<MaintenanceType> get neverServiced {
    final serviced = latestByType.keys.toSet();
    return MaintenanceType.values
        .where((t) => !serviced.contains(t) && t != MaintenanceType.other)
        .toList();
  }

  /// Overall health score (0-100)
  int get healthScore {
    final overdue = overdueItems.length;
    final dueSoon = dueSoonItems.length;
    final never = neverServiced.length;
    
    // Start at 100, deduct for issues
    var score = 100;
    score -= overdue * 15; // -15 per overdue item
    score -= dueSoon * 5;  // -5 per due soon item
    score -= never * 3;    // -3 per never serviced item
    
    return score.clamp(0, 100);
  }

  /// Health status label
  String get healthLabel {
    final score = healthScore;
    if (score >= 80) return 'God';
    if (score >= 60) return 'OK';
    if (score >= 40) return 'Kræver opmærksomhed';
    return 'Kritisk';
  }
}

/// Maintenance reminder notification
class MaintenanceReminder {
  const MaintenanceReminder({
    required this.bikeId,
    required this.bikeName,
    required this.type,
    required this.kmUntilDue,
    required this.isOverdue,
  });

  final String bikeId;
  final String bikeName;
  final MaintenanceType type;
  final double kmUntilDue;
  final bool isOverdue;

  String get message {
    if (isOverdue) {
      return '${type.displayName} på $bikeName er ${(-kmUntilDue).toStringAsFixed(0)} km overskredet';
    } else {
      return '${type.displayName} på $bikeName om ${kmUntilDue.toStringAsFixed(0)} km';
    }
  }
}
