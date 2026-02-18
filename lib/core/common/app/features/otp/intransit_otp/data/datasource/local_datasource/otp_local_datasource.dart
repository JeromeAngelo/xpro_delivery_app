import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../services/objectbox.dart';
import '../../../../../trip_ticket/trip/data/models/trip_models.dart';
import '../../models/otp_models.dart';


abstract class OtpLocalDatasource {

    Future<OtpModel?> getOtpById(String id);

        Future<OtpModel?> getOtpByTripId(String tripId);


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
   Box<OtpModel> get otpBox => objectBoxStore.intransitOtpBox;
     Box<TripModel> get tripBox => objectBoxStore.tripBox;

  final ObjectBoxStore objectBoxStore;

  OtpLocalDatasourceImpl(this.objectBoxStore);
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

    // ✅ device local time (PH if device is PH)
    final now = DateTime.now();
    debugPrint('🕒 Device time now: ${now.toIso8601String()} (offset: ${now.timeZoneOffset})');

    final query = otpBox.query(OtpModel_.id.equals(otpId)).build();
    final otp = query.findFirst();
    query.close();

    if (otp != null && enteredOtp == otp.generatedCode) {
      otp.otpCode = enteredOtp;
      otp.isVerified = true;

      // ✅ save device local time
      otp.verifiedAt = now;

      otp.intransitOdometer = odometerReading;

      // ⚠️ NOTE: this looks wrong — you're overwriting OTP PB id with tripId
      // Keep original otp.id (ObjectBox internal/PB id). If you need tripId, store it in a trip field instead.
      // otp.id = tripId;

      otpBox.put(otp);

      debugPrint('✅ LOCAL: OTP verified and data saved');
      debugPrint('   • verifiedAt(local): ${otp.verifiedAt}');
      return true;
    }

    debugPrint('❌ LOCAL: OTP verification failed');
    return false;
  } catch (e) {
    debugPrint('❌ LOCAL: Verification error: $e');
    throw CacheException(message: e.toString());
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// ISO8601 WITH timezone offset (ex: 2026-02-09T11:20:00.123+08:00)
String isoDeviceNow() => _isoWithOffset(DateTime.now());

String _isoWithOffset(DateTime dt) {
  final local = dt; // device local
  final o = local.timeZoneOffset;
  final sign = o.isNegative ? '-' : '+';
  final hh = _two(o.inHours.abs());
  final mm = _two((o.inMinutes.abs()) % 60);

  // Dart local iso has no "+08:00" → append it
  return '${local.toIso8601String()}$sign$hh:$mm';
}

  @override
  Future<bool> verifyEndDeliveryOtp({
    required String enteredOtp,
    required String generatedOtp,
  }) async {
    try {
      debugPrint('📱 LOCAL: Verifying End-Delivery OTP');
      final otps = otpBox.getAll();
      
      if (otps.isNotEmpty) {
        final otp = otps.first;
        if (enteredOtp == otp.generatedCode) {
          otp.otpCode = enteredOtp;
          otp.isVerified = true;
          otp.verifiedAt = DateTime.now();
          otpBox.put(otp);
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
  @override
Future<OtpModel?> getOtpById(String id) async {
  try {
    debugPrint('📱 LOCAL: Fetching OTP by ID → $id');

    // -----------------------------------------------------
    // 1️⃣ Query OTP by PB ID
    // -----------------------------------------------------
    final query =
        otpBox.query(OtpModel_.id.equals(id)).build();
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


@override
Future<OtpModel?> getOtpByTripId(String tripId) async {
  try {
    debugPrint('📱 LOCAL: Fetching OTP by Trip ID → $tripId');

    // -----------------------------------------------------
    // 1️⃣ Find the Trip first (PB ID)
    // -----------------------------------------------------
    final tripQuery =
        tripBox.query(TripModel_.id.equals(tripId)).build();
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
