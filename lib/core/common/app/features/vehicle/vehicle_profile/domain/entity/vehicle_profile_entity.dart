import 'package:equatable/equatable.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';

import '../../../../../../../enums/vehicle_status.dart';

class VehicleProfileEntity extends Equatable {
  String? id;
  String? collectionId;
  String? collectionName;
  DeliveryVehicleModel? deliveryVehicleData;
  List<TripModel>? assignedTrips;
  
  /// New field for file attachments from PocketBase
  List<String>? attachments;

  DateTime? created;
  DateTime? updated;
  VehicleStatus? status;

  VehicleProfileEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.deliveryVehicleData,
    this.assignedTrips,
    this.attachments,
    this.status,
    this.created,
    this.updated,
  });

  factory VehicleProfileEntity.empty() {
    return VehicleProfileEntity(
      id: '',
      collectionId: '',
      collectionName: '',
      deliveryVehicleData: null,
      assignedTrips: [],
      attachments: [],
      status: VehicleStatus.goodCondition,
      created: null,
      updated: null,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        deliveryVehicleData?.id,
        assignedTrips?.map((trip) => trip.id).toList(),
        attachments,
        status,
        created,
        updated,
      ];
}
