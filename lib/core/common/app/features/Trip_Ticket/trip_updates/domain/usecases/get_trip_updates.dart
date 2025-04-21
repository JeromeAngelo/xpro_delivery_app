import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/repo/trip_update_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetTripUpdates extends UsecaseWithParams<List<TripUpdateEntity>, String> {
  const GetTripUpdates(this._repo);

  final TripUpdateRepo _repo;

  @override
  ResultFuture<List<TripUpdateEntity>> call(String params) => 
      _repo.getTripUpdates(params);

  ResultFuture<List<TripUpdateEntity>> loadFromLocal(String tripId) =>
      _repo.getLocalTripUpdates(tripId);
}
