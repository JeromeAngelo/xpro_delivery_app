import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/local_datasource/end_trip_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/remote_datasource/end_trip_otp_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/domain/entity/end_trip_otp_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/domain/repo/end_trip_otp_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class EndTripOtpRepoImpl implements EndTripOtpRepo {
  const EndTripOtpRepoImpl(this._remoteDataSource, this._localDataSource);

  final EndTripOtpRemoteDataSource _remoteDataSource;
  final EndTripOtpLocalDatasource _localDataSource;

  @override
  ResultFuture<String> getEndGeneratedOtp() async {
    try {
      debugPrint('🔄 Fetching end trip OTP from remote');
      final remoteOtp = await _remoteDataSource.getEndGeneratedOtp();
      return Right(remoteOtp);
    } on ServerException catch (e) {
      debugPrint('❌ Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<EndTripOtpEntity> loadEndTripOtpByTripId(String tripId) async {
    try {
      debugPrint('📱 LOCAL FIRST: Loading EndTrip OTP for trip → $tripId');

      // -------------------------------------------------
      // 1️⃣ Try LOCAL first
      // -------------------------------------------------
      final localOtp = await _localDataSource.getEndTripOtpByTripId(tripId);

      if (localOtp != null) {
        debugPrint('✅ EndTrip OTP loaded from LOCAL DB');
        return Right(localOtp);
      }

      debugPrint('⚠️ No local EndTrip OTP found, fetching REMOTE...');
    } on CacheException catch (e) {
      debugPrint('⚠️ Local fetch failed: ${e.message}');
    }

    // -------------------------------------------------
    // 2️⃣ REMOTE fallback
    // -------------------------------------------------
    try {
      debugPrint('🌐 REMOTE: Fetching EndTrip OTP for trip → $tripId');

      final remoteOtp = await _remoteDataSource.loadEndTripOtpByTripId(tripId);

      // -------------------------------------------------
      // 3️⃣ Save to LOCAL
      // -------------------------------------------------
      // await _localDataSource.saveEndTripOtp(remoteOtp);

      debugPrint('💾 EndTrip OTP saved to LOCAL DB');
      return Right(remoteOtp);
    } on ServerException catch (e) {
      debugPrint('❌ Remote fetch failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<EndTripOtpEntity> loadEndTripOtpById(String otpId) async {
    try {
      debugPrint('🔄 Loading OTP by ID: $otpId');
      final remoteOtp = await _remoteDataSource.loadEndTripOtpById(otpId);
      return Right(remoteOtp);
    } on ServerException catch (e) {
      debugPrint('❌ Failed to load OTP: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> verifyEndTripOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
    bool noOdometer = false,
  }) async {
    try {
      debugPrint('🔐 Verifying end trip OTP');
      final remoteResult = await _remoteDataSource.verifyEndTripOtp(
        enteredOtp: enteredOtp,
        generatedOtp: generatedOtp,
        tripId: tripId,
        otpId: otpId,
        odometerReading: odometerReading,
        noOdometer: noOdometer,
      );

      if (remoteResult) {
        await _localDataSource.verifyEndTripOtp(
          enteredOtp: enteredOtp,
          generatedOtp: generatedOtp,
          tripId: tripId,
          otpId: otpId,
          odometerReading: odometerReading,
          noOdometer: noOdometer,
        );
      }

      return Right(remoteResult);
    } on ServerException catch (e) {
      debugPrint('❌ Remote verification failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      debugPrint('❌ Local cache update failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> verifyOdoStatus({
    required String id,
    required bool noOdometer,
  }) async {
    try {
      debugPrint('🔐 Verifying End Trip OTP no-odometer status');
      final remoteResult = await _remoteDataSource.verifyOdoStatus(
        id: id,
        noOdometer: noOdometer,
      );

      if (remoteResult) {
        await _localDataSource.verifyOdoStatus(id: id, noOdometer: noOdometer);
      }

      return Right(remoteResult);
    } on ServerException catch (e) {
      debugPrint('❌ Remote no-odometer update failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      debugPrint('❌ Local cache update failed: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
