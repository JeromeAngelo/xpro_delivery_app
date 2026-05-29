import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/local_datasource/intransit_otp_local_impl/otp_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetOtpByTripIdImpl on OtpLocalBase {
  Future<OtpModel?> getOtpByTripId(String tripId) async {
    try {
      debugPrint('📱 LOCAL: Fetching OTP by Trip ID → $tripId');

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
      // 2️⃣ Find OTP linked to this Trip
      // -----------------------------------------------------
      final otpQuery =
          otpBox.query(OtpModel_.trip.equals(trip.objectBoxId)).build();
      final otp = otpQuery.findFirst();
      otpQuery.close();

      if (otp == null) {
        debugPrint('⚠️ No OTP found for trip: ${trip.name}');
        return null;
      }

      debugPrint(
        '🔐 OTP found for trip → code=${otp.otpCode}, verified=${otp.isVerified}',
      );

      // -----------------------------------------------------
      // 3️⃣ Attach full Trip relation
      // -----------------------------------------------------
      otp.trip.target = trip;
      otp.trip.targetId = trip.objectBoxId;

      debugPrint('✅ OTP fully loaded with Trip relation');
      return otp;
    } catch (e, st) {
      debugPrint('❌ getOtpByTripId ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
