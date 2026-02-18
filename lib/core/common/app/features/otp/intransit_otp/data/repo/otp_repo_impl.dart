import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/local_datasource/otp_local_datasource.dart'
    show OtpLocalDatasource;
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/domain/entity/otp_entity.dart'
    show OtpEntity;

import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../../domain/repo/otp_repo.dart';
import '../datasource/remote_data_source/otp_remote_datasource.dart';

class OtpRepoImpl implements OtpRepo {
  const OtpRepoImpl(this._remoteDataSource, this._localDataSource);

  final OtpRemoteDataSource _remoteDataSource;
  final OtpLocalDatasource _localDataSource;

  @override
  ResultFuture<String> getGeneratedOtp() async {
    try {
      final remoteOtp = await _remoteDataSource.getGeneratedOtp();
      return Right(remoteOtp);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> verifyInTransitOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
  }) async {
    try {
      debugPrint('🔁 REPO: Verifying In-Transit OTP (offline first)');
      debugPrint('   🆔 tripId=$tripId | otpId=$otpId');

      // -------------------------------------------------
      // 1️⃣ LOCAL FIRST
      // -------------------------------------------------
      try {
        await _localDataSource.verifyInTransitOtp(
          enteredOtp: enteredOtp,
          generatedOtp: generatedOtp,
          tripId: tripId,
          otpId: otpId,
          odometerReading: odometerReading,
        );

        debugPrint('✅ LOCAL OTP verification successful');
      } on CacheException catch (e) {
        // ⚠️ Do NOT stop flow — still try remote
        debugPrint('⚠️ LOCAL OTP verification failed: ${e.message}');
      }

      // -------------------------------------------------
      // 2️⃣ REMOTE SECOND
      // -------------------------------------------------
      debugPrint('🌐 Calling REMOTE OTP verification...');
      final remoteResult = await _remoteDataSource.verifyInTransitOtp(
        enteredOtp: enteredOtp,
        generatedOtp: generatedOtp,
        tripId: tripId,
        otpId: otpId,
        odometerReading: odometerReading,
      );

      debugPrint('✅ REMOTE OTP verification successful');

      return Right(remoteResult);
    } on ServerException catch (e) {
      debugPrint('❌ REMOTE OTP verification failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      debugPrint('❌ LOCAL OTP verification fatal error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<bool> verifyEndDeliveryOtp({
    required String enteredOtp,
    required String generatedOtp,
  }) async {
    try {
      final remoteResult = await _remoteDataSource.verifyEndDeliveryOtp(
        enteredOtp: enteredOtp,
        generatedOtp: generatedOtp,
      );

      await _localDataSource.verifyEndDeliveryOtp(
        enteredOtp: enteredOtp,
        generatedOtp: generatedOtp,
      );

      return Right(remoteResult);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
@override
ResultFuture<OtpEntity> loadOtpByTripId(String tripId) async {
  try {
    debugPrint('📱 LOCAL FIRST: Loading OTP for trip → $tripId');

    // -------------------------------------------------
    // 1️⃣ Try LOCAL first
    // -------------------------------------------------
    final localOtp = await _localDataSource.getOtpByTripId(tripId);

    if (localOtp != null) {
      debugPrint('✅ OTP loaded from LOCAL DB');
      return Right(localOtp);
    }

    debugPrint('⚠️ No local OTP found, fetching REMOTE...');
  } on CacheException catch (e) {
    debugPrint('⚠️ Local fetch failed: ${e.message}');
  }

  // -------------------------------------------------
  // 2️⃣ REMOTE fallback
  // -------------------------------------------------
  try {
    debugPrint('🌐 REMOTE: Fetching OTP for trip → $tripId');

    final remoteOtp = await _remoteDataSource.loadOtpByTripId(tripId);

    // -------------------------------------------------
    // 3️⃣ Save to LOCAL (optional, uncomment if you have it)
    // -------------------------------------------------
    // await _localDataSource.saveOtp(remoteOtp);
    // debugPrint('💾 OTP saved to LOCAL DB');

    return Right(remoteOtp);
  } on ServerException catch (e) {
    debugPrint('❌ Remote fetch failed: ${e.message}');
    return Left(
      ServerFailure(message: e.message, statusCode: e.statusCode),
    );
  } on CacheException catch (e) {
    debugPrint('❌ Local save failed: ${e.message}');
    return Left(
      CacheFailure(message: e.message, statusCode: e.statusCode),
    );
  }
}


  @override
  ResultFuture<OtpEntity> loadOtpById(String otpId) async {
    try {
      debugPrint('🔄 Loading OTP data for trip: $otpId');
      final remoteOtp = await _remoteDataSource.loadOtpById(otpId);
      return Right(remoteOtp);
    } on ServerException catch (e) {
      debugPrint('❌ Failed to load OTP: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
