import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/domain/entity/checklist_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../trip_ticket/trip/data/models/trip_models.dart';
@Entity()
class ChecklistModel extends ChecklistEntity {
  // --------------------------------------------------------------------------
  // OBJECTBOX ID
  // --------------------------------------------------------------------------
  @Id()
  int objectBoxId = 0;

  // --------------------------------------------------------------------------
  // BASIC IDS
  // --------------------------------------------------------------------------

  /// PocketBase record ID (also duplicated into [pocketbaseId] for consistency)
  @override
  @Property()
  String? id;

  /// ✅ Consistent naming with other models (deliveryDataModel.pocketbaseId)
  @Property()
  String pocketbaseId = '';

  /// Optional: store trip PB id for fast filtering/debug
  @Property()
  String? tripId;

  // --------------------------------------------------------------------------
  // FIELDS
  // --------------------------------------------------------------------------

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
  @Property(type: PropertyType.date)
  DateTime? timeCompleted;

  @Property()
  String? description;

  // --------------------------------------------------------------------------
  // RELATIONS
  // --------------------------------------------------------------------------
  final trip = ToOne<TripModel>();

  // --------------------------------------------------------------------------
  // CONSTRUCTOR
  // --------------------------------------------------------------------------
  ChecklistModel({
    this.id,
    String? pocketbaseId,
    this.tripId,
    this.objectName,
    this.isChecked,
    this.status,
    this.description,
    this.timeCompleted,
    TripModel? tripModel,
    this.objectBoxId = 0,
  }) : super(
          id: id ?? '',
          objectName: objectName ?? '',
          isChecked: isChecked ?? false,
          status: status ?? '',
          timeCompleted: timeCompleted,
          tripModel: tripModel,
        ) {
    // ✅ Normalize PB ID:
    // prefer explicit pocketbaseId, else fallback to id
    final normalized = (pocketbaseId ?? this.id ?? '').trim();
    this.pocketbaseId = normalized;

    // ✅ Fix wrong self-assignment bug
    // (previously: tripId = tripId; does nothing)
    this.tripId = this.tripId ?? tripModel?.id;

    if (tripModel != null) {
      trip.target = tripModel;
    }
  }

  // --------------------------------------------------------------------------
  // FROM JSON
  // --------------------------------------------------------------------------
  factory ChecklistModel.fromJson(dynamic json) {
    debugPrint('🔄 MODEL: Creating ChecklistModel from JSON');

    // ✅ ID-only case
    if (json is String) {
      final id = json.trim();
      return ChecklistModel(
        id: id,
        pocketbaseId: id, // IMPORTANT so cleanup/sync won’t treat it as null
      );
    }

    final map = json as Map<String, dynamic>;
    final expanded = map['expand'] as Map<String, dynamic>?;

    // -----------------------------
    // Trip (expand or ID)
    // -----------------------------
    TripModel? tripModel;
    final tripData = expanded?['trip'] ?? map['trip'];
    if (tripData != null) {
      if (tripData is Map<String, dynamic>) {
        tripModel = TripModel.fromJson(tripData);
      } else if (tripData is TripModel) {
        tripModel = tripData;
      } else if (tripData is String && tripData.trim().isNotEmpty) {
        tripModel = TripModel(id: tripData.trim());
      }
    }

    final id = map['id']?.toString().trim();
    final tripId = map['trip']?.toString().trim();

    return ChecklistModel(
      id: id,
      pocketbaseId: id, // ✅ mirror PB id always
      objectName: map['objectName']?.toString(),
      description: map['description']?.toString(),
      isChecked: map['isChecked'] as bool? ?? false,
      status: map['status']?.toString(),
      timeCompleted: map['timeCompleted'] != null
          ? DateTime.tryParse(map['timeCompleted'].toString())
          : null,
      tripId: tripId,
      tripModel: tripModel,
    );
  }

  // --------------------------------------------------------------------------
  // TO JSON
  // --------------------------------------------------------------------------
  DataMap toJson() {
    return {
      'id': pocketbaseId.isNotEmpty ? pocketbaseId : (id ?? ''),
      'objectName': objectName,
      'description': description,
      'isChecked': isChecked ?? false,
      'status': status,
      'timeCompleted': timeCompleted?.toIso8601String(),
      // ✅ send trip PB id (prefer relation target if loaded)
      'trip': trip.target?.id ?? tripId,
    };
  }

  // --------------------------------------------------------------------------
  // COPY WITH
  // --------------------------------------------------------------------------
  ChecklistModel copyWith({
    String? id,
    String? pocketbaseId,
    String? tripId,
    String? objectName,
    bool? isChecked,
    String? status,
    String? description,
    DateTime? timeCompleted,
    TripModel? tripModel,
  }) {
    final result = ChecklistModel(
      id: id ?? this.id,
      pocketbaseId: pocketbaseId ?? this.pocketbaseId,
      tripId: tripId ?? this.tripId,
      objectName: objectName ?? this.objectName,
      isChecked: isChecked ?? this.isChecked,
      status: status ?? this.status,
      description: description ?? this.description,
      timeCompleted: timeCompleted ?? this.timeCompleted,
      tripModel: tripModel ?? trip.target,
      objectBoxId: objectBoxId,
    );

    return result;
  }

  // --------------------------------------------------------------------------
  // OVERRIDES
  // --------------------------------------------------------------------------
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistModel &&
          (other.pocketbaseId.isNotEmpty ? other.pocketbaseId : other.id) ==
              (pocketbaseId.isNotEmpty ? pocketbaseId : id);

  @override
  int get hashCode =>
      (pocketbaseId.isNotEmpty ? pocketbaseId : (id ?? '')).hashCode;
}
