import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/domain/repo/trip_update_repo.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CreateTripUpdateParams {
  final String tripId;
  final String description;
  final String image;
  final String latitude;
  final String longitude;
  final TripUpdateStatus status;

  const CreateTripUpdateParams({
    required this.tripId,
    required this.description,
    required this.image,
    required this.latitude,
    required this.longitude,
    required this.status,
  });
}

class CreateTripUpdate extends UsecaseWithParams<void, CreateTripUpdateParams> {
  const CreateTripUpdate(this._repo);

  final TripUpdateRepo _repo;

  @override
  ResultFuture<void> call(CreateTripUpdateParams params) => _repo.createTripUpdate(
        tripId: params.tripId,
        description: params.description,
        image: params.image,
        latitude: params.latitude,
        longitude: params.longitude,
        status: params.status
      );
}
