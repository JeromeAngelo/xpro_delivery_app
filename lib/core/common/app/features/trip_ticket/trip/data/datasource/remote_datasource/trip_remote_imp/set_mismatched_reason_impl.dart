import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';

mixin SetMismatchedReasonImpl on TripRemoteBase {
  Future<bool> setMismatchedReason(String tripId, String reasonCode) async {
    try {
      debugPrint(
        '📝 REMOTE: Setting mismatched personnel reason for trip: $tripId',
      );
      debugPrint('   📋 Reason Code: $reasonCode');

      // Update the tripticket record with the chosen reason
      await pocketBaseClient
          .collection('tripticket')
          .update(
            tripId,
            body: {
              'mismatchedPersonnelReasonCode': reasonCode,
              'allowMismatchedPersonnels': false,
              'updated': DateTime.now().toIso8601String(),
            },
          );

      debugPrint('✅ REMOTE: Trip mismatch reason updated successfully');
      debugPrint('   🎯 Trip ID: $tripId');
      debugPrint('   📋 Reason Code: $reasonCode');
      debugPrint('   🚫 Allow Mismatched: false');

      return true;
    } catch (e) {
      debugPrint('❌ REMOTE: Error setting mismatched personnel reason: $e');
      throw ServerException(
        message: 'Failed to set mismatched personnel reason: $e',
        statusCode: '500',
      );
    }
  }
}
