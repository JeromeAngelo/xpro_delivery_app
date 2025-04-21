import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';

class SearchTrip extends UsecaseWithParams<TripEntity, String> {
  const SearchTrip(this._repo);

  final TripRepo _repo;

  @override
  ResultFuture<TripEntity> call(String params) async {
    return _repo.searchTripByNumber(params);
  }
}
