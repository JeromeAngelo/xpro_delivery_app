import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class UpdateTripLocation implements UsecaseWithParams<TripEntity, UpdateTripLocationParams> {
  final TripRepo _repo;

  const UpdateTripLocation(this._repo);

  @override
  ResultFuture<TripEntity> call(UpdateTripLocationParams params) async {
    return await _repo.updateTripLocation(
      params.tripId,
      params.latitude,
      params.longitude,
    );
  }
}

class UpdateTripLocationParams extends Equatable {
  final String tripId;
  final double latitude;
  final double longitude;

  const UpdateTripLocationParams({
    required this.tripId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [tripId, latitude, longitude];
}
