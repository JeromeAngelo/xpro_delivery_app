import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_datasurce.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/repo/trip_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class TripRepoImpl implements TripRepo {
  const TripRepoImpl(
    this._remoteDatasource,
    this._localDatasource,
  );

  final TripRemoteDatasurce _remoteDatasource;
  final TripLocalDatasource _localDatasource;

  @override
  ResultFuture<TripEntity> loadTrip() async {
    try {
      debugPrint('🌐 Fetching trip data from remote');
      final remoteTrip = await _remoteDatasource.loadTrip();

      // Store successful remote data locally
      await _localDatasource.autoSaveTrip(remoteTrip);
      debugPrint('💾 Remote trip data cached locally');

      return Right(remoteTrip);
    } on ServerException catch (_) {
      debugPrint('⚠️ Remote fetch failed, checking local storage');
      try {
        final localTrip = await _localDatasource.loadTrip();
        return Right(localTrip as TripEntity);
      } on CacheException catch (e) {
        return Left(CacheFailure(
          message: e.message,
          statusCode: e.statusCode,
        ));
      }
    }
  }

  @override
  ResultFuture<TripEntity> searchTripByNumber(String tripNumberId) async {
    try {
      final result = await _remoteDatasource.searchTripByNumber(tripNumberId);
      await _localDatasource.saveTrip(result);
      return Right(result as TripEntity);
    } on ServerException catch (e) {
      try {
        final localTrip =
            await _localDatasource.searchTripByNumber(tripNumberId);
        return Right(localTrip );
      } on CacheException {
        return Left(ServerFailure(
          message: e.message,
          statusCode: e.statusCode,
        ));
      }
    }
  }@override
ResultFuture<(TripEntity, String)> acceptTrip(String tripId) async {
  try {
    debugPrint('🔄 REPO: Starting trip acceptance flow');

    // First create and accept trip in remote
    debugPrint('🌐 REPO: Creating trip in remote for ID: $tripId');
    final (remoteTrip, remoteTrackingId) = 
        await _remoteDatasource.acceptTrip(tripId);

    debugPrint('📦 REPO: Remote Trip Details:');
    debugPrint('   📋 Trip ID: ${remoteTrip.id}');
    debugPrint('   🔢 Trip Number: ${remoteTrip.tripNumberId}');
    debugPrint('   👥 Delivery Team ID: ${remoteTrip.deliveryTeam.target?.id}');
    debugPrint('   🎯 Tracking ID: $remoteTrackingId');

    // Accept and store trip locally
    debugPrint('💾 REPO: Processing local acceptance');
    final (localTrip, _) = await _localDatasource.acceptTrip(tripId);

    // Verify local storage
    debugPrint('✅ REPO: Trip accepted in both remote and local storage');
    debugPrint('   📱 Local Trip ID: ${localTrip.id}');
    debugPrint('   🔄 Local Trip Number: ${localTrip.tripNumberId}');

    return Right((remoteTrip, remoteTrackingId) );
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}


  @override
  ResultFuture<TripEntity> loadLocalTrip() async {
    try {
      debugPrint('📱 Loading trip from local storage');
      final localTrip = await _localDatasource.loadTrip();
      return Right(localTrip );
    } on CacheException catch (e) {
      return Left(CacheFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    }
  }

  @override
  ResultFuture<bool> checkEndTripOtpStatus(String tripId) async {
    try {
      debugPrint('🔍 Checking end trip OTP status');
      final remoteResult =
          await _remoteDatasource.checkEndTripOtpStatus(tripId);
      return Right(remoteResult);
    } on ServerException {
      try {
        debugPrint('📱 Checking local OTP status');
        final localResult =
            await _localDatasource.checkEndTripOtpStatus(tripId);
        return Right(localResult);
      } on CacheException catch (e) {
        return Left(CacheFailure(
          message: e.message,
          statusCode: e.statusCode,
        ));
      }
    }
  }

  @override
  ResultFuture<bool> checkEndTripStatus() {
    // TODO: implement checkEndTripStatus
    throw UnimplementedError();
  }

 

  @override
  ResultFuture<List<TripEntity>> searchTrips({
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
      debugPrint('🔍 REPO: Starting advanced trip search');
      final results = await _remoteDatasource.searchTrips(
        tripNumberId: tripNumberId,
        startDate: startDate,
        endDate: endDate,
        isAccepted: isAccepted,
        isEndTrip: isEndTrip,
        deliveryTeamId: deliveryTeamId,
        vehicleId: vehicleId,
        personnelId: personnelId,
      );
      return Right(results.cast<TripEntity>());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<TripEntity>> getTripsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('📅 REPO: Fetching trips by date range');
      final results =
          await _remoteDatasource.getTripsByDateRange(startDate, endDate);
      return Right(results.cast<TripEntity>());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<String> calculateTotalTripDistance(String tripId) async {
    try {
      final remoteDistance =
          await _remoteDatasource.calculateTotalTripDistance(tripId);
      return Right(remoteDistance);
    } on ServerException {
      try {
        final localDistance =
            await _localDatasource.calculateTotalTripDistance(tripId);
        return Right(localDistance);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }
  
@override
ResultFuture<TripEntity> scanTripByQR(String qrData) async {
  try {
    debugPrint('🔍 REPO: Processing QR scan...');
    debugPrint('📄 QR Data: $qrData');

    final result = await _remoteDatasource.scanTripByQR(qrData);

    debugPrint('✅ REPO: Trip scan successful. Trip ID: ${result.id}');
    return Right(result);

  } catch (e) {
    debugPrint('❌ REPO: Unexpected error in QR scan: $e');

    return Left(
      ServerFailure(
        message: 'Unexpected error scanning QR code: $e',
        statusCode: '500',
      ),
    );
  }
}



 @override
ResultFuture<TripEntity> getTripById(String id) async {
  try {
    debugPrint('🌐 REPO: Fetching trip by ID from remote: $id');
    final remoteTrip = await _remoteDatasource.getTripById(id);
    
    debugPrint('💾 REPO: Caching remote trip data locally');
    await _localDatasource.saveTrip(remoteTrip);
    
    return Right(remoteTrip );
  } on ServerException catch (e) {
    debugPrint('⚠️ REPO: Remote fetch failed, checking local storage');
    try {
      final localTrip = await _localDatasource.getTripById(id);
      return Right(localTrip);
    } on CacheException {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    }
  }
}

@override
ResultFuture<TripEntity> loadLocalTripById(String id) async {
  try {
    debugPrint('📱 REPO: Loading trip from local storage: $id');
    final localTrip = await _localDatasource.getTripById(id);
    return Right(localTrip );
  } on CacheException catch (e) {
    return Left(CacheFailure(
      message: e.message,
      statusCode: e.statusCode,
    ));
  }
}
@override
ResultFuture<TripEntity> endTrip(String tripId) async {
  final safeTripId = tripId.trim();

  if (safeTripId.isEmpty) {
    return Left(
      ServerFailure(message: 'Trip ID is required', statusCode: 400),
    );
  }

  debugPrint('🔄 REPO: endTrip($safeTripId)');

  // ---------------------------------------------------
  // 1️⃣ REMOTE FIRST
  // ---------------------------------------------------
  try {
    debugPrint('🌐 REPO: Ending trip remotely for ID: $safeTripId');
    final remoteTrip = await _remoteDatasource.endTrip(safeTripId);
    debugPrint('✅ REPO: Remote endTrip success → tripId=$safeTripId');

    // ---------------------------------------------------
    // 2️⃣ LOCAL AFTER REMOTE SUCCESS
    //    ✅ pass tripId so local clears only the correct trip safely
    // ---------------------------------------------------
    try {
      debugPrint('💾 REPO: Clearing local trip data for tripId=$safeTripId');
      await _localDatasource.endTrip(safeTripId);
      debugPrint('✅ REPO: Local cleanup success → tripId=$safeTripId');
    } on CacheException catch (ce) {
      // Remote already succeeded, so we return success but log local failure.
      // (Avoids “trip ended remotely but app shows error” UX.)
      debugPrint(
        '⚠️ REPO: Local cleanup failed AFTER remote success: ${ce.message}',
      );
    }

    debugPrint('✅ REPO: Trip ended successfully (remote-first)');
    return Right(remoteTrip);
  } on ServerException catch (e) {
    debugPrint('❌ REPO: Remote endTrip failed: ${e.message}');

    // ---------------------------------------------------
    // 3️⃣ REMOTE FAIL → OPTIONAL LOCAL FALLBACK (best effort)
    //    Only do local cleanup if you want app to proceed offline.
    //    If you prefer STRICT remote-first, remove this block.
    // ---------------------------------------------------
    try {
      debugPrint('📱 REPO: Remote failed → attempting local cleanup (offline fallback)');
      await _localDatasource.endTrip(safeTripId);
      debugPrint('✅ REPO: Local cleanup success (offline fallback)');

      // If you want: treat this as success offline:
      // return Right(TripEntity.empty());  // only if you have an empty factory
    } catch (e2) {
      debugPrint('⚠️ REPO: Local fallback cleanup also failed: $e2');
    }

    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } on CacheException catch (e) {
    // This only triggers if remote succeeded but local threw a CacheException
    // and you want to surface it as an error. (We already catch local above.)
    debugPrint('❌ REPO: Local cleanup failed: ${e.message}');
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}


 @override
ResultFuture<TripEntity> updateTripLocation(String tripId, double latitude, double longitude, {double? accuracy, String? source, double? totalDistance}) async {
  try {
    debugPrint('🔄 REPO: Updating trip location with distance tracking');
    debugPrint('📍 Coordinates: Lat: ${latitude.toStringAsFixed(6)}, Long: ${longitude.toStringAsFixed(6)}');
    debugPrint('🎯 Accuracy: ${accuracy?.toStringAsFixed(2) ?? 'Unknown'} meters');
    debugPrint('📡 Source: ${source ?? 'GPS'}');
    debugPrint('📏 Total Distance: ${totalDistance?.toStringAsFixed(3) ?? 'Unknown'} km');
    
    // Call the remote data source to update the trip location with distance info
    final updatedTrip = await _remoteDatasource.updateTripLocation(
      tripId, 
      latitude, 
      longitude,
      accuracy: accuracy,
      source: source,
      totalDistance: totalDistance,
    );
    
    debugPrint('✅ REPO: Trip location and distance updated successfully');
    return Right(updatedTrip );
  } on ServerException catch (e) {
    debugPrint('❌ REPO: Server error updating trip location: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } catch (e) {
    debugPrint('❌ REPO: Unexpected error updating trip location: $e');
    return Left(ServerFailure(
      message: 'Unexpected error updating trip location: $e',
      statusCode: '500',
    ));
  }
}

  @override
  ResultFuture<List<String>> checkTripPersonnels(String tripId) async {
    try {
      debugPrint('🔍 REPO: Checking trip personnels for ID: $tripId');
      final result = await _remoteDatasource.checkTripPersonnels(tripId);
      debugPrint('✅ REPO: Found ${result.length} personnels');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Failed to check trip personnels: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error checking trip personnels: $e');
      return Left(ServerFailure(
        message: 'Failed to check trip personnels: $e',
        statusCode: '500',
      ));
    }
  }

  @override
  ResultFuture<bool> setMismatchedReason(String tripId, String reasonCode) async {
    try {
      debugPrint('🔄 REPO: Setting mismatched personnel reason');
      debugPrint('   🎯 Trip ID: $tripId');
      debugPrint('   📋 Reason Code: $reasonCode');
      
      final result = await _remoteDatasource.setMismatchedReason(tripId, reasonCode);
      
      debugPrint('✅ REPO: Trip mismatch reason set successfully');
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('❌ REPO: Server error setting mismatch reason: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('❌ REPO: Unexpected error setting mismatch reason: $e');
      return Left(ServerFailure(message: 'Failed to set mismatch reason: $e', statusCode: '500'));
    }
  }

}
