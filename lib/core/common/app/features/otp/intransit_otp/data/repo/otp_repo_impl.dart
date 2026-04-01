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
    bool noOdometer = false,
  }) async {
    try {
      final remoteResult = await _remoteDataSource.verifyInTransitOtp(
        enteredOtp: enteredOtp,
        generatedOtp: generatedOtp,
        tripId: tripId,
        otpId: otpId,
        odometerReading: odometerReading,
        noOdometer: noOdometer,
      );

      await _localDataSource.verifyInTransitOtp(
        enteredOtp: enteredOtp,
        generatedOtp: generatedOtp,
        tripId: tripId,
        otpId: otpId,
        odometerReading: odometerReading,
        noOdometer: noOdometer,
      );

      return Right(remoteResult);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
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
  ResultFuture<bool> verifyOdoStatus({
    required String id,
    required bool noOdometer,
  }) async {
    try {
      final remoteResult = await _remoteDataSource.verifyOdoStatus(
        id: id,
        noOdometer: noOdometer,
      );

      await _localDataSource.verifyOdoStatus(id: id, noOdometer: noOdometer);

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
      debugPrint('🔄 Loading OTP data for trip: $tripId');
      final remoteOtp = await _remoteDataSource.loadOtpByTripId(tripId);
      debugPrint('✅ OTP data loaded successfully');
      return Right(remoteOtp);
    } on ServerException catch (e) {
      debugPrint('❌ Failed to load OTP: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<OtpEntity> loadOtpById(String otpId) async {
    try {
      debugPrint('🔄 Loading OTP data for id: $otpId');
      final remoteOtp = await _remoteDataSource.loadOtpById(otpId);
      return Right(remoteOtp);
    } on ServerException catch (e) {
      debugPrint('❌ Failed to load OTP: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
