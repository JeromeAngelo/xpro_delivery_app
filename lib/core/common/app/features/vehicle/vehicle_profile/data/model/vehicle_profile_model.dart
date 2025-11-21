import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

import '../../../../../../../enums/vehicle_status.dart';
import '../../../../Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import '../../../../Trip_Ticket/trip/data/models/trip_models.dart';
import '../../domain/entity/vehicle_profile_entity.dart';

class VehicleProfileModel extends VehicleProfileEntity {
  String? pocketbaseId;

  // Relationship IDs
  String? deliveryVehicleId;
  List<String>? assignedTripIds;

  // Attachments stored in PocketBase
  List<String>? attachmentFiles;

  VehicleProfileModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.deliveryVehicleData,
    super.assignedTrips,
    super.attachments,
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

    // DELIVERY VEHICLE
    DeliveryVehicleModel? deliveryVehicle;
    final dvData = expand?['deliveryVehicleData'] ?? json['deliveryVehicleData'];
    if (dvData != null) {
      if (dvData is RecordModel) {
        deliveryVehicle = DeliveryVehicleModel.fromJson({
          'id': dvData.id,
          'collectionId': dvData.collectionId,
          'collectionName': dvData.collectionName,
          ...dvData.data,
        });
      } else if (dvData is Map) {
        deliveryVehicle = DeliveryVehicleModel.fromJson(dvData as Map<String, dynamic>);
      } else if (dvData is String) {
        deliveryVehicle = DeliveryVehicleModel(id: dvData);
      }
    }

    // ASSIGNED TRIPS
    List<TripModel> assignedTripsList = [];
    final tripsExpand = expand?['assignedTrips'] ?? json['assignedTrips'];
    if (tripsExpand != null) {
      if (tripsExpand is List) {
        assignedTripsList = tripsExpand.map((t) {
          if (t is RecordModel) {
            return TripModel.fromJson({
              'id': t.id,
              'collectionId': t.collectionId,
              'collectionName': t.collectionName,
              ...t.data,
            });
          } else if (t is Map) {
            return TripModel.fromJson(t as Map<String, dynamic>);
          } else if (t is String) {
            return TripModel(id: t);
          }
          return TripModel.empty();
        }).toList();
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

      // Expanded entities
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
      created: json['created'] != null ? _parseDateTime(json['created']) : null,
      updated: json['updated'] != null ? _parseDateTime(json['updated']) : null,
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
      'attachments': attachmentFiles ?? [],
      'status': status?.name,
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
      assignedTripIds: entity.assignedTrips?.map((t) => t.id ?? '').toList() ?? [],
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
  // HELPER - SAFE DATE PARSE
  // ---------------------------------------------------------------------------
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      if (value is int) {
        return value > 9999999999
            ? DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal()
            : DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true).toLocal();
      }
      final strValue = value.toString().trim();
      try {
        final parsed = DateTime.parse(strValue);
        return parsed.isUtc ? parsed.toLocal() : parsed;
      } catch (_) {}
      return DateTime.tryParse(strValue);
    } catch (e) {
      debugPrint('❌ _parseDateTime error: $e');
      return null;
    }
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
