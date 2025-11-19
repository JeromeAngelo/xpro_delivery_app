import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/repo/delivery_team_repo.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';
import 'package:equatable/equatable.dart';

class UpdateDeliveryTeam extends UsecaseWithParams<DeliveryTeamEntity, UpdateDeliveryTeamParams> {
  final DeliveryTeamRepo _repo;

  const UpdateDeliveryTeam(this._repo);

  @override
  ResultFuture<DeliveryTeamEntity> call(UpdateDeliveryTeamParams params) async {
    return _repo.updateDeliveryTeam(
      deliveryTeamId: params.deliveryTeamId,
      vehicle: params.vehicle,
      personels: params.personels,
      tripId: params.tripId,
    );
  }
}

class UpdateDeliveryTeamParams extends Equatable {
  final String deliveryTeamId;
  final VehicleEntity vehicle;
  final List<PersonelEntity> personels;
  final TripEntity tripId;

  const UpdateDeliveryTeamParams({
    required this.deliveryTeamId,
    required this.vehicle,
    required this.personels,
    required this.tripId,
  });

  @override
  List<Object?> get props => [
    deliveryTeamId,
    vehicle,
    personels,
    tripId,
  ];
}
