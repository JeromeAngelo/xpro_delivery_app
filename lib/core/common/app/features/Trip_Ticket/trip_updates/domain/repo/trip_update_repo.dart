import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/domain/entity/trip_update_entity.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class TripUpdateRepo {
  const TripUpdateRepo();

  // Load trip updates for a specific trip
  ResultFuture<List<TripUpdateEntity>> getTripUpdates(String tripId);

  ResultFuture<List<TripUpdateEntity>> getLocalTripUpdates(String tripId);

  // Create new trip update
  ResultFuture<void> createTripUpdate({
    required String tripId,
    required String description,
    required String image,
    required String latitude,
    required String longitude,
    required TripUpdateStatus status,
  });
}
