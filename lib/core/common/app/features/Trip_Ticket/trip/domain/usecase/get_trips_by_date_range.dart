import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetTripsByDateRange extends UsecaseWithParams<List<TripEntity>, DateRangeParams> {
  final TripRepo _repo;

  const GetTripsByDateRange(this._repo);

  @override
  ResultFuture<List<TripEntity>> call(DateRangeParams params) async {
    return _repo.getTripsByDateRange(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class DateRangeParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const DateRangeParams({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}
