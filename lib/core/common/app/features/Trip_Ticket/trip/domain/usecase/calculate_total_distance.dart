import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CalculateTotalTripDistance extends UsecaseWithParams<String, String> {
  const CalculateTotalTripDistance(this._repo);
  final TripRepo _repo;

  @override
  ResultFuture<String> call(String params) => _repo.calculateTotalTripDistance(params);
}
