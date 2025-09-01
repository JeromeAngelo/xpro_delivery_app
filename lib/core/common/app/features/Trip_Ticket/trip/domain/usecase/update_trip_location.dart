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
      accuracy: params.accuracy,
      source: params.source,
      totalDistance: params.totalDistance,
    );
  }
}

class UpdateTripLocationParams extends Equatable {
  final String tripId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? source;
  final double? totalDistance;

  const UpdateTripLocationParams({
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.source,
    this.totalDistance,
  });

  @override
  List<Object?> get props => [tripId, latitude, longitude, accuracy, source, totalDistance];
}
