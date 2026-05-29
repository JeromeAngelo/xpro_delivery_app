import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';

import '../delivery_team_local_impl/delivery_team_local_base.dart';
import '../delivery_team_local_impl/load_delivery_team_impl.dart';
import '../delivery_team_local_impl/update_delivery_team_impl.dart';
import '../delivery_team_local_impl/cache_delivery_team_impl.dart';
import '../delivery_team_local_impl/load_delivery_team_by_id_impl.dart';
import '../delivery_team_local_impl/assign_delivery_team_to_trip_impl.dart';
import '../delivery_team_local_impl/save_delivery_team_by_trip_id_impl.dart';

abstract class DeliveryTeamLocalDatasource {
  Future<DeliveryTeamModel> loadDeliveryTeam(String tripId);
  Future<void> updateDeliveryTeam(DeliveryTeamModel team);
  Future<void> cacheDeliveryTeam(DeliveryTeamModel team);
  Future<DeliveryTeamModel> loadDeliveryTeamById(String deliveryTeamId);
  Future<void> saveDeliveryTeamByTripId(String tripId, DeliveryTeamModel team);
  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  });
}

class DeliveryTeamLocalDatasourceImpl extends DeliveryTeamLocalBase
    with
        LoadDeliveryTeamImpl,
        UpdateDeliveryTeamImpl,
        CacheDeliveryTeamImpl,
        LoadDeliveryTeamByIdImpl,
        AssignDeliveryTeamToTripImpl,
        SaveDeliveryTeamByTripIdImpl
    implements DeliveryTeamLocalDatasource {
  DeliveryTeamLocalDatasourceImpl(super.objectBoxStore);
}
