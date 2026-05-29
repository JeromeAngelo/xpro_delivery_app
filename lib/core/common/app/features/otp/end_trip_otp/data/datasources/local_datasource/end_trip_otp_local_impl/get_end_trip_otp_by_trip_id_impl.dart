import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/local_datasource/end_trip_otp_local_impl/end_trip_otp_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin GetEndTripOtpByTripIdImpl on EndTripOtpLocalBase {
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
