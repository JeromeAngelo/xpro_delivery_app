import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/data/model/vehicle_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:equatable/equatable.dart';


class DeliveryTeamEntity extends Equatable {
  final String? id;
  final String? collectionId;
  final String? collectionName;
  final List<PersonelModel> personels;
  final List<ChecklistModel> checklist;
  final List<VehicleModel> vehicle;
  final TripModel? trip;
  final int? activeDeliveries;
  final int? totalDelivered;
  final int? undeliveredCustomers;
  final double? totalDistanceTravelled;
  final DateTime? created;
  final DateTime? updated;

  DeliveryTeamEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    List<PersonelModel>? personels,
    List<ChecklistModel>? checklist,
    List<VehicleModel>? vehicle,
    this.trip,
    this.activeDeliveries,
    this.totalDelivered,
    this.undeliveredCustomers,
    this.totalDistanceTravelled,
    this.created,
    this.updated,
  }) : 
    personels = personels ?? [],
    checklist = checklist ?? [],
    vehicle = vehicle ?? [];

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        personels,
        checklist,
        vehicle,
        trip,
        activeDeliveries,
        totalDelivered,
        undeliveredCustomers,
        totalDistanceTravelled,
        created,
        updated,
      ];

  // Factory constructor for creating an empty entity
  factory DeliveryTeamEntity.empty() {
    return DeliveryTeamEntity(
      id: '',
      collectionId: '',
      collectionName: '',
      personels: [],
      checklist: [],
      vehicle: [],
      trip: null,
      activeDeliveries: 0,
      totalDelivered: 0,
      undeliveredCustomers: 0,
      totalDistanceTravelled: 0,
      created: DateTime.now(),
      updated: DateTime.now(),
    );
  }
  
  @override
  String toString() {
    return 'DeliveryTeamEntity(id: $id, personels: ${personels.length}, vehicles: ${vehicle.length}, checklist: ${checklist.length})';
  }
}
