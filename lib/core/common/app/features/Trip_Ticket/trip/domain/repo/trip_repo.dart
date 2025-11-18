import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

abstract class TripRepo {
  const TripRepo();

  /// Get all trip tickets
  ResultFuture<List<TripEntity>> getAllTripTickets();

    ResultFuture<List<TripEntity>> getAllActiveTripTickets();

  
  /// Create a new trip ticket
  ResultFuture<TripEntity> createTripTicket(TripEntity trip);
  
  /// Search trip tickets by various criteria
  ResultFuture<List<TripEntity>> searchTripTickets({
    String? tripNumberId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAccepted,
    bool? isEndTrip,
    String? deliveryTeamId,
    String? vehicleId,
    String? personnelId,
  });
  
  /// Get a specific trip ticket by ID
  ResultFuture<TripEntity> getTripTicketById(String tripId);
  
  /// Update an existing trip ticket
  ResultFuture<TripEntity> updateTripTicket(TripEntity trip);
  
  /// Delete a specific trip ticket
  ResultFuture<bool> deleteTripTicket(String tripId);
  
  /// Delete all trip tickets
  ResultFuture<bool> deleteAllTripTickets();

   // NEW: Filter by date range
  ResultFuture<List<TripEntity>> filterTripsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  // NEW: Filter by user
  ResultFuture<List<TripEntity>> filterTripsByUser({
    required String userId,
  });


}
