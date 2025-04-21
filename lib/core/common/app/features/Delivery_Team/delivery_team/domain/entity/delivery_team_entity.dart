import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
@Entity()
class DeliveryTeamEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  String? collectionId;
  String? collectionName;
  final ToMany<PersonelModel> personels = ToMany<PersonelModel>();
  final ToMany<ChecklistModel> checklist = ToMany<ChecklistModel>();
  final ToMany<VehicleModel> vehicle = ToMany<VehicleModel>();
  final ToOne<TripModel> trip = ToOne<TripModel>();
  int? activeDeliveries;
  int? totalDelivered;
  int? undeliveredCustomers;
  double? totalDistanceTravelled;
  DateTime? created;
  DateTime? updated;

  DeliveryTeamEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    List<PersonelModel>? personels,
    List<ChecklistModel>? checklist,
    List<VehicleModel>? vehicle,
    TripModel? trip,
    this.activeDeliveries,
    this.totalDelivered,
    this.undeliveredCustomers,
    this.totalDistanceTravelled,
    this.created,
    this.updated,
  }) {
    if (personels != null) this.personels.addAll(personels);
    if (checklist != null) this.checklist.addAll(checklist);
    if (vehicle != null) this.vehicle.addAll(vehicle);
    if (trip != null) this.trip.target = trip;
  }

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

       // Add this factory constructor
  factory DeliveryTeamEntity.empty() {
    return DeliveryTeamEntity(
      id: '',
      collectionId: '',
      collectionName: '',
      personels: const [],
      checklist: const [],
      vehicle: const [],
      trip: null,
      activeDeliveries: 0,
      totalDelivered: 0,
      undeliveredCustomers: 0,
      totalDistanceTravelled: 0,
      created: DateTime.now(),
      updated: DateTime.now(),
    );
  }
}
