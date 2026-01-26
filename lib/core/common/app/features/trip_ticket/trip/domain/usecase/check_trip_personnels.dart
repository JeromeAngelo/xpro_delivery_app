import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CheckTripPersonnels extends UsecaseWithParams<List<String>, String> {
  const CheckTripPersonnels(this._repo);

  final TripRepo _repo;

  @override
  ResultFuture<List<String>> call(String tripId) => _repo.checkTripPersonnels(tripId);
}
