import '../../../models/delivery_team_model.dart';
import '../delivery_team_remote_impl/delivery_team_remote_base.dart';
import '../delivery_team_remote_impl/load_delivery_team_impl.dart';
import '../delivery_team_remote_impl/load_delivery_team_by_id_impl.dart';
import '../delivery_team_remote_impl/sync_delivery_team_by_trip_impl.dart';
import '../delivery_team_remote_impl/assign_delivery_team_to_trip_impl.dart';

abstract class DeliveryTeamDatasource {
  Future<DeliveryTeamModel> loadDeliveryTeam(String tripId);
  Future<DeliveryTeamModel> loadDeliveryTeamById(String deliveryTeamId);
  Future<DeliveryTeamModel> syncDeliveryTeamByTrip(String tripId);

  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  });
}

class DeliveryTeamDatasourceImpl extends DeliveryTeamRemoteBase
    with
        LoadDeliveryTeamImpl,
        LoadDeliveryTeamByIdImpl,
        SyncDeliveryTeamByTripImpl,
        AssignDeliveryTeamToTripImpl
    implements DeliveryTeamDatasource {
  const DeliveryTeamDatasourceImpl({
    required super.pocketBaseClient,
    required super.deliveryTeamBox,
  });
}
