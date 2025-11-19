import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:pocketbase/pocketbase.dart';

class VehicleModel extends VehicleEntity {
  String pocketbaseId;
  String? tripId;
  String? deliveryTeamId;

  VehicleModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.vehicleName,
    super.vehiclePlateNumber,
    super.vehicleType,
    DeliveryTeamModel? deliveryTeamModel,
    TripModel? tripModel,
    super.created,
    super.updated,
    this.tripId,
    this.deliveryTeamId,
  }) : pocketbaseId = id ?? '',
       super(
         deliveryTeam: deliveryTeamModel,
         trip: tripModel,
       );

  factory VehicleModel.fromJson(DataMap json) {
    final expandedData = json['expand'] as Map<String, dynamic>?;

    // Handle trip data
    final tripData = expandedData?['trip'];
    TripModel? tripModel;
    if (tripData != null) {
      if (tripData is RecordModel) {
        tripModel = TripModel.fromJson({
          'id': tripData.id,
          'collectionId': tripData.collectionId,
          'collectionName': tripData.collectionName,
          ...tripData.data,
        });
      } else if (tripData is Map) {
        tripModel = TripModel.fromJson(tripData as Map<String, dynamic>);
      }
    }

    // Handle delivery team data
    final deliveryTeamData = expandedData?['deliveryTeam'];
    DeliveryTeamModel? deliveryTeamModel;
    if (deliveryTeamData != null) {
      if (deliveryTeamData is RecordModel) {
        deliveryTeamModel = DeliveryTeamModel.fromJson({
          'id': deliveryTeamData.id,
          'collectionId': deliveryTeamData.collectionId,
          'collectionName': deliveryTeamData.collectionName,
          ...deliveryTeamData.data,
        });
      } else if (deliveryTeamData is Map) {
        deliveryTeamModel = DeliveryTeamModel.fromJson(deliveryTeamData as Map<String, dynamic>);
      }
    }

    return VehicleModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      vehicleName: json['vehicleName']?.toString(),
      vehiclePlateNumber: json['vehiclePlateNumber']?.toString(),
      vehicleType: json['vehicleType']?.toString(),
      tripModel: tripModel,
      deliveryTeamModel: deliveryTeamModel,
      tripId: json['trip']?.toString(),
      deliveryTeamId: json['deliveryTeam']?.toString(),
      created: json['created'] != null ? DateTime.parse(json['created'].toString()) : null,
      updated: json['updated'] != null ? DateTime.parse(json['updated'].toString()) : null,
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'vehicleName': vehicleName,
      'vehiclePlateNumber': vehiclePlateNumber,
      'vehicleType': vehicleType,
      'trip': tripId,
      'deliveryTeam': deliveryTeamId,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  VehicleModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? vehicleName,
    String? vehiclePlateNumber,
    String? vehicleType,
    TripModel? tripModel,
    DeliveryTeamModel? deliveryTeamModel,
    String? tripId,
    String? deliveryTeamId,
    DateTime? created,
    DateTime? updated,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      vehicleName: vehicleName ?? this.vehicleName,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      tripModel: tripModel ?? trip,
      deliveryTeamModel: deliveryTeamModel ?? deliveryTeam,
      tripId: tripId ?? this.tripId,
      deliveryTeamId: deliveryTeamId ?? this.deliveryTeamId,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  factory VehicleModel.fromEntity(VehicleEntity entity) {
    return VehicleModel(
      id: entity.id,
      collectionId: entity.collectionId,
      collectionName: entity.collectionName,
      vehicleName: entity.vehicleName,
      vehiclePlateNumber: entity.vehiclePlateNumber,
      vehicleType: entity.vehicleType,
      tripModel: entity.trip,
      deliveryTeamModel: entity.deliveryTeam,
      created: entity.created,
      updated: entity.updated,
    );
  }
  
  factory VehicleModel.empty() {
    return VehicleModel(
      id: '',
      collectionId: '',
      collectionName: '',
      vehicleName: '',
      vehiclePlateNumber: '',
      vehicleType: '',
      tripModel: null,
      deliveryTeamModel: null,
      created: null,
      updated: null,
    );
  }

  @override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is VehicleModel && other.id == id;
}

@override
int get hashCode => id.hashCode;

}
