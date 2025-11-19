import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:equatable/equatable.dart';

class VehicleEntity extends Equatable {
  final String? id;
  final String? collectionId;
  final String? collectionName;
  final String? vehicleName;
  final String? vehiclePlateNumber;
  final String? vehicleType;
  final DeliveryTeamModel? deliveryTeam;
  final TripModel? trip;
  final DateTime? created;
  final DateTime? updated;

  const VehicleEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.vehicleName,
    this.vehiclePlateNumber,
    this.vehicleType,
    this.deliveryTeam,
    this.trip,
    this.created,
    this.updated,
  });

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        vehicleName,
        vehiclePlateNumber,
        vehicleType,
        deliveryTeam?.id,
        trip?.id,
        created,
        updated,
      ];
      
  factory VehicleEntity.empty() {
    return const VehicleEntity(
      id: '',
      collectionId: '',
      collectionName: '',
      vehicleName: '',
      vehiclePlateNumber: '',
      vehicleType: '',
      deliveryTeam: null,
      trip: null,
      created: null,
      updated: null,
    );
  }
  
  @override
  String toString() {
    return 'VehicleEntity(id: $id, name: $vehicleName, plate: $vehiclePlateNumber, type: $vehicleType)';
  }
}
