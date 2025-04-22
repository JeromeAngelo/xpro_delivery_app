import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/enums/otp_type.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class OtpRemoteDataSource {
  Future<bool> verifyInTransitOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
  });

  Future<bool> verifyEndDeliveryOtp({
    required String enteredOtp,
    required String generatedOtp,
  });

  Future<String> getGeneratedOtp();

  Future<OtpModel> loadOtpByTripId(String tripId);

  Future<OtpModel> loadOtpById(String otpId);
}

class OtpRemoteDataSourceImpl implements OtpRemoteDataSource {
  const OtpRemoteDataSourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  @override
  Future<bool> verifyInTransitOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
  }) async {
    try {
      debugPrint('🔍 Verifying In-Transit OTP...');
      debugPrint('Trip ID: $tripId');
      debugPrint('OTP ID: $otpId');
      debugPrint('Odometer Reading: $odometerReading');

      final otpRecord = await _pocketBaseClient.collection('otp').getOne(otpId);
      final backendGeneratedCode = otpRecord.data['generatedCode'] as String;
      debugPrint('Backend Generated Code: $backendGeneratedCode');

      if (enteredOtp == backendGeneratedCode) {
        await _pocketBaseClient.collection('otp').update(
          otpId,
          body: {
            'otpCode': enteredOtp,
            'isVerified': true,
            'verifiedAt': DateTime.now().toIso8601String(),
            'otpType': 'inTransit',
            'trip': tripId,
            'intransitOdometer': odometerReading,
          },
        );

        debugPrint('✅ OTP verified and odometer reading saved successfully');
        return true;
      }

      debugPrint('❌ OTP verification failed: Code mismatch');
      return false;
    } catch (e) {
      debugPrint('❌ Verification error: ${e.toString()}');
      throw ServerException(
        message: 'Failed to verify OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<OtpModel> loadOtpById(String otpId) async {
    try {
      debugPrint('🔍 Loading OTP by ID: $otpId');

      // Add delay between requests
      await Future.delayed(const Duration(milliseconds: 500));

      final record = await _pocketBaseClient.collection('otp').getOne(
            otpId,
            expand: 'trip',
          );

      debugPrint('✅ Found OTP record: ${record.id}');
      debugPrint('📄 Full OTP Data: ${record.data}');

      return OtpModel(
        id: record.id,
        generatedCode: record.data['generatedCode'],
        otpCode: record.data['otpCode'],
        isVerified: record.data['isVerified'] ?? false,
        verifiedAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)).toUtc(),
        otpType: record.data['otpType']?.toString().isNotEmpty == true
            ? OtpType.values.firstWhere(
                (type) =>
                    type.toString() == 'OtpType.${record.data['otpType']}',
                orElse: () => OtpType.inTransit,
              )
            : OtpType.inTransit,
        trip: TripModel(id: record.data['trip']),
        intransitOdometer: record.data['intransitOdometer'],
      );
    } catch (e) {
      if (e.toString().contains('429')) {
        debugPrint('⚠️ Rate limit hit, retrying after delay...');
        await Future.delayed(const Duration(seconds: 2));
        return loadOtpById(otpId);
      }
      debugPrint('❌ Failed to load OTP by ID: $e');
      throw ServerException(
        message: 'Failed to load OTP by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> verifyEndDeliveryOtp({
    required String enteredOtp,
    required String generatedOtp,
  }) async {
    try {
      debugPrint('🔍 Verifying End-Delivery OTP...');
      debugPrint('Entered OTP: $enteredOtp');
      debugPrint('Generated OTP: $generatedOtp');

      final otpRecords =
          await _pocketBaseClient.collection('otp').getFullList();

      if (otpRecords.isNotEmpty) {
        final record = otpRecords.first;
        final backendGeneratedCode = record.data['generatedCode'] as String;

        if (enteredOtp == backendGeneratedCode) {
          await _pocketBaseClient.collection('otp').update(
            record.id,
            body: {
              'otpCode': enteredOtp,
            },
          );
          debugPrint('✅ End-Delivery OTP verification successful!');
          return true;
        }
      }
      debugPrint('❌ End-Delivery OTP verification failed: OTP mismatch');
      return false;
    } catch (e) {
      debugPrint('❌ End-Delivery OTP verification error: ${e.toString()}');
      throw ServerException(
        message: 'Failed to verify end-delivery OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<String> getGeneratedOtp() async {
    try {
      final otpRecords =
          await _pocketBaseClient.collection('otp').getFullList();
      if (otpRecords.isNotEmpty) {
        final generatedCode = otpRecords.first.data['generatedCode'];
        if (generatedCode != null) {
          return generatedCode.toString();
        }
        throw const ServerException(
          message: 'Generated OTP code is null',
          statusCode: '404',
        );
      }
      throw const ServerException(
        message: 'No OTP records found',
        statusCode: '404',
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to get OTP: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<OtpModel> loadOtpByTripId(String tripId) async {
    try {
      debugPrint('🔍 Starting OTP load process for trip: $tripId');

      // Get stored user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');
      debugPrint('📦 Raw stored user data: $storedUserData');

      if (storedUserData == null) {
        throw const ServerException(
          message: 'No stored user data found',
          statusCode: '404',
        );
      }

      final userData = jsonDecode(storedUserData);
      debugPrint('🔄 Parsed user data: $userData');

      // Direct query using provided trip ID
      debugPrint('🎯 Using direct trip ID on OTP: $tripId');
      final otpRecords = await _pocketBaseClient.collection('otp').getFullList(
            expand: 'trip',
            filter: 'trip = "$tripId"',
          );

      if (otpRecords.isEmpty) {
        debugPrint('⚠️ No OTP records found');
        throw const ServerException(
          message: 'No OTP found for this trip',
          statusCode: '404',
        );
      }

      final record = otpRecords.first;
      debugPrint('✅ Found OTP record ID: ${record.id}');
      debugPrint('📄 OTP Data: ${record.data}');

      return OtpModel(
        id: record.id,
        generatedCode: record.data['generatedCode'],
        otpCode: record.data['otpCode'],
        isVerified: record.data['isVerified'] ?? false,
        verifiedAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
        otpType: record.data['otpType']?.toString().isNotEmpty == true
            ? OtpType.values.firstWhere(
                (type) =>
                    type.toString() == 'OtpType.${record.data['otpType']}',
                orElse: () => OtpType.inTransit,
              )
            : OtpType.inTransit,
        trip: TripModel(id: tripId),
        intransitOdometer: record.data['intransitOdometer'],
      );
    } catch (e) {
      debugPrint('❌ Error in loadOtpByTripId: $e');
      throw ServerException(
        message: 'Failed to load OTP by trip id: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
