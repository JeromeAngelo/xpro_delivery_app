import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class DeliveryTeamRepo {
  ResultFuture<DeliveryTeamEntity> loadDeliveryTeam(String tripId);
  ResultFuture<DeliveryTeamEntity> loadLocalDeliveryTeam(String tripId);
  ResultFuture<DeliveryTeamEntity> loadDeliveryTeamById(String deliveryTeamId);
  ResultFuture<DeliveryTeamEntity> loadLocalDeliveryTeamById(String deliveryTeamId);
  ResultFuture<DeliveryTeamEntity> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  });
}



