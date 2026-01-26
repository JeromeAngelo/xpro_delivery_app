import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../../../../../../enums/sync_status_enums.dart';

@Entity()
class TripUpdateModel extends TripUpdateEntity {
  @Id(assignable: true)
  int objectBoxId = 0;

  // --------------------------------------------------------------------------
  // FIELDS
  // --------------------------------------------------------------------------
  @override
  @Property()
  String? id;

  @Property()
  String pocketbaseId = '';

  @Property()
  String? tripId;

  // ---- Boolean fields ----
  @Property()
  bool _hasTrip = false;

  @Property()
  bool? get hasTrip => _hasTrip;

  set hasTrip(bool? value) {
    _hasTrip = value ?? false;
  }

  @Property()
  bool _hasPendingSync = false;

  @Property()
  bool? get hasPendingSync => _hasPendingSync;

  set hasPendingSync(bool? value) {
    _hasPendingSync = value ?? false;
  }

  // Sync state
  @Property()
  String syncStatus = SyncStatus.synced.name;

  // Retry handling
  @Property()
  int retryCount = 0;

  @Property()
  DateTime? lastSyncAttemptAt;

  @Property()
  DateTime? nextRetryAt;

  // Error tracking
  @Property()
  String? lastSyncError;

  // Conflict resolution
  @Property()
  int version = 0;

  // Optional audit
  @Property()
  String? updatedBy;

  @Property()
  String? deviceId;

  // --------------------------------------------------------------------------
  // MAIN DATA FIELDS
  // --------------------------------------------------------------------------
  @override
  @Property()
  TripUpdateStatus? status;

  @override
  @Property()
  DateTime? date;

  @override
  @Property()
  String? image;

  @override
  @Property()
  String? description;

  @override
  @Property()
  String? latitude;

  @override
  @Property()
  String? longitude;

  @Property()
  String? collectionId;

  @Property()
  String? collectionName;

  // --------------------------------------------------------------------------
  // RELATIONS
  // --------------------------------------------------------------------------
  final trip = ToOne<TripModel>();

  // --------------------------------------------------------------------------
  // CONSTRUCTOR
  // --------------------------------------------------------------------------
  TripUpdateModel({
    this.id,
    this.collectionId,
    this.collectionName,
    this.status,
    this.date,
    this.image,
    this.description,
    this.latitude,
    this.longitude,
    TripModel? tripData,
    this.tripId,
    bool? hasTrip,
    bool? hasPendingSync,
    this.objectBoxId = 0,
  }) {
    pocketbaseId = id ?? '';
    if (tripData != null) trip.target = tripData;
    this.hasTrip = hasTrip ?? false;
    this.hasPendingSync = hasPendingSync ?? false;
  }

  // --------------------------------------------------------------------------
  // JSON PARSING
  // --------------------------------------------------------------------------
  factory TripUpdateModel.fromJson(DataMap json) {
    final expandedData = json['expand'] as Map<String, dynamic>?;

    TripModel? tripModel;
    if (expandedData?['trip'] != null) {
      tripModel = TripModel.fromJson(expandedData!['trip'] as DataMap);
    }

    TripUpdateStatus parseStatus(String? statusStr) {
      if (statusStr == null) return TripUpdateStatus.none;
      switch (statusStr) {
        case 'vehicleBreakdown':
          return TripUpdateStatus.vehicleBreakdown;
        case 'generalUpdate':
          return TripUpdateStatus.generalUpdate;
        case 'refuelling':
          return TripUpdateStatus.refuelling;
        case 'roadClosure':
          return TripUpdateStatus.roadClosure;
        case 'others':
          return TripUpdateStatus.others;
        default:
          return TripUpdateStatus.none;
      }
    }

    return TripUpdateModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      status: parseStatus(json['status']?.toString()),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : DateTime.now(),
      image: json['image']?.toString(),
      description: json['description']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      tripData: tripModel,
      tripId: expandedData?['trip']?['id']?.toString(),
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'status': status?.toString().split('.').last,
      'date': date?.toIso8601String(),
      'image': image,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'trip': trip.target?.id,
    };
  }

  // --------------------------------------------------------------------------
  // INITIAL
  // --------------------------------------------------------------------------
  factory TripUpdateModel.initial([String? tripId]) {
    return TripUpdateModel(
      id: '',
      collectionId: '',
      collectionName: 'tripUpdates',
      status: TripUpdateStatus.others,
      date: DateTime.now(),
      image: null,
      description: '',
      latitude: '',
      longitude: '',
      tripId: tripId,
    );
  }

  // --------------------------------------------------------------------------
  // COPY WITH
  // --------------------------------------------------------------------------
  TripUpdateModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    TripUpdateStatus? status,
    DateTime? date,
    String? image,
    String? description,
    String? latitude,
    String? longitude,
    TripModel? tripData,
    String? tripId,
    bool? hasTrip,
    bool? hasPendingSync,
  }) {
    return TripUpdateModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      status: status ?? this.status,
      date: date ?? this.date,
      image: image ?? this.image,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tripData: tripData ?? this.trip.target,
      tripId: tripId ?? this.tripId,
      hasTrip: hasTrip ?? this.hasTrip,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
      objectBoxId: objectBoxId,
    );
  }

  // --------------------------------------------------------------------------
  // OVERRIDES
  // --------------------------------------------------------------------------
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TripUpdateModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
