import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/entity/delivery_team_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/domain/repo/delivery_team_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadDeliveryTeam extends UsecaseWithParams<DeliveryTeamEntity, String> {
  const LoadDeliveryTeam(this._repo);

  final DeliveryTeamRepo _repo;

  @override
  ResultFuture<DeliveryTeamEntity> call(String params) => _repo.loadDeliveryTeam(params);
  
  ResultFuture<DeliveryTeamEntity> loadFromLocal(String tripId) => _repo.loadLocalDeliveryTeam(tripId);
}

