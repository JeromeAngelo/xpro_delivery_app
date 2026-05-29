import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/datasources/remote_datasource/end_trip_otp_remote_impl/end_trip_otp_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin LoadEndTripOtpByIdImpl on EndTripOtpRemoteBase {
  Future<EndTripOtpModel> loadEndTripOtpById(String otpId) async {
    try {
      debugPrint('🔍 Loading End Trip OTP by ID: $otpId');

      final record = await pocketBaseClient
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
