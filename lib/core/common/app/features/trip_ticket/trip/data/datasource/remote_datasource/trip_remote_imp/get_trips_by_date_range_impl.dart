import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';

mixin GetTripsByDateRangeImpl on TripRemoteBase {
  Future<List<TripModel>> getTripsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint(
        '📅 Fetching trips between ${startDate.toIso8601String()} and ${endDate.toIso8601String()}',
      );

      final records = await pocketBaseClient
          .collection('tripticket')
          .getFullList(
            filter:
                'created >= "${startDate.toIso8601String()}" && created <= "${endDate.toIso8601String()}"',
            expand: 'customers,timeline,personels,vehicle,checklist',
          );

      return records
          .map((record) => TripModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      debugPrint('❌ Date range fetch error: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch trips by date range: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
