import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';

mixin SearchTripByNumberImpl on TripRemoteBase {
  Future<TripModel> searchTripByNumber(String tripNumberId) async {
    try {
      debugPrint('🔍 REMOTE: Searching for trip number: $tripNumberId');

      final records = await pocketBaseClient
          .collection('tripticket')
          .getFullList(
            filter:
                'tripNumberId = "$tripNumberId" && isAccepted = false && isEndTrip = false',
            expand:
                'timeline,personels,vehicle,checklist,deliveryData,deliveryVehicle',
          );

      if (records.isEmpty) {
        throw ServerException(
          message: 'Trip number $tripNumberId not found or already assigned',
          statusCode: '404',
        );
      }

      final record = records.first;

      // Enhanced safe date parsing function with multiple fallbacks
      DateTime? parseDate(dynamic value) {
        if (value == null) return null;

        String strValue = value.toString().trim();
        if (strValue.isEmpty) return null;

        try {
          // Try standard ISO format first
          return DateTime.parse(strValue);
        } catch (e) {
          debugPrint(
            '⚠️ Standard date parsing failed: $e for value: $strValue',
          );

          try {
            // Try Unix timestamp (milliseconds)
            if (strValue.length >= 10 && RegExp(r'^\d+$').hasMatch(strValue)) {
              int timestamp = int.parse(strValue);
              // If it's in seconds (10 digits), convert to milliseconds
              if (strValue.length == 10) {
                timestamp *= 1000;
              }
              return DateTime.fromMillisecondsSinceEpoch(timestamp);
            }

            // Try various date formats
            final formats = [
              // Add more formats as needed
              RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'), // MM/DD/YYYY
              RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$'), // YYYY-MM-DD
              RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$'), // DD-MM-YYYY
            ];

            for (var format in formats) {
              if (format.hasMatch(strValue)) {
                var match = format.firstMatch(strValue)!;
                if (format.pattern == r'^(\d{1,2})/(\d{1,2})/(\d{4})$') {
                  // MM/DD/YYYY
                  return DateTime(
                    int.parse(match.group(3)!),
                    int.parse(match.group(1)!),
                    int.parse(match.group(2)!),
                  );
                } else if (format.pattern == r'^(\d{4})-(\d{1,2})-(\d{1,2})$') {
                  // YYYY-MM-DD
                  return DateTime(
                    int.parse(match.group(1)!),
                    int.parse(match.group(2)!),
                    int.parse(match.group(3)!),
                  );
                } else if (format.pattern == r'^(\d{1,2})-(\d{1,2})-(\d{4})$') {
                  // DD-MM-YYYY
                  return DateTime(
                    int.parse(match.group(3)!),
                    int.parse(match.group(2)!),
                    int.parse(match.group(1)!),
                  );
                }
              }
            }

            // If all else fails, return current time
            debugPrint(
              '⚠️ All date parsing attempts failed for: $strValue, using current time',
            );
            return DateTime.now();
          } catch (e2) {
            debugPrint(
              '⚠️ Alternative date parsing failed: $e2 for value: $strValue',
            );
            return null;
          }
        }
      }

      // Safely extract data from the record
      Map<String, dynamic> extractData() {
        try {
          final data = {
            'id': record.id,
            'collectionId': record.collectionId,
            'collectionName': record.collectionName,
            ...Map<String, dynamic>.from(record.data),
          };

          // Ensure boolean fields are properly set
          data['isAccepted'] = record.data['isAccepted'] == true;
          data['isEndTrip'] = record.data['isEndTrip'] == true;

          // Handle date fields
          data['timeAccepted'] = parseDate(record.data['timeAccepted']);
          data['created'] = parseDate(record.data['created']);
          data['updated'] = parseDate(record.data['updated']);
          data['timeEndTrip'] = parseDate(record.data['timeEndTrip']);

          // Handle relations
          if (record.expand.containsKey('personels') &&
              record.expand['personels'] != null) {
            data['personels'] = mapPersonels(record);
          }

          if (record.expand.containsKey('checklist') &&
              record.expand['checklist'] != null) {
            data['checklist'] = mapChecklist(record);
          }

          // Handle deliveryData if available
          if (record.expand.containsKey('deliveryData') &&
              record.expand['deliveryData'] != null) {
            data['deliveryData'] = mapDeliveryData(record);
          }

          // Handle deliveryVehicle if available
          data['deliveryVehicle'] = record.expand['deliveryVehicle'] != null;

          return data;
        } catch (e) {
          debugPrint('⚠️ Error extracting data: $e');
          // Return minimal valid data to avoid further errors
          return {
            'id': record.id,
            'collectionId': record.collectionId,
            'collectionName': record.collectionName,
            'tripNumberId': record.data['tripNumberId'],
            'isAccepted': false,
            'isEndTrip': false,
          };
        }
      }

      final mappedData = extractData();

      debugPrint('✅ REMOTE: Trip found and mapped successfully');
      debugPrint('   🎫 Trip Number: ${record.data['tripNumberId']}');
      debugPrint('   👥 Customers: ${record.expand['customers']?.length ?? 0}');
      debugPrint('   👤 Personnel: ${record.expand['personels']?.length ?? 0}');
      debugPrint(
        '   🚛 Vehicle: ${record.expand['vehicle'] != null ? 'Assigned' : 'None'}',
      );

      return TripModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ REMOTE: Search error: $e');
      throw ServerException(
        message: 'Trip: Error searching trip: $e',
        statusCode: '500',
      );
    }
  }
}
