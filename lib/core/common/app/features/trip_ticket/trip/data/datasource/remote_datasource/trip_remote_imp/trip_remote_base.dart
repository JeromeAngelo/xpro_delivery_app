import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_datasource/trip_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

import '../../../../../../delivery_team/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import '../../../../../../otp/end_trip_otp/data/model/end_trip_model.dart';
import '../../../../../../otp/intransit_otp/data/models/otp_models.dart';

/// Base class that holds the shared PocketBase client, local datasource,
/// and all private helper methods (now public) used across trip remote
/// data source implementations.
class TripRemoteBase {
  final PocketBase pocketBaseClient;
  final TripLocalDatasource tripLocalDatasource;

  TripRemoteBase({
    required this.pocketBaseClient,
    required this.tripLocalDatasource,
  });

  // ---------------------------------------------------------------------------
  // Helper: map expanded record
  // ---------------------------------------------------------------------------
  dynamic mapExpandedRecord(dynamic record) {
    if (record == null) return null;

    if (record is List) {
      if (record.isEmpty) return [];

      return record.map((r) {
        if (r is RecordModel) {
          final dataMap = Map<String, dynamic>.from(r.data);
          // Ensure 'name' exists
          if (!dataMap.containsKey('name')) {
            dataMap['name'] = r.data['name'] ?? r.id; // fallback to ID
          }
          return {
            'id': r.id,
            'collectionId': r.collectionId,
            'collectionName': r.collectionName,
            'created': formatDateField(r.created),
            'updated': formatDateField(r.updated),
            ...dataMap,
          };
        }

        if (r is Map<String, dynamic>) return r;

        return {'value': r};
      }).toList();
    }

    if (record is RecordModel) {
      final dataMap = Map<String, dynamic>.from(record.data);
      if (!dataMap.containsKey('name')) {
        dataMap['name'] = record.data['name'] ?? record.id;
      }
      return {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'created': formatDateField(record.created),
        'updated': formatDateField(record.updated),
        ...dataMap,
      };
    }

    if (record is Map<String, dynamic>) return record;

    return null;
  }

  // ---------------------------------------------------------------------------
  // Helper: safely format date fields
  // ---------------------------------------------------------------------------
  String? formatDateField(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      // Directly return ISO8601 if valid string
      if (dateValue is String) {
        // Attempt ISO 8601 parse
        try {
          final parsed = DateTime.parse(dateValue);
          return parsed.toIso8601String();
        } catch (_) {
          // continue trying other formats below
        }

        // Try common non-ISO date formats
        final possibleFormats = [
          'yyyy-MM-dd HH:mm:ss',
          'yyyy/MM/dd HH:mm:ss',
          'yyyy-MM-dd',
          'yyyy/MM/dd',
          'MM/dd/yyyy',
          'MM-dd-yyyy',
          'dd/MM/yyyy',
          'dd-MM-yyyy',
          'dd MMM yyyy',
          'MMM dd, yyyy',
        ];

        for (final format in possibleFormats) {
          try {
            final parsed = DateFormat(format).parse(dateValue, true);
            return parsed.toIso8601String();
          } catch (_) {}
        }

        // Try parsing numeric string as timestamp
        final numeric = int.tryParse(dateValue);
        if (numeric != null) {
          return timestampToIso(numeric);
        }

        debugPrint('⚠️ Unrecognized date string format: $dateValue');
        return null;
      }

      // If DateTime → ISO string
      if (dateValue is DateTime) {
        return dateValue.toIso8601String();
      }

      // If numeric timestamp (milliseconds or seconds)
      if (dateValue is int) {
        return timestampToIso(dateValue);
      }

      // Fallback: try toString() and parse
      final dateString = dateValue.toString();
      try {
        final parsed = DateTime.parse(dateString);
        return parsed.toIso8601String();
      } catch (_) {
        debugPrint('⚠️ Could not parse date string: $dateString');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ Invalid date format for value: $dateValue, error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: Converts timestamps (in ms or s) → ISO8601 string
  // ---------------------------------------------------------------------------
  String timestampToIso(int timestamp) {
    try {
      // Detect ms vs s
      final isMilliseconds = timestamp > 1000000000000; // ~Sat Nov 20 2001
      final dateTime =
          isMilliseconds
              ? DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true)
              : DateTime.fromMillisecondsSinceEpoch(
                timestamp * 1000,
                isUtc: true,
              );
      return dateTime.toIso8601String();
    } catch (e) {
      debugPrint('⚠️ Failed to convert timestamp: $timestamp → $e');
      return DateTime.now().toIso8601String(); // fallback
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: map delivery data
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> mapDeliveryData(RecordModel tripRecord) {
    try {
      final deliveryData = tripRecord.expand['deliveryData'] as List? ?? [];
      return deliveryData.map((item) {
        final record = item as RecordModel;
        return convertRecordToJson(record);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping delivery data: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: map trip updates
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> mapTripUpdates(RecordModel tripRecord) {
    try {
      final timeline = tripRecord.expand['trip_update_list'] as List? ?? [];
      return timeline.map((item) {
        final record = item as RecordModel;
        return convertRecordToJson(record);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping trip Updates: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: map personels
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> mapPersonels(RecordModel tripRecord) {
    try {
      final personels = tripRecord.expand['personels'] as List? ?? [];
      return personels.map((item) {
        final record = item as RecordModel;
        return convertRecordToJson(record);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping personels: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: map checklist
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> mapChecklist(RecordModel tripRecord) {
    try {
      final checklist = tripRecord.expand['checklist'] as List? ?? [];
      return checklist.map((item) {
        final record = item as RecordModel;
        return convertRecordToJson(record);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping checklist: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: convert record to JSON
  // ---------------------------------------------------------------------------
  Map<String, dynamic> convertRecordToJson(RecordModel record) {
    try {
      final data = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
      };

      // Add all data fields, ensuring DateTime objects are converted to strings
      record.data.forEach((key, value) {
        if (value is DateTime) {
          data[key] = value.toIso8601String();
        } else {
          data[key] = value;
        }
      });

      return data;
    } catch (e) {
      debugPrint('⚠️ Error converting record to JSON: $e');
      return {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: calculate and store trip total time
  // ---------------------------------------------------------------------------
  Future<void> calculateAndStoreTripTotalTime(TripModel trip) async {
    try {
      // Get verification time from EndTripOtp or Otp
      final verifiedAt =
          trip.endTripOtp.target?.verifiedAt ?? trip.otp.target?.verifiedAt;
      final timeAccepted = trip.timeAccepted;

      if (verifiedAt == null || timeAccepted == null) {
        debugPrint(
          '⚠️ Cannot calculate tripTotalTime: verifiedAt=$verifiedAt, timeAccepted=$timeAccepted',
        );
        return;
      }

      // Calculate duration
      final duration = verifiedAt.difference(timeAccepted);
      trip.tripTotalTime = duration.toString() as String?;

      debugPrint(
        '⏱️ Trip Total Time Calculated: ${trip.tripTotalTime} '
        '(Start: $timeAccepted, End: $verifiedAt)',
      );
    } catch (e) {
      debugPrint('❌ Error calculating trip total time: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: prepare trip data safely
  // ---------------------------------------------------------------------------
  Map<String, dynamic> prepareTripDataSafely(
    RecordModel tripRecord,
    RecordModel updatedRecord,
    double latitude,
    double longitude,
  ) {
    try {
      final data = {
        'id': updatedRecord.id,
        'collectionId': updatedRecord.collectionId,
        'collectionName': updatedRecord.collectionName,
        'latitude': latitude,
        'longitude': longitude,
      };

      // Add all data fields with safe type conversion
      updatedRecord.data.forEach((key, value) {
        data[key] = convertValueSafely(key, value);
      });

      // Add expanded relations with safe mapping
      data['timeline'] = mapTimelineSafely(tripRecord);
      data['personels'] = mapPersonelsSafely(tripRecord);
      data['checklist'] = mapChecklistSafely(tripRecord);
      data['vehicle'] = mapVehicleSafely(tripRecord);

      return data;
    } catch (e) {
      debugPrint('⚠️ Error preparing trip data: $e');
      // Return minimal valid data to avoid further errors
      return {
        'id': updatedRecord.id,
        'collectionId': updatedRecord.collectionId,
        'collectionName': updatedRecord.collectionName,
        'latitude': latitude,
        'longitude': longitude,
        'updated': DateTime.now().toIso8601String(),
      };
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: safe value conversion
  // ---------------------------------------------------------------------------
  dynamic convertValueSafely(String key, dynamic value) {
    try {
      if (value == null) return null;

      // Handle DateTime objects
      if (value is DateTime) {
        return value.toIso8601String();
      }

      // Handle date fields that might be strings
      if (isDateField(key)) {
        if (value is String && value.isNotEmpty) {
          final parsedDate = parseDateSafely(value);
          return parsedDate?.toIso8601String() ?? value;
        } else if (value is List && value.isEmpty) {
          // Handle empty lists that shouldn't be date fields
          return null;
        }
        return value;
      }

      // Handle different data types appropriately
      if (value is List) {
        // Don't try to parse lists as dates
        return value;
      }

      if (value is Map) {
        return value;
      }

      if (value is bool || value is int || value is double) {
        return value;
      }

      // For strings, return as-is unless it's a date field
      return value;
    } catch (e) {
      debugPrint('⚠️ Error converting value for key $key: $e');
      return value; // Return original value if conversion fails
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: enhanced and safer date parsing
  // ---------------------------------------------------------------------------
  DateTime? parseDateSafely(dynamic value) {
    if (value == null) return null;

    // Handle non-string types
    if (value is! String) {
      if (value is List && value.isEmpty) {
        return null; // Empty list is not a date
      }
      if (value is int) {
        // Could be a timestamp
        try {
          return DateTime.fromMillisecondsSinceEpoch(
            value > 9999999999 ? value : value * 1000,
          );
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    String strValue = value.toString().trim();
    if (strValue.isEmpty || strValue == '[]' || strValue == '{}') {
      return null;
    }

    try {
      // Try standard ISO format first
      return DateTime.parse(strValue);
    } catch (e) {
      debugPrint('⚠️ Standard date parsing failed for: $strValue');

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
          RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'), // MM/DD/YYYY
          RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$'), // YYYY-MM-DD
          RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$'), // DD-MM-YYYY
          RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2})$'), // MM/DD/YY
          RegExp(r'^(\d{4})/(\d{1,2})/(\d{1,2})$'), // YYYY/MM/DD
        ];

        for (var format in formats) {
          if (format.hasMatch(strValue)) {
            var match = format.firstMatch(strValue)!;
            try {
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
              } else if (format.pattern == r'^(\d{1,2})/(\d{1,2})/(\d{2})$') {
                // MM/DD/YY
                int year = int.parse(match.group(3)!);
                year += year <= 30 ? 2000 : 1900;
                return DateTime(
                  year,
                  int.parse(match.group(1)!),
                  int.parse(match.group(2)!),
                );
              } else if (format.pattern == r'^(\d{4})/(\d{1,2})/(\d{1,2})$') {
                // YYYY/MM/DD
                return DateTime(
                  int.parse(match.group(1)!),
                  int.parse(match.group(2)!),
                  int.parse(match.group(3)!),
                );
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing date with format: $e');
              continue;
            }
          }
        }

        // Try parsing with time components
        if (strValue.contains('T') || strValue.contains(' ')) {
          try {
            return DateTime.parse(strValue.replaceAll(' ', 'T'));
          } catch (e) {
            debugPrint('⚠️ ISO format parsing failed: $e');
          }
        }

        // If all parsing fails, return null instead of current time
        debugPrint('⚠️ All date parsing attempts failed for: $strValue');
        return null;
      } catch (e2) {
        debugPrint(
          '⚠️ Alternative date parsing failed: $e2 for value: $strValue',
        );
        return null;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: check if a field is a date field
  // ---------------------------------------------------------------------------
  bool isDateField(String fieldName) {
    final dateFields = [
      'created',
      'updated',
      'timeAccepted',
      'timeEndTrip',
      'timestamp',
      'date',
      'time',
      'deliveredAt',
      'completedAt',
      'startTime',
      'endTime',
    ];
    return dateFields.contains(fieldName.toLowerCase()) ||
        fieldName.toLowerCase().contains('time') ||
        fieldName.toLowerCase().contains('date');
  }

  // ---------------------------------------------------------------------------
  // Helper: safe mapping methods
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> mapTimelineSafely(RecordModel tripRecord) {
    try {
      final timeline = tripRecord.expand['timeline'] as List? ?? [];
      return timeline.map((item) {
        if (item is RecordModel) {
          return convertRecordToJsonSafely(item);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping timeline: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> mapPersonelsSafely(RecordModel tripRecord) {
    try {
      final personels = tripRecord.expand['personels'] as List? ?? [];
      return personels.map((item) {
        if (item is RecordModel) {
          return convertRecordToJsonSafely(item);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping personels: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> mapChecklistSafely(RecordModel tripRecord) {
    try {
      final checklist = tripRecord.expand['checklist'] as List? ?? [];
      return checklist.map((item) {
        if (item is RecordModel) {
          return convertRecordToJsonSafely(item);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping checklist: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> mapVehicleSafely(RecordModel tripRecord) {
    try {
      final vehicle = tripRecord.expand['vehicle'] as List? ?? [];
      return vehicle.map((item) {
        if (item is RecordModel) {
          return convertRecordToJsonSafely(item);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping vehicle: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: safe record conversion with proper type handling
  // ---------------------------------------------------------------------------
  Map<String, dynamic> convertRecordToJsonSafely(RecordModel record) {
    try {
      final data = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
      };

      // Add all data fields with safe conversion
      record.data.forEach((key, value) {
        data[key] = convertValueSafely(key, value);
      });

      return data;
    } catch (e) {
      debugPrint('⚠️ Error converting record to JSON: $e');
      return {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: create trip coordinate update with distance tracking
  // ---------------------------------------------------------------------------
  Future<void> createTripCoordinateUpdate(
    String tripId,
    double latitude,
    double longitude, {
    double? accuracy,
    String? source,
    double? totalDistance,
  }) async {
    try {
      debugPrint(
        '🔄 REMOTE: Creating enhanced trip coordinate update with distance tracking',
      );
      debugPrint(
        '   📍 Coordinates: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
      );
      debugPrint(
        '   🎯 Accuracy: ${accuracy?.toStringAsFixed(2) ?? 'Unknown'} meters',
      );
      debugPrint('   📡 Source: ${source ?? 'GPS'}');
      debugPrint(
        '   📏 Total Distance: ${totalDistance?.toStringAsFixed(3) ?? 'Unknown'} km',
      );

      final now = DateTime.now();
      final timestamp = now.toIso8601String();

      // Create enhanced coordinate record with distance information
      await pocketBaseClient
          .collection('tripCoordinatesUpdates')
          .create(
            body: {
              'trip': tripId,
              'latitude': latitude.toString(),
              'longitude': longitude.toString(),
              'accuracy': accuracy?.toString() ?? '0',
              'source': source ?? 'GPS_VALIDATED',
              'totalDistance': totalDistance?.toString() ?? '0',
              'created': timestamp,
              'updated': timestamp,
              'isValidated': 'true',
            },
          );

      debugPrint(
        '✅ REMOTE: Enhanced trip coordinate record created successfully',
      );

      // Now update the delivery team's total distance traveled
      await updateDeliveryTeamDistance(tripId, totalDistance);
    } catch (e) {
      debugPrint(
        '⚠️ REMOTE: Error creating enhanced coordinate update record: $e',
      );

      try {
        // Attempt a simplified version with minimal required fields
        await pocketBaseClient
            .collection('tripCoordinatesUpdates')
            .create(
              body: {
                'trip': tripId,
                'latitude': latitude.toString(),
                'longitude': longitude.toString(),
                'totalDistance': totalDistance?.toString() ?? '0',
                'created': DateTime.now().toIso8601String(),
                'source': 'GPS_FALLBACK',
              },
            );
        debugPrint('✅ REMOTE: Trip coordinate record created (fallback mode)');

        // Still try to update delivery team distance even in fallback mode
        await updateDeliveryTeamDistance(tripId, totalDistance);
      } catch (e2) {
        debugPrint(
          '❌ REMOTE: Failed to create coordinate update record (both attempts): $e2',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: update delivery team total distance traveled
  // ---------------------------------------------------------------------------
  Future<void> updateDeliveryTeamDistance(
    String tripId,
    double? currentSessionDistance,
  ) async {
    try {
      if (currentSessionDistance == null) {
        debugPrint(
          '⚠️ REMOTE: No current session distance provided - skipping delivery team distance update',
        );
        return;
      }

      debugPrint(
        '🚛 REMOTE: Updating delivery team cumulative distance for trip: $tripId',
      );
      debugPrint(
        '   📏 Current Session Distance: ${currentSessionDistance.toStringAsFixed(3)} km',
      );

      // Find delivery team record using tripTicket field
      final deliveryTeamRecords = await pocketBaseClient
          .collection('deliveryTeam')
          .getList(filter: 'tripTicket = "$tripId"', perPage: 1);

      if (deliveryTeamRecords.items.isEmpty) {
        debugPrint('⚠️ REMOTE: No delivery team found for trip: $tripId');
        debugPrint('   This might be normal if trip is not yet fully assigned');
        return;
      }

      final deliveryTeamRecord = deliveryTeamRecords.items.first;
      final deliveryTeamId = deliveryTeamRecord.id;

      // Get previous total distance from database (handles app restart scenario)
      final previousDistanceStr =
          deliveryTeamRecord.data['totalDistanceTraveled']?.toString() ?? '0';
      final previousDistance = double.tryParse(previousDistanceStr) ?? 0.0;

      // Calculate cumulative distance: previous + current session
      final cumulativeDistance = previousDistance + currentSessionDistance;

      debugPrint('🎯 REMOTE: Found delivery team: $deliveryTeamId');
      debugPrint(
        '   📋 Previous Total Distance: ${previousDistance.toStringAsFixed(3)} km',
      );
      debugPrint(
        '   📋 Current Session Distance: ${currentSessionDistance.toStringAsFixed(3)} km',
      );
      debugPrint(
        '   📋 New Cumulative Distance: ${cumulativeDistance.toStringAsFixed(3)} km',
      );

      // Update the delivery team's cumulative total distance traveled
      await pocketBaseClient
          .collection('deliveryTeam')
          .update(
            deliveryTeamId,
            body: {
              'totalDistanceTraveled': cumulativeDistance.toStringAsFixed(
                3,
              ), // Store cumulative distance
              'currentSessionDistance': currentSessionDistance.toStringAsFixed(
                3,
              ), // Track current session
              'lastLocationUpdate': DateTime.now().toIso8601String(),
              'updated': DateTime.now().toIso8601String(),
            },
          );

      debugPrint(
        '✅ REMOTE: Delivery team cumulative distance updated successfully',
      );
      debugPrint('   🎯 Delivery Team ID: $deliveryTeamId');
      debugPrint('   📏 Previous: ${previousDistance.toStringAsFixed(3)} km');
      debugPrint(
        '   📏 Session: ${currentSessionDistance.toStringAsFixed(3)} km',
      );
      debugPrint(
        '   📏 Cumulative Total: ${cumulativeDistance.toStringAsFixed(3)} km',
      );
    } catch (e) {
      debugPrint('❌ REMOTE: Error updating delivery team distance: $e');
      debugPrint(
        '   This error is non-critical - coordinate tracking will continue',
      );
      // Don't throw error here as coordinate creation should still succeed
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: map a record to a TripModel
  // ---------------------------------------------------------------------------
  TripModel mapRecordToTripModel(RecordModel record) {
    try {
      debugPrint('🔄 Mapping record to TripModel: ${record.id}');

      // Debug the raw record data first
      debugPrint('📋 Raw record.id: ${record.id}');
      debugPrint('📋 Raw record.data keys: ${record.data.keys.toList()}');
      debugPrint(
        '📋 Raw tripNumberId from data: ${record.data['tripNumberId']}',
      );
      debugPrint('📋 Raw qrCode from data: ${record.data['qrCode']}');
      debugPrint('📋 Raw name from data: ${record.data['name']}');

      // Safe string helper - handles various data types
      String? safeString(dynamic value) {
        if (value == null) return null;
        if (value is String && value.isNotEmpty) return value;
        if (value is String && value.isEmpty) return null;
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is bool || value is num) return value.toString();
        return null;
      }

      // Parse dates properly
      DateTime? timeAccepted;
      if (record.data['timeAccepted'] != null) {
        try {
          timeAccepted = DateTime.parse(record.data['timeAccepted']);
          debugPrint('✅ Parsed timeAccepted: $timeAccepted');
        } catch (e) {
          debugPrint('❌ Failed to parse timeAccepted: ${e.toString()}');
        }
      }

      DateTime? expectedReturnDate;
      if (record.data['expectedReturnDate'] != null) {
        try {
          expectedReturnDate = DateTime.parse(
            record.data['expectedReturnDate'],
          );
          debugPrint('✅ Parsed expectedReturnDate: $expectedReturnDate');
        } catch (e) {
          debugPrint('❌ Failed to parse expectedReturnDate: ${e.toString()}');
        }
      }

      // Parse dates properly
      DateTime? deliveryDate;
      if (record.data['deliveryDate'] != null) {
        try {
          deliveryDate = DateTime.parse(record.data['deliveryDate']);
          debugPrint('✅ Parsed deliveryDate: $deliveryDate');
        } catch (e) {
          debugPrint('❌ Failed to parse deliveryDate: ${e.toString()}');
        }
      }

      DateTime? timeEndTrip;
      if (record.data['timeEndTrip'] != null) {
        try {
          timeEndTrip = DateTime.parse(record.data['timeEndTrip']);
          debugPrint('✅ Parsed timeEndTrip: $timeEndTrip');
        } catch (e) {
          debugPrint('❌ Failed to parse timeEndTrip: ${e.toString()}');
        }
      }

      DateTime? tripTotalTime;
      if (record.data['tripTotalTime'] != null) {
        try {
          tripTotalTime = DateTime.parse(record.data['tripTotalTime']);
          debugPrint('✅ Parsed tripTotalTime: $tripTotalTime');
        } catch (e) {
          debugPrint('❌ Failed to parse tripTotalTime: ${e.toString()}');
        }
      }

      // Handle delivery vehicle - Use helper function to map expanded data
      final vehicleJsonData = mapExpandedItem(record.expand['deliveryVehicle']);
      DeliveryVehicleModel? vehicleModel;

      if (vehicleJsonData != null) {
        debugPrint(
          '✅ Found vehicle data: ${vehicleJsonData['name']} - ${vehicleJsonData['volumeCapacity']} - ${vehicleJsonData['type']}',
        );

        try {
          vehicleModel = DeliveryVehicleModel.fromJson(vehicleJsonData);
          debugPrint(
            '✅ Successfully processed vehicle: ${vehicleModel.name} - ${vehicleModel.volumeCapacity} - ${vehicleModel.type}',
          );
        } catch (e) {
          debugPrint('❌ Error processing vehicle data: $e');
        }
      } else {
        debugPrint('⚠️ No vehicle data found in record');
      }

      // Handle OTP - Use helper function to map expanded data
      final otpJsonData = mapExpandedItem(record.expand['otp']);
      OtpModel? otpData;

      if (otpJsonData != null) {
        debugPrint(
          '✅ Found OTP data: ${otpJsonData['otpCode']} - ${otpJsonData['otpType']}',
        );

        try {
          otpData = OtpModel.fromJson(otpJsonData);
          debugPrint(
            '✅ Successfully processed OTP:  - ${otpData.otpCode} - ${otpData.otpType} - ',
          );
        } catch (e) {
          debugPrint('❌ Error processing OTP data: $e');
        }
      } else {
        debugPrint('⚠️ No OTP data found in record');
      }

      // Handle End Trip OTP - Use helper function to map expanded data
      final endTripOtpJsonData = mapExpandedItem(record.expand['endTripOtp']);
      EndTripOtpModel? endTripOtpData;

      if (endTripOtpJsonData != null) {
        debugPrint(
          '✅ Found OTP data: ${endTripOtpJsonData['otpCode']} - ${endTripOtpJsonData['otpType']}',
        );

        try {
          endTripOtpData = EndTripOtpModel.fromJson(endTripOtpJsonData);
          debugPrint(
            '✅ Successfully processed End Trip OTP:  - ${endTripOtpData.otpCode} - ${endTripOtpData.otpType} - ',
          );
        } catch (e) {
          debugPrint('❌ Error processing End Trip Otp Data data: $e');
        }
      } else {
        debugPrint('⚠️ No End Trip Otp Data data found in record');
      }

      // Debug vehicle mapping
      if (vehicleModel != null) {
        debugPrint(
          '🚗 Vehicle data mapped for TripModel: ${vehicleModel.name} (${vehicleModel.type})',
        );
      } else {
        debugPrint('⚠️ No vehicle data available for TripModel mapping');
      }

      // IMPORTANT: Spread record.data FIRST, then override with correct values
      // This ensures record.id, tripNumberId, qrCode etc. are not overwritten by null values in record.data
      final mappedData = <String, dynamic>{
        // First spread the base data
        ...record.data,
        // Then override with the correct values that MUST come from record properties
        'id':
            record
                .id, // PocketBase record ID - MUST use record.id, not record.data['id']
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        // Safely extract string fields that might have wrong types in record.data
        'tripNumberId': safeString(record.data['tripNumberId']),
        'qrCode': safeString(record.data['qrCode']),
        'name': safeString(record.data['name']),
        // Expanded relations
        'customers': mapExpandedList(record.expand['customers']),
        'deliveryTeam': mapExpandedItem(record.expand['deliveryTeam']),
        'personels': mapExpandedList(record.expand['personels']),
        'deliveryVehicle': vehicleModel,
        'otp': otpData,
        'endTripOtp': endTripOtpData,
        'deliveryData': mapExpandedList(record.expand['deliveryData']),
        'dispatcher': record.data['dispatcher'],
        'checklist': mapExpandedList(record.expand['checklist']),
        'endTripChecklists': mapExpandedList(
          record.expand['endTripChecklists'],
        ),
        'trip_update_list': mapExpandedList(record.expand['trip_update_list']),
        // Dates - use parsed values
        'created': record.created,
        'updated': record.updated,
        'timeAccepted': timeAccepted?.toIso8601String(),
        'timeEndTrip': timeEndTrip?.toIso8601String(),
        'deliveryDate': deliveryDate?.toIso8601String(),
        'expectedReturnDate': expectedReturnDate?.toIso8601String(),
        'tripTotalTime': tripTotalTime?.toIso8601String(),
        // Other fields
        'longitude': record.data['longitude'],
        'latitude': record.data['latitude'],
        'volumeRate': record.data['volumeRate'],
        'weightRate': record.data['weightRate'],
        'averageFillRate': record.data['averageFillRate'],
      };

      // Debug the final mapped data
      debugPrint('📦 Final mappedData id: ${mappedData['id']}');
      debugPrint(
        '📦 Final mappedData tripNumberId: ${mappedData['tripNumberId']}',
      );
      debugPrint('📦 Final mappedData qrCode: ${mappedData['qrCode']}');

      return TripModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error mapping record to TripModel: $e');
      throw ServerException(
        message: 'Failed to map record to TripModel: $e',
        statusCode: '500',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: map expanded list items
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> mapExpandedList(dynamic records) {
    if (records == null) return [];

    if (records is List) {
      return records.map((record) {
        if (record is RecordModel) {
          return <String, dynamic>{
            'id': record.id,
            'collectionId': record.collectionId,
            'collectionName': record.collectionName,
            ...Map<String, dynamic>.from(record.data),
            'created': record.created,
            'updated': record.updated,
          };
        }
        return <String, dynamic>{};
      }).toList();
    }

    return [];
  }

  // ---------------------------------------------------------------------------
  // Helper: map a single expanded item
  // ---------------------------------------------------------------------------
  Map<String, dynamic>? mapExpandedItem(dynamic record) {
    if (record == null) return null;

    if (record is List && record.isNotEmpty) {
      final item = record.first;
      if (item is RecordModel) {
        return <String, dynamic>{
          'id': item.id,
          'collectionId': item.collectionId,
          'collectionName': item.collectionName,
          ...Map<String, dynamic>.from(item.data),
          'created': item.created,
          'updated': item.updated,
        };
      }
    } else if (record is RecordModel) {
      return <String, dynamic>{
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        ...Map<String, dynamic>.from(record.data),
        'created': record.created,
        'updated': record.updated,
      };
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Helper: retry with exponential backoff
  // ---------------------------------------------------------------------------
  Future<T> retry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 4,
    Duration initialDelay = const Duration(milliseconds: 350),
    double backoffFactor = 2.0,
    Duration maxDelay = const Duration(seconds: 4),
    bool Function(Object e)? shouldRetry,
    String? label,
  }) async {
    int attempt = 0;
    final rng = Random();

    bool defaultShouldRetry(Object e) {
      final msg = e.toString().toLowerCase();

      // PocketBase / http client / socket / dns / timeouts typically look like these:
      return msg.contains('socketexception') ||
          msg.contains('network is unreachable') ||
          msg.contains('connection failed') ||
          msg.contains('failed host lookup') ||
          msg.contains('errno = 101') ||
          msg.contains('statuscode: 0') ||
          msg.contains('timed out') ||
          msg.contains('timeout') ||
          msg.contains('connection reset') ||
          msg.contains('handshakeexception');
    }

    while (true) {
      attempt++;
      try {
        return await fn();
      } catch (e) {
        final retryable = (shouldRetry ?? defaultShouldRetry)(e);

        if (!retryable || attempt >= maxAttempts) {
          debugPrint(
            '❌${label != null ? " [$label]" : ""} Retry stopped (attempt $attempt/$maxAttempts): $e',
          );
          rethrow;
        }

        // exponential backoff + small jitter
        final expMs =
            (initialDelay.inMilliseconds * pow(backoffFactor, attempt - 1))
                .toInt();
        final jitterMs = rng.nextInt(150); // 0..149ms
        final delayMs = min(expMs + jitterMs, maxDelay.inMilliseconds);

        debugPrint(
          '🔁${label != null ? " [$label]" : ""} Retry $attempt/$maxAttempts after ${delayMs}ms بسبب error: $e',
        );
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: sync user data from remote
  // ---------------------------------------------------------------------------
  Future<LocalUsersModel> syncUserData(String userId) async {
    try {
      debugPrint('🔄 Syncing user data from remote for ID: $userId');

      final userRecord = await pocketBaseClient
          .collection('users')
          .getOne(
            userId,
            expand:
                'checklist,updateTimeline,deliveryTeam,completedCustomer,returnList,endTripChecklists,trips',
          );

      // Basic info
      debugPrint('📊 Remote Sync Stats:');
      debugPrint('   👤 User ID: ${userRecord.id}');
      debugPrint('   📝 Name: ${userRecord.data['name']}');
      debugPrint('   📧 Email: ${userRecord.data['email']}');
      debugPrint('   🚚 Trip Number: ${userRecord.data['tripNumberId']}');

      // Expanded relationships counts
      debugPrint(
        '   📋 Checklist Items: ${userRecord.expand['checklist']?.length ?? 0}',
      );
      debugPrint(
        '   ⏱ Update Timeline Items: ${userRecord.expand['updateTimeline']?.length ?? 0}',
      );
      debugPrint(
        '   👥 Delivery Team Items: ${userRecord.expand['deliveryTeam']?.length ?? 0}',
      );
      debugPrint(
        '   ✅ Completed Customers: ${userRecord.expand['completedCustomer']?.length ?? 0}',
      );
      debugPrint(
        '   🔄 Return List Items: ${userRecord.expand['returnList']?.length ?? 0}',
      );
      debugPrint(
        '   🏁 End Trip Checklists: ${userRecord.expand['endTripChecklists']?.length ?? 0}',
      );
      debugPrint('   🛣 Trip Data: ${userRecord.expand['trip'] ?? 'No Trip'}');

      // 4️⃣ Extract DeliveryTeam + nested relations
      final tripRecord = userRecord.expand['trip']?.firstOrNull;
      Map<String, dynamic>? tripMapped;
      if (tripRecord != null) {
        debugPrint('trip record: ${tripRecord.id}');
      }
      final Map<String, dynamic> userData = {
        ...userRecord.data,
        'id': userRecord.id,
        'name': userRecord.data['name'] ?? '',
        'tripNumberId': userRecord.data['tripNumberId'] ?? '',
        'checklist':
            userRecord.expand['checklist']?.map((item) => item.id).toList() ??
            [],
        'updateTimeline':
            userRecord.expand['updateTimeline']
                ?.map((item) => item.id)
                .toList() ??
            [],
        'deliveryTeam':
            userRecord.expand['deliveryTeam']
                ?.map((item) => item.id)
                .toList() ??
            [],
        'completedCustomer':
            userRecord.expand['completedCustomer']
                ?.map((item) => item.id)
                .toList() ??
            [],
        'returnList':
            userRecord.expand['returnList']?.map((item) => item.id).toList() ??
            [],
        'endTripChecklists':
            userRecord.expand['endTripChecklists']
                ?.map((item) => item.id)
                .toList() ??
            [],
        'trip': tripMapped,
      };

      // Full data debug
      debugPrint('📦 Full userData Map: ${userData.toString()}');

      debugPrint('✅ User data synced successfully');
      return LocalUsersModel.fromJson(userData);
    } catch (e) {
      debugPrint('❌ User sync failed: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: sync user trip data from remote
  // ---------------------------------------------------------------------------
  Future<TripModel> syncUserTripData(String userId) async {
    try {
      debugPrint('🔄 [SYNC] Starting user trip sync for user: $userId');

      // 1️⃣ Fetch user & trip
      debugPrint('📡 Fetching user record...');
      final userRecord = await pocketBaseClient
          .collection('users')
          .getOne(userId, expand: 'trip');

      debugPrint('🧩 USER RAW DATA: ${jsonEncode(userRecord.data)}');
      debugPrint('🧩 USER EXPAND KEYS: ${userRecord.expand.keys.toList()}');

      final expandedTrip = userRecord.expand['trip'];

      if (expandedTrip == null || expandedTrip.isEmpty) {
        debugPrint(
          'ℹ️ No trip assigned to user (normal). Clearing local trip cache.',
        );

        final prefs = await SharedPreferences.getInstance();

        // Clear trip cache so UI doesn't render stale trip
        await prefs.remove('user_trip_data');

        // Also clear trip reference inside user_data (if exists)
        final userDataRaw = prefs.getString('user_data');
        if (userDataRaw != null) {
          final userData = jsonDecode(userDataRaw);
          userData.remove('trip'); // or: userData['trip'] = null;
          await prefs.setString('user_data', jsonEncode(userData));
          debugPrint('💾 user_data updated → trip cleared');
        } else {
          debugPrint('⚠️ user_data not found, skipping trip clear');
        }

        // Return a safe empty TripModel (prevents UI crash)
        return TripModel(
          id: null,
          name: null,
          tripNumberId: null,
          isAccepted: false,
          isEndTrip: false,
        );
      }

      final tripId = expandedTrip.first.id;
      debugPrint('🆔 User\'s Trip ID: $tripId');

      // 2️⃣ Fetch FULL expanded trip including relations
      debugPrint('📡 Fetching full trip from PocketBase...');
      final fullTripList = await pocketBaseClient
          .collection('tripticket')
          .getFullList(
            filter: 'id = "$tripId"',
            expand:
                'customers,deliveryTeam,deliveryTeam.personels,deliveryTeam.deliveryVehicle,deliveryTeam.checklist,personels,deliveryVehicle,checklist,deliveryData.customer,deliveryData.invoices,deliveryData.deliveryUpdates,deliveryData.trip,cancelledInvoice,deliveryData.invoiceItems',
            sort: '-created',
          );

      if (fullTripList.isEmpty) {
        debugPrint('❌ Trip not found on server.');
        throw const ServerException(
          message: 'Trip not found.',
          statusCode: '404',
        );
      }

      final tripRecord = fullTripList.first;
      debugPrint('📦 TRIP RAW DATA: ${jsonEncode(tripRecord.data)}');
      debugPrint('📦 TRIP EXPAND KEYS: ${tripRecord.expand.keys.toList()}');
      // 3️⃣ Extract DeliveryData
      final deliveryDataList = tripRecord.expand['deliveryData'] ?? [];
      debugPrint(
        '📦 Delivery Data Count: ${deliveryDataList.length} (with invoiceItems)',
      );

      for (final d in deliveryDataList) {
        // Basic delivery info
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('➡️ DeliveryData ID: ${d.id}');
        debugPrint('   🔑 DeliveryData expand keys: ${d.expand.keys.toList()}');

        // -----------------------------
        // Customer (expand)
        // -----------------------------
        final customerRec =
            (d.expand['customer'] != null)
                ? (d.expand['customer'] as List).firstOrNull
                : null;

        if (customerRec == null) {
          debugPrint('   👤 customer: ❌ NULL / not expanded');
          d.data['customer'] = null;
        } else {
          debugPrint(
            '   👤 customer: ✅ id=${customerRec.id} | name=${customerRec.data['name']}',
          );
          d.data['customer'] = mapExpandedRecord(customerRec);
        }

        // -----------------------------
        // Trip (expand)
        // -----------------------------
        final tripRec =
            (d.expand['trip'] != null)
                ? (d.expand['trip'] as List).firstOrNull
                : null;

        if (tripRec == null) {
          debugPrint('   🎫 trip: ❌ NULL / not expanded');
          d.data['trip'] = null;
        } else {
          debugPrint(
            '   🎫 trip: ✅ id=${tripRec.id} | name=${tripRec.data['name']}',
          );
          d.data['trip'] = mapExpandedRecord(tripRec);
        }

        // -----------------------------
        // Invoices (expand list)
        // -----------------------------
        final invoices = d.expand['invoices'] as List? ?? [];
        debugPrint('   🧾 invoices: count=${invoices.length}');
        for (final inv in invoices) {
          final r = inv as RecordModel;
          debugPrint(
            '      • invoice id=${r.id} | name=${r.data['name']} | total=${r.data['totalAmount']}',
          );
        }
        d.data['invoices'] = invoices.map(mapExpandedRecord).toList();

        // -----------------------------
        // DeliveryUpdates (expand list)
        // -----------------------------
        final updates = d.expand['deliveryUpdates'] as List? ?? [];
        debugPrint('   🔄 deliveryUpdates: count=${updates.length}');
        for (final up in updates) {
          final r = up as RecordModel;
          debugPrint(
            '      • update id=${r.id} | title=${r.data['title']} | time=${r.data['time']}',
          );
        }
        d.data['deliveryUpdates'] = updates.map(mapExpandedRecord).toList();

        // -----------------------------
        // InvoiceItems (expand list)
        // -----------------------------
        final invoiceItems = d.expand['invoiceItems'] as List? ?? [];
        debugPrint('   📦 invoiceItems: count=${invoiceItems.length}');
        for (final it in invoiceItems) {
          final r = it as RecordModel;
          debugPrint(
            '      • item id=${r.id} | name=${r.data['name']} | qty=${r.data['quantity']} | baseQty=${r.data['totalBaseQuantity']} | uom=${r.data['uom']}',
          );
        }
        d.data['invoiceItems'] = invoiceItems.map(mapExpandedRecord).toList();

        // -----------------------------
        // Final mapped payload check
        // -----------------------------
        debugPrint(
          '   ✅ mapped: customer=${d.data['customer'] != null}, '
          'trip=${d.data['trip'] != null}, '
          'invoices=${(d.data['invoices'] as List).length}, '
          'updates=${(d.data['deliveryUpdates'] as List).length}, '
          'invoiceItems=${(d.data['invoiceItems'] as List).length}',
        );
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // 3️⃣ Extract CancelledInvoice
      final cancelledInvoiceList = tripRecord.expand['cancelledInvoice'] ?? [];
      debugPrint(
        '📦 Cancelled Invoices Data Count: ${cancelledInvoiceList.length}',
      );
      for (var d in cancelledInvoiceList) {
        debugPrint('   ➡️ CancelledInvoice ID: ${d.id}');
        final customer =
            (d.expand['customer'] != null)
                ? (d.expand['customer'] as List).firstOrNull
                : null;
        d.data['customer'] =
            customer != null ? mapExpandedRecord(customer) : null;
        final deliveryData =
            (d.expand['deliveryData'] != null)
                ? (d.expand['deliveryData'] as List).firstOrNull
                : null;
        d.data['deliveryData'] =
            deliveryData != null ? mapExpandedRecord(deliveryData) : null;
        final trip =
            (d.expand['trip'] != null)
                ? (d.expand['trip'] as List).firstOrNull
                : null;
        d.data['trip'] = trip != null ? mapExpandedRecord(trip) : null;

        final invoices = d.expand['invoices'] as List? ?? [];
        d.data['invoices'] = invoices.map(mapExpandedRecord).toList();
      }

      // 4️⃣ Extract DeliveryTeam + nested relations
      final deliveryTeamRecord = tripRecord.expand['deliveryTeam']?.firstOrNull;
      Map<String, dynamic>? mappedDeliveryTeam;
      if (deliveryTeamRecord != null) {
        debugPrint('👥 Delivery Team ID: ${deliveryTeamRecord.id}');

        // Vehicle
        final vehicleRecord =
            deliveryTeamRecord.expand['deliveryVehicle']?.firstOrNull;
        final mappedVehicle =
            vehicleRecord != null ? mapExpandedRecord(vehicleRecord) : null;
        debugPrint(
          '🚛 DeliveryTeam Vehicle ID: ${vehicleRecord?.id ?? "NONE"}',
        );

        // Personels
        final teamPersonels = deliveryTeamRecord.expand['personels'] ?? [];
        debugPrint(
          '🧑‍🔧 DeliveryTeam Personels Count: ${teamPersonels.length}',
        );

        // Checklist
        final teamChecklist = deliveryTeamRecord.expand['checklist'] ?? [];
        debugPrint('📋 DeliveryTeam Checklist Count: ${teamChecklist.length}');

        mappedDeliveryTeam = {
          ...mapExpandedRecord(deliveryTeamRecord),
          'deliveryVehicle': mappedVehicle,
          'personels': mapExpandedRecord(teamPersonels),
          'checklist': mapExpandedRecord(teamChecklist),
        };
      }

      // 5️⃣ Extract other relations
      final personels = tripRecord.expand['personels'] ?? [];
      final vehicle = tripRecord.expand['deliveryVehicle']?.firstOrNull;
      final checklistList = tripRecord.expand['checklist'] ?? [];
      final tripUpdateList = tripRecord.expand['trip_update_list'] ?? [];
      final intransitOtp = tripRecord.expand['otp'] ?? [];
      final endTripOtp = tripRecord.expand['endTripOtp'] ?? [];

      // 6️⃣ Map full trip
      final mappedTrip = {
        'id': tripRecord.id,
        'collectionId': tripRecord.collectionId,
        'collectionName': tripRecord.collectionName,
        'name': tripRecord.data['name']?.toString() ?? tripRecord.id,
        'tripNumberId':
            tripRecord.data['tripNumberId']?.toString() ?? tripRecord.id,
        'qrCode': tripRecord.data['qrCode']?.toString() ?? '',
        'isAccepted': tripRecord.data['isAccepted'] ?? false,
        'isEndTrip': tripRecord.data['isEndTrip'] ?? false,
        'deliveryDate': tripRecord.data['deliveryDate'],
        'latitude': tripRecord.data['latitude'] ?? 0.0,
        'longitude': tripRecord.data['longitude'] ?? 0.0,
        'deliveryTeam': mappedDeliveryTeam,
        'personels': mapExpandedRecord(personels),
        'deliveryVehicle': mapExpandedRecord(vehicle),
        'checklist': mapExpandedRecord(checklistList),
        'deliveryData': mapExpandedRecord(deliveryDataList),
        'cancelledInvoice': mapExpandedRecord(cancelledInvoiceList),
        'trip_update_list': mapExpandedRecord(tripUpdateList),
        'intransitOtp': mapExpandedRecord(intransitOtp),
        'endTripOtp': mapExpandedRecord(endTripOtp),
      };

      debugPrint('📦 FINAL MAPPED TRIP JSON: ${jsonEncode(mappedTrip)}');

      // 7️⃣ Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_trip_data', jsonEncode(mappedTrip));
      debugPrint('💾 Trip cache saved successfully');

      // 8️⃣ Build TripModel
      final trip = TripModel.fromJson(mappedTrip);
      debugPrint(
        '🧪 TripModel BUILT → name="${trip.name}", tripNumberId="${trip.tripNumberId}"',
      );

      debugPrint('📦 Delivery Data Count: ${trip.deliveryData.length}');
      debugPrint('👥 Delivery Team ID: ${trip.deliveryTeam.target?.id}');
      debugPrint('🚛 Vehicle Name: ${trip.deliveryVehicle.target?.name}');
      debugPrint('🧑‍🔧 Personnels Count: ${trip.personels.length}');

      // 7.5️⃣ Update user_data with resolved trip reference
      final userDataRaw = prefs.getString('user_data');

      if (userDataRaw != null) {
        final userData = jsonDecode(userDataRaw);

        userData['trip'] = {
          'id': mappedTrip['id'], // PB ID
          'name': mappedTrip['name'], // PB ID

          'tripNumberId': mappedTrip['tripNumberId'],
          'isAccepted': mappedTrip['isAccepted'],
          'isEndTrip': mappedTrip['isEndTrip'],
        };

        await prefs.setString('user_data', jsonEncode(userData));
        debugPrint('💾 user_data updated with resolved trip ID');
      } else {
        debugPrint('⚠️ user_data not found, skipping trip reference update');
      }

      return trip;
    } catch (e, st) {
      debugPrint('❌ [SYNC USER TRIP ERROR] $e');
      debugPrint('STACK TRACE: $st');
      throw ServerException(
        message: 'Failed to sync user trip: $e',
        statusCode: '500',
      );
    }
  }
}
