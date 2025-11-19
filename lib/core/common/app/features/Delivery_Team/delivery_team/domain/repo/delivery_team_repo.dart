import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/vehicle/delivery_vehicle_data/domain/entity/vehicle_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

abstract class DeliveryTeamRepo {
  // Existing functions to keep
  ResultFuture<List<DeliveryTeamEntity>> loadAllDeliveryTeam();
  ResultFuture<DeliveryTeamEntity> loadDeliveryTeam(String tripId);
  ResultFuture<DeliveryTeamEntity> loadDeliveryTeamById(String deliveryTeamId);
  ResultFuture<DeliveryTeamEntity> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  });
  
  // New functions for creating and updating delivery teams
  ResultFuture<DeliveryTeamEntity> createDeliveryTeam({
    required String deliveryTeamId,
    required VehicleEntity vehicle,
    required List<PersonelEntity> personels,
    required TripEntity tripId
  });
  
  ResultFuture<DeliveryTeamEntity> updateDeliveryTeam({
    required String deliveryTeamId,
    required VehicleEntity vehicle,
    required List<PersonelEntity> personels,
    required TripEntity tripId
  });
  
  ResultFuture<bool> deleteDeliveryTeam(String deliveryTeamId);
  
}
