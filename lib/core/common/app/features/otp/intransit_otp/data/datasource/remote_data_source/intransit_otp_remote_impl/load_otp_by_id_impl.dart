import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/otp_type.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/intransit_otp/data/datasource/remote_data_source/intransit_otp_remote_impl/otp_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import '../../../models/otp_models.dart';

mixin LoadOtpByIdImpl on OtpRemoteBase {
  Future<OtpModel> loadOtpById(String otpId) async {
    try {
      debugPrint('🔍 Loading OTP by ID: $otpId');

      // Add delay between requests
      await Future.delayed(const Duration(milliseconds: 500));

      final record = await pocketBaseClient
          .collection('otp')
          .getOne(otpId, expand: 'trip');

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
        otpType:
            record.data['otpType']?.toString().isNotEmpty == true
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
}
