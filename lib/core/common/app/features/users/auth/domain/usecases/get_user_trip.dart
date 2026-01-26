import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repo/auth_repo.dart';

class GetUserTrip extends UsecaseWithParams<TripEntity, String> {
  const GetUserTrip(this._repo);
  final AuthRepo _repo;

  @override
  ResultFuture<TripEntity> call(String params) => _repo.getUserTrip(params);
  ResultFuture<TripEntity> loadFromLocal(String userId) => _repo.loadLocalUserTrip(userId);
}
