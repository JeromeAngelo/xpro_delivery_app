import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';

mixin CheckEndTripOtpStatusImpl on TripRemoteBase {
  Future<bool> checkEndTripOtpStatus(String tripId) async {
    try {
      debugPrint('🔍 Checking end trip OTP status for trip: $tripId');

      final tripRecord = await pocketBaseClient
          .collection('tripticket')
          .getOne(tripId, expand: 'endTripOtp');

      final hasEndTripOtp = tripRecord.expand['endTripOtp'] != null;
      final isEndTrip = tripRecord.data['isEndTrip'] as bool? ?? false;

      debugPrint('📊 End Trip Status Check:');
      debugPrint('Has End Trip OTP: $hasEndTripOtp');
      debugPrint('Is End Trip: $isEndTrip');

      return hasEndTripOtp && isEndTrip;
    } catch (e) {
      debugPrint('❌ Error checking end trip OTP status: $e');
      throw ServerException(
        message: 'Failed to check end trip OTP status: $e',
        statusCode: '500',
      );
    }
  }
}
