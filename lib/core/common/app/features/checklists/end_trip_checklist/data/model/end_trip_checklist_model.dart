import 'package:flutter/foundation.dart' show debugPrint;
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/domain/entity/end_checklist_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../../../../enums/sync_status_enums.dart';
import '../../../../trip_ticket/trip/data/models/trip_models.dart';
@Entity()
class EndTripChecklistModel extends EndChecklistEntity {
  // --------------------------------------------------------------------------
  // OBJECTBOX ID
  // --------------------------------------------------------------------------

  @Id(assignable: true)
  int objectBoxId = 0;

  // --------------------------------------------------------------------------
  // CORE FIELDS (TripModel-style clean overrides)
  // --------------------------------------------------------------------------

  @override
  @Property()
  String? id;

  @Property()
  String pocketbaseId = '';

  // Used for offline lookup / sync
  @Property()
  String? tripId;

  @override
  @Property()
  String? objectName;

  @override
  @Property()
  bool? isChecked;

  @override
  @Property()
  String? status;

  @override
  @Property()
  DateTime? timeCompleted;

  // --------------------------------------------------------------------------
  // RELATIONS
  // --------------------------------------------------------------------------

final trip = ToOne<TripModel>();

// --------------------------------------------------------------------------
  // 🔵 BACKGROUND SYNC FIELDS
  // --------------------------------------------------------------------------

  @Property()
  String syncStatus = SyncStatus.pending.name; // pending, syncing, synced, failed

  @Property()
  int retryCount = 0; // retry counter for backoff

  @Property()
  DateTime? lastSyncAttemptAt; // last attempt timestamp

  @Property()
  DateTime? nextRetryAt; // scheduled next retry

  @Property()
  String? lastSyncError; // error message from last attempt

  @Property()
  DateTime? lastLocalUpdatedAt; // local timestamp for conflict resolution
  // --------------------------------------------------------------------------
  // CONSTRUCTOR
  // --------------------------------------------------------------------------

  EndTripChecklistModel({
    this.id,
    this.objectName,
    this.isChecked,
    this.status,
    this.timeCompleted,
    String? tripId,
    TripModel? tripData,
    String? syncStatus, // nullable
  this.retryCount = 0,
  this.lastSyncAttemptAt,
  this.nextRetryAt,
  this.lastSyncError,
  this.lastLocalUpdatedAt,
    this.objectBoxId = 0,
  }) : super(
          id: id ?? '',
          objectName: objectName ?? '',
          isChecked: isChecked ?? false,
          status: status ?? '',
          tripId: tripId ?? '',
          timeCompleted: timeCompleted,
        ) {
    pocketbaseId = id ?? '';
    this.tripId = tripId;

   if (tripData != null) trip.target = tripData;
  }


  // --------------------------------------------------------------------------
  // 🔵 PARSE HELPERS
  // --------------------------------------------------------------------------
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      debugPrint('📅 Failed to parse date → fallback: null');
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // FROM JSON
  // --------------------------------------------------------------------------

  factory EndTripChecklistModel.fromJson(dynamic json) {
    debugPrint('🔄 MODEL: Creating EndTripChecklistModel from JSON');

    // ID-only fallback
    if (json is String) {
      return EndTripChecklistModel(id: json);
    }

    final expandedData = json['expand'] as Map<String, dynamic>?;

    // -----------------------------
    // Trip handling (expanded / id / model)
    // -----------------------------
    TripModel? tripModel;
    final tripData = expandedData?['trip'] ?? json['trip'];

    if (tripData != null) {
      if (tripData is Map<String, dynamic>) {
        tripModel = TripModel.fromJson(tripData);
      } else if (tripData is TripModel) {
        tripModel = tripData;
      } else if (tripData is String && tripData.isNotEmpty) {
        tripModel = TripModel(id: tripData);
      }
    }

    return EndTripChecklistModel(
      id: json['id']?.toString(),
      objectName: json['objectName']?.toString(),
      isChecked: json['isChecked'] as bool? ?? false,
      status: json['status']?.toString(),
      timeCompleted: json['timeCompleted'] != null
          ? DateTime.tryParse(json['timeCompleted'].toString())?.toUtc()
          : null,
      tripId: json['trip']?.toString(),
      tripData: tripModel,
      syncStatus: json['syncStatus']?.toString() ?? SyncStatus.pending.name,
      retryCount: json['retryCount'] ?? 0,
      lastSyncAttemptAt: parseDate(json['lastSyncAttemptAt']),
      nextRetryAt: parseDate(json['nextRetryAt']),
      lastSyncError: json['lastSyncError']?.toString(),
      lastLocalUpdatedAt: parseDate(json['lastLocalUpdatedAt']),
    );
  }

  // --------------------------------------------------------------------------
  // TO JSON (PocketBase-compatible)
  // --------------------------------------------------------------------------

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'objectName': objectName,
      'isChecked': isChecked,
      'status': status,
      'trip': tripId,
      'tripModel': trip,
      'timeCompleted': timeCompleted?.toIso8601String(),
      'syncStatus': syncStatus,
      'retryCount': retryCount,
      'lastSyncAttemptAt': lastSyncAttemptAt?.toIso8601String(),
      'nextRetryAt': nextRetryAt?.toIso8601String(),
      'lastSyncError': lastSyncError,
      'lastLocalUpdatedAt': lastLocalUpdatedAt?.toIso8601String(),
    };
  }

  // --------------------------------------------------------------------------
  // COPY WITH
  // --------------------------------------------------------------------------

  EndTripChecklistModel copyWith({
    String? id,
    String? objectName,
    bool? isChecked,
    String? status,
    DateTime? timeCompleted,
    TripModel? tripData,
     String? syncStatus,
    int? retryCount,
    DateTime? lastSyncAttemptAt,
    DateTime? nextRetryAt,
    String? lastSyncError,
    DateTime? lastLocalUpdatedAt,
  }) {
    final model = EndTripChecklistModel(
      id: id ?? this.id,
      objectName: objectName ?? this.objectName,
      isChecked: isChecked ?? this.isChecked,
      status: status ?? this.status,
      timeCompleted: timeCompleted ?? this.timeCompleted,
      tripId: tripId,
      tripData: tripData ,
      objectBoxId: objectBoxId,
       syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      lastSyncAttemptAt: lastSyncAttemptAt ?? this.lastSyncAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      lastLocalUpdatedAt: lastLocalUpdatedAt ?? this.lastLocalUpdatedAt,
    );

    return model;
  }

  // --------------------------------------------------------------------------
  // OVERRIDES
  // --------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndTripChecklistModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
