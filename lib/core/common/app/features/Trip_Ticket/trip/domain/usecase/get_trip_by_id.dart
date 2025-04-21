import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetTripById extends UsecaseWithParams<TripEntity, String> {
  const GetTripById(this._repo);
  final TripRepo _repo;

  @override
  ResultFuture<TripEntity> call(String params) => _repo.getTripById(params);
  ResultFuture<TripEntity> loadFromLocal(String id) => _repo.loadLocalTripById(id);
}
