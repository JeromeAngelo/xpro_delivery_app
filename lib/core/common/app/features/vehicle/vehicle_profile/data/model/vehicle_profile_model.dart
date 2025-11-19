import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

import '../../../../../../../enums/vehicle_status.dart';
import '../../../../Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import '../../../../Trip_Ticket/trip/data/models/trip_models.dart';
import '../../domain/entity/vehicle_profile_entity.dart';

class VehicleProfileModel extends VehicleProfileEntity {
  final String pocketbaseId;

  // Relationship IDs
  String? deliveryVehicleId;
  List<String>? assignedTripIds;

  // Attachments stored in PocketBase (file names)
  List<String>? attachmentFiles;

  VehicleProfileModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.deliveryVehicleData,
    super.attachments,
    super.assignedTrips,
    super.status,
    super.created,
    super.updated,
    this.deliveryVehicleId,
    this.assignedTripIds,
    this.attachmentFiles,
  }) : pocketbaseId = id ?? '';

  // ---------------------------------------------------------------------------
  // FROM JSON
  // ---------------------------------------------------------------------------
  factory VehicleProfileModel.fromJson(DataMap json) {
    final expand = json['expand'] as Map<String, dynamic>?;

    // DELIVERY VEHICLE (expand)
    DeliveryVehicleModel? deliveryVehicle;
    final dvData = expand?['deliveryVehicleData'];

    if (dvData != null) {
      if (dvData is RecordModel) {
        deliveryVehicle = DeliveryVehicleModel.fromJson({
          'id': dvData.id,
          'collectionId': dvData.collectionId,
          'collectionName': dvData.collectionName,
          ...dvData.data,
        });
      } else if (dvData is Map) {
        deliveryVehicle =
            DeliveryVehicleModel.fromJson(dvData as Map<String, dynamic>);
      }
    }

    // ASSIGNED TRIPS (expand)
    List<TripModel> assignedTripsList = [];
    final tripsExpand = expand?['assignedTrips'];

    if (tripsExpand != null && tripsExpand is List) {
      for (var t in tripsExpand) {
        if (t is RecordModel) {
          assignedTripsList.add(
            TripModel.fromJson({
              'id': t.id,
              'collectionId': t.collectionId,
              'collectionName': t.collectionName,
              ...t.data,
            }),
          );
        } else if (t is Map) {
          assignedTripsList.add(TripModel.fromJson(t as Map<String, dynamic>));
        }
      }
    }

    // STATUS ENUM
    VehicleStatus? status;
    final statusVal = json['status']?.toString();
    if (statusVal != null) {
      status = VehicleStatus.values.firstWhere(
        (s) => s.name == statusVal,
        orElse: () => VehicleStatus.goodCondition,
      );
    }

    return VehicleProfileModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),

      // Expand entities
      deliveryVehicleData: deliveryVehicle,
      assignedTrips: assignedTripsList,

      // Relationship IDs
      deliveryVehicleId: json['deliveryVehicleData']?.toString(),
      assignedTripIds: json['assignedTrips'] != null
          ? List<String>.from(json['assignedTrips'])
          : [],

      // Attachments
      attachmentFiles: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : [],

      status: status,
      created:
          json['created'] != null ? DateTime.tryParse(json['created']) : null,
      updated:
          json['updated'] != null ? DateTime.tryParse(json['updated']) : null,
    );
  }

  // ---------------------------------------------------------------------------
  // TO JSON
  // ---------------------------------------------------------------------------
  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'deliveryVehicleData': deliveryVehicleId,
      'assignedTrips': assignedTripIds ?? [],
      'status': status?.name,
      'attachments': attachmentFiles ?? [],
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // COPY WITH
  // ---------------------------------------------------------------------------
  VehicleProfileModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    DeliveryVehicleModel? deliveryVehicleData,
    List<TripModel>? assignedTrips,
    String? deliveryVehicleId,
    List<String>? assignedTripIds,
    VehicleStatus? status,
    List<String>? attachments,
    List<String>? attachmentFiles,
    DateTime? created,
    DateTime? updated,
  }) {
    return VehicleProfileModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      deliveryVehicleData: deliveryVehicleData ?? this.deliveryVehicleData,
      assignedTrips: assignedTrips ?? this.assignedTrips,
      deliveryVehicleId: deliveryVehicleId ?? this.deliveryVehicleId,
      assignedTripIds: assignedTripIds ?? this.assignedTripIds,
      status: status ?? this.status,

      // Attachments
      attachments: attachments ?? this.attachments,
      attachmentFiles: attachmentFiles ?? this.attachmentFiles,

      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  // ---------------------------------------------------------------------------
  // FROM ENTITY
  // ---------------------------------------------------------------------------
  factory VehicleProfileModel.fromEntity(VehicleProfileEntity entity) {
    return VehicleProfileModel(
      id: entity.id,
      collectionId: entity.collectionId,
      collectionName: entity.collectionName,
      deliveryVehicleData: entity.deliveryVehicleData,
      assignedTrips: entity.assignedTrips?.cast<TripModel>(),
      deliveryVehicleId: entity.deliveryVehicleData?.id,
      assignedTripIds:
          entity.assignedTrips?.map((t) => t.id ?? '').toList() ?? [],

      // Attachments
      attachments: entity.attachments,
      attachmentFiles: entity.attachments?.cast<String>(),

      status: entity.status,
      created: entity.created,
      updated: entity.updated,
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY MODEL
  // ---------------------------------------------------------------------------
  factory VehicleProfileModel.empty() {
    return VehicleProfileModel(
      id: '',
      collectionId: '',
      collectionName: '',
      deliveryVehicleData: null,
      assignedTrips: [],
      deliveryVehicleId: '',
      assignedTripIds: [],
      attachmentFiles: [],
      status: VehicleStatus.goodCondition,
      created: null,
      updated: null,
    );
  }

  // ---------------------------------------------------------------------------
  // EQUALITY
  // ---------------------------------------------------------------------------
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehicleProfileModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
