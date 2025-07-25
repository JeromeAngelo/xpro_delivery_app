import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/personnels_trip/domain/entity/personnel_trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/material.dart';

class PersonnelTripModel extends PersonnelTripEntity {
  String? personnelsId;
  List<String> assignedTripIds;

  PersonnelTripModel({
    super.id,
    super.collectionId,
    super.collectionName,
    PersonelModel? personnelModel,
    List<TripModel>? assignedTripModels,
    super.created,
    super.updated,
    this.personnelsId,
    List<String>? assignedTripIds,
  }) : assignedTripIds = assignedTripIds ?? [],
       super(
         personnels: personnelModel,
         assignedTrip: assignedTripModels ?? [],
       );

  factory PersonnelTripModel.fromJson(DataMap json) {
    debugPrint('🔄 Creating PersonnelTripModel from JSON');
    
    final expandedData = json['expand'] as Map<String, dynamic>?;

    // Handle personnel data
    final personnelData = expandedData?['personnels'];
    PersonelModel? personnelModel;
    if (personnelData != null) {
      if (personnelData is RecordModel) {
        personnelModel = PersonelModel.fromJson({
          'id': personnelData.id,
          'collectionId': personnelData.collectionId,
          'collectionName': personnelData.collectionName,
          ...personnelData.data,
        });
      } else if (personnelData is Map) {
        personnelModel = PersonelModel.fromJson(personnelData as Map<String, dynamic>);
      }
    }

    // Handle assigned trips data
    final assignedTripsData = expandedData?['assignedTrips'];
    List<TripModel> assignedTripModels = [];
    List<String> assignedTripIds = [];
    
    if (assignedTripsData != null) {
      if (assignedTripsData is List) {
        assignedTripModels = assignedTripsData.map((trip) {
          if (trip is String) {
            assignedTripIds.add(trip);
            return TripModel(id: trip);
          } else if (trip is RecordModel) {
            assignedTripIds.add(trip.id);
            return TripModel.fromJson({
              'id': trip.id,
              'collectionId': trip.collectionId,
              'collectionName': trip.collectionName,
              ...trip.data,
            });
          } else if (trip is Map) {
            final tripMap = trip as Map<String, dynamic>;
            assignedTripIds.add(tripMap['id']?.toString() ?? '');
            return TripModel.fromJson(tripMap);
          }
          return TripModel(id: '');
        }).toList();
      }
    }

    // Also check for raw assignedTrips field
    if (json['assignedTrips'] is List) {
      final rawTrips = json['assignedTrips'] as List;
      assignedTripIds = rawTrips.map((trip) => trip.toString()).toList();
    }

    return PersonnelTripModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      personnelModel: personnelModel,
      assignedTripModels: assignedTripModels,
      personnelsId: json['personnels']?.toString(),
      assignedTripIds: assignedTripIds,
      created: json['created'] != null
          ? DateTime.parse(json['created'].toString())
          : null,
      updated: json['updated'] != null
          ? DateTime.parse(json['updated'].toString())
          : null,
    );
  }

  DataMap toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'personnels': personnelsId,
      'assignedTrips': assignedTripIds,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  PersonnelTripModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    PersonelModel? personnelModel,
    List<TripModel>? assignedTripModels,
    String? personnelsId,
    List<String>? assignedTripIds,
    DateTime? created,
    DateTime? updated,
  }) {
    return PersonnelTripModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      personnelModel: personnelModel ?? personnels as PersonelModel?,
      assignedTripModels: assignedTripModels ?? assignedTrip.cast<TripModel>(),
      personnelsId: personnelsId ?? this.personnelsId,
      assignedTripIds: assignedTripIds ?? this.assignedTripIds,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  factory PersonnelTripModel.fromEntity(PersonnelTripEntity entity) {
    return PersonnelTripModel(
      id: entity.id,
      collectionId: entity.collectionId,
      collectionName: entity.collectionName,
      personnelModel: entity.personnels as PersonelModel?,
      assignedTripModels: entity.assignedTrip.cast<TripModel>(),
      created: entity.created,
      updated: entity.updated,
    );
  }

  factory PersonnelTripModel.empty() {
    return PersonnelTripModel(
      id: '',
      collectionId: '',
      collectionName: '',
      personnelModel: null,
      assignedTripModels: [],
      personnelsId: null,
      assignedTripIds: [],
      created: null,
      updated: null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonnelTripModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
