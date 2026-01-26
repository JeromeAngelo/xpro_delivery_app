import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/users_roles/entity/user_role_entity.dart';

@Entity()
class LocalUser extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
  final String? collectionId;
  final String? collectionName;
  final String? email;
  final String? profilePic;
  final String? name;
  final String? tripNumberId;
  final String? token; 
  final UserRoleEntity? userRole;

  // Changed to ToOne relationship
  final ToOne<DeliveryTeamModel> deliveryTeam = ToOne<DeliveryTeamModel>();
  final ToOne<TripModel> trip = ToOne<TripModel>();

  LocalUser({
    this.id,
    this.collectionId,
    this.collectionName,
    this.email,
    this.profilePic,
    this.name,
    this.tripNumberId,
    this.token,
    this.userRole,
    DeliveryTeamModel? deliveryTeamModel,
    TripModel? tripModel,
  }) {
    if (deliveryTeamModel != null) deliveryTeam.target = deliveryTeamModel;
    if (tripModel != null) trip.target = tripModel;
  }

  LocalUser.empty()
      : id = '',
        collectionId = '',
        collectionName = '',
        email = '',
        profilePic = '',
        token = '',
        name = '',
        tripNumberId = '',
        userRole = null;

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        email,
        profilePic,
        name,
        tripNumberId,
        deliveryTeam.target,
        trip.target,
        token,
        userRole,
      ];
}
