/// CYKEL — Bike Maintenance Provider
/// Manages maintenance records in Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/maintenance.dart';
import '../domain/bike.dart';
import 'bikes_provider.dart';

/// Service for managing bike maintenance records
class MaintenanceService {
  MaintenanceService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _maintenanceCol(String uid, String bikeId) =>
      _db.collection('users').doc(uid).collection('bikes').doc(bikeId).collection('maintenance');

  /// Stream all maintenance records for a bike
  Stream<List<MaintenanceRecord>> streamRecords(String uid, String bikeId) {
    return _maintenanceCol(uid, bikeId)
        .orderBy('date', descending: true)
        .limit(100)  // Limit maintenance records
        .snapshots()
        .map((snap) => snap.docs.map(MaintenanceRecord.fromFirestore).toList());
  }

  /// Get all maintenance records for a bike
  Future<List<MaintenanceRecord>> getRecords(String uid, String bikeId) async {
    try {
      final snap = await _maintenanceCol(uid, bikeId)
          .orderBy('date', descending: true)
          .limit(100)  // Limit maintenance records
          .get();
      return snap.docs.map(MaintenanceRecord.fromFirestore).toList();
    } catch (e) {
      debugPrint('[Maintenance] Get records error: $e');
      return [];
    }
  }

  /// Add a new maintenance record
  Future<void> addRecord(String uid, String bikeId, MaintenanceRecord record) async {
    try {
      final doc = _maintenanceCol(uid, bikeId).doc();
      final data = record.toJson();
      data['id'] = doc.id;
      await doc.set(data);
    } catch (e) {
      debugPrint('[Maintenance] Add record error: $e');
      rethrow;
    }
  }

  /// Update a maintenance record
  Future<void> updateRecord(String uid, String bikeId, MaintenanceRecord record) async {
    try {
      await _maintenanceCol(uid, bikeId).doc(record.id).update(record.toJson());
    } catch (e) {
      debugPrint('[Maintenance] Update record error: $e');
      rethrow;
    }
  }

  /// Delete a maintenance record
  Future<void> deleteRecord(String uid, String bikeId, String recordId) async {
    try {
      await _maintenanceCol(uid, bikeId).doc(recordId).delete();
    } catch (e) {
      debugPrint('[Maintenance] Delete record error: $e');
      rethrow;
    }
  }

  /// Get maintenance status for a bike (with calculated km from rides)
  Future<MaintenanceStatus> getStatus(String uid, String bikeId, double totalKm) async {
    final records = await getRecords(uid, bikeId);
    return MaintenanceStatus(
      bikeId: bikeId,
      totalKm: totalKm,
      records: records,
    );
  }

  /// Get all reminders for overdue/due-soon maintenance across all bikes
  Future<List<MaintenanceReminder>> getReminders(
    String uid, 
    List<Bike> bikes,
    Map<String, double> bikeKmMap,
  ) async {
    final reminders = <MaintenanceReminder>[];
    
    for (final bike in bikes) {
      final totalKm = bikeKmMap[bike.id] ?? 0;
      final status = await getStatus(uid, bike.id, totalKm);
      
      for (final record in status.overdueItems) {
        reminders.add(MaintenanceReminder(
          bikeId: bike.id,
          bikeName: bike.name,
          type: record.type,
          kmUntilDue: record.kmUntilService(totalKm),
          isOverdue: true,
        ));
      }
      
      for (final record in status.dueSoonItems) {
        reminders.add(MaintenanceReminder(
          bikeId: bike.id,
          bikeName: bike.name,
          type: record.type,
          kmUntilDue: record.kmUntilService(totalKm),
          isOverdue: false,
        ));
      }
    }
    
    // Sort by urgency (most overdue first)
    reminders.sort((a, b) => a.kmUntilDue.compareTo(b.kmUntilDue));
    
    return reminders;
  }
}

/// Provider for maintenance service
final maintenanceServiceProvider = Provider<MaintenanceService>((ref) {
  return MaintenanceService(FirebaseFirestore.instance);
});

/// Stream provider for maintenance records of a specific bike
final bikeMaintenanceProvider = StreamProvider.family<List<MaintenanceRecord>, String>((ref, bikeId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(maintenanceServiceProvider).streamRecords(user.uid, bikeId);
});

/// Provider for maintenance status of a specific bike
final bikeMaintenanceStatusProvider = FutureProvider.family<MaintenanceStatus, ({String bikeId, double totalKm})>((ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return MaintenanceStatus(bikeId: params.bikeId, totalKm: params.totalKm, records: []);
  }
  
  return ref.watch(maintenanceServiceProvider).getStatus(user.uid, params.bikeId, params.totalKm);
});

/// Provider for all maintenance reminders across all bikes
final maintenanceRemindersProvider = FutureProvider<List<MaintenanceReminder>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final bikesAsync = ref.watch(bikesProvider);
  final bikes = bikesAsync.value ?? [];
  if (bikes.isEmpty) return [];
  
  // TODO: Get actual km per bike from ride history
  // For now, use simple estimate or stored value
  final bikeKmMap = <String, double>{
    for (final bike in bikes) bike.id: bike.totalKm ?? 0,
  };
  
  return ref.watch(maintenanceServiceProvider).getReminders(user.uid, bikes, bikeKmMap);
});
