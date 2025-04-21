import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class TripRepo {
  ResultFuture<TripEntity> loadTrip();
  ResultFuture<TripEntity> searchTripByNumber(String tripNumberId);
  ResultFuture<(TripEntity, String)> acceptTrip(String tripId);
  ResultFuture<TripEntity> loadLocalTrip();
 // New method to update trip location
  ResultFuture<TripEntity> updateTripLocation(String tripId, double latitude, double longitude);
  ResultFuture<bool> checkEndTripStatus(); // Add this new function
  ResultFuture<bool> checkEndTripOtpStatus(String tripId); // New function
ResultFuture<TripEntity> scanTripByQR(String qrData);
  ResultFuture<List<TripEntity>> searchTrips({
    String? tripNumberId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAccepted,
    bool? isEndTrip,
    String? deliveryTeamId,
    String? vehicleId,
    String? personnelId,
  });

  ResultFuture<TripEntity> getTripById(String id);
  ResultFuture<TripEntity> loadLocalTripById(String id);

  ResultFuture<List<TripEntity>> getTripsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  ResultFuture<String> calculateTotalTripDistance(String tripId);

  ResultFuture<TripEntity> endTrip(String tripId);


}
