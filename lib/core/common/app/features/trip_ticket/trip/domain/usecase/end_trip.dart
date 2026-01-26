import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class EndTrip extends UsecaseWithParams<TripEntity, String> {
  const EndTrip(this._repo);
  final TripRepo _repo;

  @override
  ResultFuture<TripEntity> call(String params) => _repo.endTrip(params);
}
