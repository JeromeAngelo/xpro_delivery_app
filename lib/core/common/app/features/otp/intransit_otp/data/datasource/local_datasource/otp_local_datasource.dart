import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../models/otp_models.dart';


abstract class OtpLocalDatasource {
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
}

class OtpLocalDatasourceImpl implements OtpLocalDatasource {
  final Box<OtpModel> _otpBox;

  OtpLocalDatasourceImpl(this._otpBox);

  @override
  Future<bool> verifyInTransitOtp({
    required String enteredOtp,
    required String generatedOtp,
    required String tripId,
    required String otpId,
    required String odometerReading,
  }) async {
    try {
      debugPrint('📱 LOCAL: Verifying In-Transit OTP');
      final query = _otpBox.query(OtpModel_.id.equals(otpId)).build();
      final otp = query.findFirst();
      query.close();

      if (otp != null && enteredOtp == otp.generatedCode) {
        otp.otpCode = enteredOtp;
        otp.isVerified = true;
        otp.verifiedAt = DateTime.now();
        otp.intransitOdometer = odometerReading;
        otp.id = tripId;
        
        _otpBox.put(otp);
        debugPrint('✅ LOCAL: OTP verified and data saved');
        return true;
      }

      debugPrint('❌ LOCAL: OTP verification failed');
      return false;
    } catch (e) {
      debugPrint('❌ LOCAL: Verification error: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> verifyEndDeliveryOtp({
    required String enteredOtp,
    required String generatedOtp,
  }) async {
    try {
      debugPrint('📱 LOCAL: Verifying End-Delivery OTP');
      final otps = _otpBox.getAll();
      
      if (otps.isNotEmpty) {
        final otp = otps.first;
        if (enteredOtp == otp.generatedCode) {
          otp.otpCode = enteredOtp;
          otp.isVerified = true;
          otp.verifiedAt = DateTime.now();
          _otpBox.put(otp);
          debugPrint('✅ LOCAL: End-Delivery OTP verified');
          return true;
        }
      }
      
      debugPrint('❌ LOCAL: End-Delivery OTP verification failed');
      return false;
    } catch (e) {
      debugPrint('❌ LOCAL: End-Delivery verification error: $e');
      throw CacheException(message: e.toString());
    }
  }
}
