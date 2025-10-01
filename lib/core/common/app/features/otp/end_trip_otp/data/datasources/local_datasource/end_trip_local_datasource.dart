import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
abstract class EndTripOtpLocalDatasource {
  Future<EndTripOtpModel> getEndTripOtpById(String otpId);
  Future<void> cacheEndTripOtp(EndTripOtpModel otp);
  Future<bool> verifyEndTripOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
  });
}

class EndTripOtpLocalDatasourceImpl implements EndTripOtpLocalDatasource {
  final Box<EndTripOtpModel> _endTripOtpBox;

  EndTripOtpLocalDatasourceImpl(this._endTripOtpBox);

 

  @override
  Future<EndTripOtpModel> getEndTripOtpById(String otpId) async {
    try {
      debugPrint('📱 LOCAL: Fetching End Trip OTP by ID: $otpId');
      final query = _endTripOtpBox.query(EndTripOtpModel_.id.equals(otpId)).build();
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
      _endTripOtpBox.put(otp);
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
  }) async {
    try {
      debugPrint('🔐 LOCAL: Verifying End Trip OTP');
      final query = _endTripOtpBox.query(EndTripOtpModel_.id.equals(otpId)).build();
      final otp = query.findFirst();
      query.close();

      if (otp != null && enteredOtp == otp.generatedCode) {
        otp.otpCode = enteredOtp;
        otp.isVerified = true;
        otp.verifiedAt = DateTime.now();
        otp.endTripOdometer = odometerReading;
        otp.trip.target?.id = tripId;
        
        _endTripOtpBox.put(otp);
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
}
