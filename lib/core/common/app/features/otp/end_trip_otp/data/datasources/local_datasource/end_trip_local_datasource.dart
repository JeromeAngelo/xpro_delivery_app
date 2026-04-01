import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../services/objectbox.dart';
import '../../../../../trip_ticket/trip/data/models/trip_models.dart';

abstract class EndTripOtpLocalDatasource {
  Future<EndTripOtpModel> getEndTripOtpById(String otpId);
  Future<EndTripOtpModel?> getEndTripOtpByTripId(String tripId);

  Future<void> cacheEndTripOtp(EndTripOtpModel otp);
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

class EndTripOtpLocalDatasourceImpl implements EndTripOtpLocalDatasource {
  Box<EndTripOtpModel> get endTripOtpBox => objectBoxStore.endTripOtpBox;
  final ObjectBoxStore objectBoxStore;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;

  EndTripOtpLocalDatasourceImpl(this.objectBoxStore);

  @override
  Future<EndTripOtpModel> getEndTripOtpById(String otpId) async {
    try {
      debugPrint('📱 LOCAL: Fetching End Trip OTP by ID: $otpId');
      final query =
          endTripOtpBox.query(EndTripOtpModel_.id.equals(otpId)).build();
      final otp = query.findFirst();
      query.close();

      if (otp != null) {
        debugPrint('✅ LOCAL: Found End Trip OTP record');
        return otp;
      }

      throw const CacheException(
        message: 'End Trip OTP not found',
        statusCode: 404,
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Error fetching End Trip OTP: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheEndTripOtp(EndTripOtpModel otp) async {
    try {
      debugPrint('💾 LOCAL: Caching End Trip OTP');
      endTripOtpBox.put(otp);
      debugPrint('✅ LOCAL: End Trip OTP cached successfully');
    } catch (e) {
      debugPrint('❌ LOCAL: Cache error: $e');
      throw CacheException(message: e.toString());
    }
  }

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
      debugPrint('🔐 LOCAL: Verifying End Trip OTP');
      final query =
          endTripOtpBox.query(EndTripOtpModel_.id.equals(otpId)).build();
      final otp = query.findFirst();
      query.close();

      if (otp != null && enteredOtp == otp.generatedCode) {
        otp.otpCode = enteredOtp;
        otp.isVerified = true;
        otp.verifiedAt = DateTime.now();
        otp.noOdometer = noOdometer;
        otp.endTripOdometer = noOdometer ? null : odometerReading;
        otp.trip.target?.id = tripId;

        endTripOtpBox.put(otp);
        debugPrint('✅ LOCAL: End Trip OTP verified and data saved');
        return true;
      }

      debugPrint('❌ LOCAL: End Trip OTP verification failed');
      return false;
    } catch (e) {
      debugPrint('❌ LOCAL: Verification error: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> verifyOdoStatus({
    required String id,
    required bool noOdometer,
  }) async {
    try {
      debugPrint('🔐 LOCAL: Updating End Trip OTP no-odometer status');
      final query = endTripOtpBox.query(EndTripOtpModel_.id.equals(id)).build();
      final otp = query.findFirst();
      query.close();

      if (otp != null) {
        otp.noOdometer = noOdometer;
        if (noOdometer) {
          otp.endTripOdometer = null;
        }
        endTripOtpBox.put(otp);
        debugPrint('✅ LOCAL: End Trip OTP no-odometer status saved');
        return true;
      }

      debugPrint('❌ LOCAL: End Trip OTP not found for no-odometer update');
      return false;
    } catch (e) {
      debugPrint('❌ LOCAL: verifyOdoStatus error: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<EndTripOtpModel?> getEndTripOtpByTripId(String tripId) async {
    try {
      debugPrint('📱 LOCAL: Fetching END TRIP OTP by Trip ID → $tripId');

      // -----------------------------------------------------
      // 1️⃣ Find the Trip first (PB ID)
      // -----------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint('⚠️ Trip not found for tripId: $tripId');
        return null;
      }

      // -----------------------------------------------------
      // 2️⃣ Find EndTripOtp linked to this Trip
      // -----------------------------------------------------
      final otpQuery =
          endTripOtpBox
              .query(EndTripOtpModel_.trip.equals(trip.objectBoxId))
              .build();

      final endTripOtp = otpQuery.findFirst();
      otpQuery.close();

      if (endTripOtp == null) {
        debugPrint('⚠️ No End Trip OTP found for trip: ${trip.name}');
        return null;
      }

      debugPrint(
        '🔐 End Trip OTP found → code=${endTripOtp.otpCode}, verified=${endTripOtp.isVerified}',
      );

      // -----------------------------------------------------
      // 3️⃣ Attach full Trip relation
      // -----------------------------------------------------
      endTripOtp.trip.target = trip;
      endTripOtp.trip.targetId = trip.objectBoxId;

      debugPrint('✅ End Trip OTP fully loaded with Trip relation');
      return endTripOtp;
    } catch (e, st) {
      debugPrint('❌ getEndTripOtpByTripId ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
