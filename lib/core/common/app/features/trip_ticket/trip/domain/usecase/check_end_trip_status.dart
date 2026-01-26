import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CheckEndTripStatus implements UsecaseWithoutParams<bool> {
  const CheckEndTripStatus(this._repo);

  final TripRepo _repo;

  @override
  ResultFuture<bool> call() async => _repo.checkEndTripStatus();
}
  