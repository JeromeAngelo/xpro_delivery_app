import 'package:dartz/dartz.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/datasource/remote_datasource/trip_remote_datasurce.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/repo/trip_repo.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:xpro_delivery_admin_app/core/errors/failures.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:flutter/material.dart';

class TripRepoImpl implements TripRepo {
  const TripRepoImpl(this._remoteDatasource);

  final TripRemoteDatasurce _remoteDatasource;

  @override
  ResultFuture<List<TripEntity>> getAllTripTickets() async {
    try {
      debugPrint('🔄 REPO: Fetching all trip tickets');
      final remoteTrips = await _remoteDatasource.getAllTripTickets();
      debugPrint('✅ REPO: Successfully retrieved ${remoteTrips.length} trip tickets');
      return Right(remoteTrips);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<TripEntity> createTripTicket(TripEntity trip) async {
    try {
      debugPrint('🔄 REPO: Creating new trip ticket');
      
      // Convert entity to model
      final tripModel = trip as TripModel;
      
      final createdTrip = await _remoteDatasource.createTripTicket(tripModel);
      debugPrint('✅ REPO: Trip ticket created successfully: ${createdTrip.id}');
      return Right(createdTrip);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<TripEntity>> searchTripTickets({
    String? tripNumberId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAccepted,
    bool? isEndTrip,
    String? deliveryTeamId,
    String? vehicleId,
    String? personnelId,
  }) async {
    try {
      debugPrint('🔍 REPO: Searching for trip tickets with filters');
      final results = await _remoteDatasource.searchTripTickets(
        tripNumberId: tripNumberId,
        startDate: startDate,
        endDate: endDate,
        isAccepted: isAccepted,
        isEndTrip: isEndTrip,
        deliveryTeamId: deliveryTeamId,
        vehicleId: vehicleId,
        personnelId: personnelId,
      );
      debugPrint('✅ REPO: Found ${results.length} matching trip tickets');
      return Right(results);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<TripEntity> getTripTicketById(String tripId) async {
    try {
      debugPrint('🔄 REPO: Fetching trip ticket by ID: $tripId');
      final trip = await _remoteDatasource.getTripTicketById(tripId);
      debugPrint('✅ REPO: Trip ticket found: ${trip.id}');
      return Right(trip);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<TripEntity> updateTripTicket(TripEntity trip) async {
    try {
      debugPrint('🔄 REPO: Updating trip ticket: ${trip.id}');
      
      // Convert entity to model
      final tripModel = trip as TripModel;
      
      final updatedTrip = await _remoteDatasource.updateTripTicket(tripModel);
      debugPrint('✅ REPO: Trip ticket updated successfully');
      return Right(updatedTrip);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> deleteTripTicket(String tripId) async {
    try {
      debugPrint('🔄 REPO: Deleting trip ticket: $tripId');
      final result = await _remoteDatasource.deleteTripTicket(tripId);
      debugPrint('✅ REPO: Trip ticket deleted successfully');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> deleteAllTripTickets() async {
    try {
      debugPrint('🔄 REPO: Deleting all trip tickets');
      final result = await _remoteDatasource.deleteAllTripTickets();
      debugPrint('✅ REPO: All trip tickets deleted successfully');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
@override
ResultFuture<List<TripEntity>> filterTripsByDateRange({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    debugPrint('🔄 REPO: Filtering trips by date range');
    debugPrint('📅 REPO: Start Date: ${startDate.toIso8601String()}');
    debugPrint('📅 REPO: End Date: ${endDate.toIso8601String()}');
    
    final remoteTrips = await _remoteDatasource.filterTripsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
    
    debugPrint('✅ REPO: Successfully retrieved ${remoteTrips.length} trips by date range');
    return Right(remoteTrips);
  } on ServerException catch (e) {
    debugPrint('❌ REPO: Server error filtering by date range: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<List<TripEntity>> filterTripsByUser({
  required String userId,
}) async {
  try {
    debugPrint('🔄 REPO: Filtering trips by user ID: $userId');
    
    final remoteTrips = await _remoteDatasource.filterTripsByUser(
      userId: userId,
    );
    
    debugPrint('✅ REPO: Successfully retrieved ${remoteTrips.length} trips for user: $userId');
    return Right(remoteTrips);
  } on ServerException catch (e) {
    debugPrint('❌ REPO: Server error filtering by user: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

  @override
  ResultFuture<List<TripEntity>> getAllActiveTripTickets() async {
    try {
      debugPrint('🔄 REPO: Fetching all trip tickets');
      final remoteTrips = await _remoteDatasource.getAllActiveTripTickets();
      debugPrint('✅ REPO: Successfully retrieved active ${remoteTrips.length} trip tickets');
      return Right(remoteTrips);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

}
