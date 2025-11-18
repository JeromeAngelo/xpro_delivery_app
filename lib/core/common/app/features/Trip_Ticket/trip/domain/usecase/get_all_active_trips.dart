import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';

class GetAllActiveTripTickets extends UsecaseWithoutParams<List<TripEntity>> {
  final TripRepo _repo;

  const GetAllActiveTripTickets(this._repo);

  @override
  ResultFuture<List<TripEntity>> call() {
    return _repo.getAllActiveTripTickets();
  }
}
