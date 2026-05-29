import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/local_datasource/intransit_otp_local_impl/otp_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetOtpByIdImpl on OtpLocalBase {
  Future<OtpModel?> getOtpById(String id) async {
    try {
      debugPrint('📱 LOCAL: Fetching OTP by ID → $id');

      // -----------------------------------------------------
      // 1️⃣ Query OTP by PB ID
      // -----------------------------------------------------
      final query = otpBox.query(OtpModel_.id.equals(id)).build();
      final otp = query.findFirst();
      query.close();

      if (otp == null) {
        debugPrint('⚠️ OTP not found for ID: $id');
        return null;
      }

      debugPrint('🔐 OTP found → id=${otp.id}, code=${otp.otpCode}');

      // -----------------------------------------------------
      // 2️⃣ Load Trip relation (ToOne)
      // -----------------------------------------------------
      final tripRef = otp.trip.target;
      if (tripRef != null) {
        final fullTrip = tripBox.get(tripRef.objectBoxId);
        if (fullTrip != null) {
          otp.trip.target = fullTrip;
          otp.trip.targetId = fullTrip.objectBoxId;
          debugPrint('🚚 Trip loaded → ${fullTrip.name}');
        } else {
          debugPrint('⚠️ Trip reference exists but cannot load full Trip');
        }
      } else {
        debugPrint('ℹ️ OTP has no trip assigned');
      }

      debugPrint('✅ OTP fully loaded');
      return otp;
    } catch (e, st) {
      debugPrint('❌ getOtpById ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
