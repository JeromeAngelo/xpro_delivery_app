import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../model/end_trip_model.dart';

abstract class EndTripOtpRemoteDataSource {
  Future<String> getEndGeneratedOtp();
  Future<EndTripOtpModel> loadEndTripOtpByTripId(String tripId);
  Future<EndTripOtpModel> loadEndTripOtpById(String otpId);
  Future<bool> verifyEndTripOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
    bool noOdometer = false,
  });

  Future<bool> verifyOdoStatus({required String id, required bool noOdometer});
}

class EndTripOtpRemoteDataSourceImpl implements EndTripOtpRemoteDataSource {
  const EndTripOtpRemoteDataSourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<bool> verifyEndTripOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
    bool noOdometer = false,
  }) async {
    try {
      debugPrint('🔍 Verifying End-Trip OTP...');
      debugPrint('Entered OTP: $enteredOtp');
      debugPrint('Generated OTP: $generatedOtp');
      debugPrint('Trip ID: $tripId');
      debugPrint('OTP ID: $otpId');
      debugPrint('Odometer Reading: $odometerReading');

      final otpRecord = await _pocketBaseClient
          .collection('endTripOtp')
          .getOne(otpId);
      final backendGeneratedCode = otpRecord.data['generatedCode'] as String;
      debugPrint('Backend Generated Code: $backendGeneratedCode');

      if (enteredOtp == backendGeneratedCode) {
        final updateBody = {
          'otpCode': enteredOtp,
          'isVerified': true,
          'verifiedAt': DateTime.now().toIso8601String(),
          'otpType': 'endDelivery',
          'trip': tripId,
          if (noOdometer) 'noOdometer': true,
          if (noOdometer) 'endTripOdometer': null,
          if (!noOdometer) 'endTripOdometer': odometerReading,
        };

        await _pocketBaseClient
            .collection('endTripOtp')
            .update(otpId, body: updateBody);

        await _pocketBaseClient
            .collection('tripticket')
            .update(
              tripId,
              body: {
                'endTripOtp': otpId,
                'isEndTrip': true,
                'timeEndTrip': DateTime.now().toUtc().toIso8601String(),
                'isAccepted': false,
              },
            );

        final currentUser = _pocketBaseClient.authStore.model;
        if (currentUser != null) {
          debugPrint('🔄 Clearing trip assignment for user: ${currentUser.id}');
          await _pocketBaseClient
              .collection('users')
              .update(currentUser.id, body: {'tripNumberId': null});
          debugPrint('✅ User trip assignment cleared');
        }

        debugPrint('✅ End Trip OTP verified successfully');
        return true;
      }

      debugPrint('❌ End Trip OTP verification failed: Code mismatch');
      return false;
    } catch (e) {
      debugPrint('❌ End Trip OTP verification error: ${e.toString()}');
      throw ServerException(
        message: 'Failed to verify End Trip OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> verifyOdoStatus({
    required String id,
    required bool noOdometer,
  }) async {
    try {
      debugPrint('🔍 Updating End Trip OTP no-odometer status...');
      debugPrint('OTP ID: $id');
      debugPrint('noOdometer: $noOdometer');

      await _pocketBaseClient
          .collection('endTripOtp')
          .update(
            id,
            body: {
              'noOdometer': noOdometer,
              if (noOdometer) 'endTripOdometer': null,
            },
          );

      debugPrint('✅ End Trip OTP no-odometer status updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ End Trip OTP no-odometer update error: ${e.toString()}');
      throw ServerException(
        message:
            'Failed to update End Trip OTP no-odometer status: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<String> getEndGeneratedOtp() async {
    try {
      final otpRecords =
          await _pocketBaseClient.collection('endTripOtp').getFullList();

      if (otpRecords.isNotEmpty) {
        final generatedCode = otpRecords.first.data['generatedCode'];
        if (generatedCode != null) {
          return generatedCode.toString();
        }
        throw const ServerException(
          message: 'Generated End Trip OTP code is null',
          statusCode: '404',
        );
      }
      throw const ServerException(
        message: 'No End Trip OTP records found',
        statusCode: '404',
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to get End Trip OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<EndTripOtpModel> loadEndTripOtpByTripId(String tripId) async {
    try {
      debugPrint('🔍 Loading End Trip OTP for trip: $tripId');

      final otpRecords = await _pocketBaseClient
          .collection('endTripOtp')
          .getFullList(expand: 'trip', filter: 'trip = "$tripId"');

      if (otpRecords.isEmpty) {
        throw const ServerException(
          message: 'No End Trip OTP found for this trip',
          statusCode: '404',
        );
      }

      final record = otpRecords.first;
      debugPrint('✅ Found End Trip OTP record: ${record.id}');

      return EndTripOtpModel(
        id: record.id,
        generatedCode: record.data['generatedCode'],
        otpCode: record.data['otpCode'],
        isVerified: record.data['isVerified'] ?? false,
        verifiedAt: DateTime.tryParse(record.data['verifiedAt'] ?? ''),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        trip: TripModel(id: tripId),
        endTripOdometer: record.data['endTripOdometer'],
      );
    } catch (e) {
      debugPrint('❌ Error loading End Trip OTP: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load End Trip OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<EndTripOtpModel> loadEndTripOtpById(String otpId) async {
    try {
      debugPrint('🔍 Loading End Trip OTP by ID: $otpId');

      final record = await _pocketBaseClient
          .collection('endTripOtp')
          .getOne(otpId, expand: 'trip');

      return EndTripOtpModel(
        id: record.id,
        generatedCode: record.data['generatedCode'],
        otpCode: record.data['otpCode'],
        isVerified: record.data['isVerified'] ?? false,
        verifiedAt: DateTime.tryParse(record.data['verifiedAt'] ?? ''),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        trip: TripModel(id: record.data['trip']),
        endTripOdometer: record.data['endTripOdometer'],
      );
    } catch (e) {
      debugPrint('❌ Error loading End Trip OTP by ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load End Trip OTP by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
