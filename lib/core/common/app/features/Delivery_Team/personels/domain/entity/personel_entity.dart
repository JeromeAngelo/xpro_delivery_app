import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';
@Entity()
class PersonelEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  String? collectionId;
  String? collectionName;
  String? name;
  final ToOne<DeliveryTeamModel> deliveryTeam = ToOne<DeliveryTeamModel>();
  final ToOne<TripModel> trip = ToOne<TripModel>();
  UserRole? role;
  DateTime? created;
  DateTime? updated;

  PersonelEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.name,
    this.role,
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
        name,
        role,
        deliveryTeam.target?.id,
        trip.target?.id,
        created,
        updated,
      ];
}
