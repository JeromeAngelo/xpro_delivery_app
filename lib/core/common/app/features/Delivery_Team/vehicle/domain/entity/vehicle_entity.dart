import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
@Entity()
class VehicleEntity extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
  final String? collectionId;
  final String? collectionName;
  final String? vehicleName;
  final String? vehiclePlateNumber;
  final String? vehicleType;
  final ToOne<DeliveryTeamModel> deliveryTeam = ToOne<DeliveryTeamModel>();
  final ToOne<TripModel> trip = ToOne<TripModel>();
  final DateTime? created;
  final DateTime? updated;

  VehicleEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.vehicleName,
    this.vehiclePlateNumber,
    this.vehicleType,
    DeliveryTeamModel? deliveryTeamModel,
    TripModel? tripModel,
    this.created,
    this.updated,
  }) {
    if (deliveryTeamModel != null) deliveryTeam.target = deliveryTeamModel;
    if (tripModel != null) trip.target = tripModel;
  }

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        vehicleName,
        vehiclePlateNumber,
        vehicleType,
        deliveryTeam.target?.id,
        trip.target?.id,
        created,
        updated,
      ];
}
