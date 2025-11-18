import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip_coordinates_update/data/model/trip_coordinates_model.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';

abstract class TripCoordinatesRemoteDataSource {
  /// Retrieves all trip coordinate updates for a specific trip
  ///
  /// [tripId] The ID of the trip to get coordinates for
  /// [delayBeforeFetch] Delay in seconds before fetching (default: 3s to ensure server has latest data)
  /// Returns a list of [TripCoordinatesModel] objects
  Future<List<TripCoordinatesModel>> getTripCoordinatesByTripId(
    String tripId, {
    int delayBeforeFetch = 3,
  });
}

class TripCoordinatesRemoteDataSourceImpl
    implements TripCoordinatesRemoteDataSource {
  const TripCoordinatesRemoteDataSourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<List<TripCoordinatesModel>> getTripCoordinatesByTripId(
    String tripId, {
    int delayBeforeFetch = 3,
  }) async {
    try {
      // Extract trip ID if we received a JSON object
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint(
        '🔄 Getting trip coordinates for trip ID: $actualTripId (waiting ${delayBeforeFetch}s for latest data)',
      );

      // Wait for the specified delay to ensure server has the latest coordinates
      // This prevents race conditions where the fetch happens before coordinates are persisted
      await Future.delayed(Duration(seconds: delayBeforeFetch));

      debugPrint(
        '✅ Delay complete, now fetching coordinates for trip: $actualTripId',
      );

      // Get coordinates using trip ID
      final List<RecordModel> records = await _pocketBaseClient
          .collection('tripCoordinatesUpdates')
          .getFullList(
            filter: 'trip = "$actualTripId"',
            expand: 'trip',
            sort:
                '-created', // Sort by creation time to get chronological order
          );

      debugPrint(
        '✅ Retrieved ${records.length} coordinate updates for trip: $actualTripId',
      );

      List<TripCoordinatesModel> coordinates = [];

      for (RecordModel record in records) {
        // Process trip data
        TripModel? tripModel;

        // Safely access expand data
        final expandData = record.expand;
        if (expandData.containsKey('trip')) {
          final tripData = expandData['trip'];

          // Handle single record or list of records
          if (tripData is List && tripData!.isNotEmpty) {
            // List of records (take the first one)
            final firstRecord = tripData.first;
            tripModel = TripModel.fromJson({
              'id': firstRecord.id,
              'collectionId': firstRecord.collectionId,
              'collectionName': firstRecord.collectionName,
              ...firstRecord.data,
            });
          }
        }

        // Parse latitude and longitude
        double? latitude;
        if (record.data.containsKey('latitude') &&
            record.data['latitude'] != null) {
          try {
            latitude = double.parse(record.data['latitude'].toString());
          } catch (e) {
            debugPrint('❌ Error parsing latitude: $e');
          }
        }

        double? longitude;
        if (record.data.containsKey('longitude') &&
            record.data['longitude'] != null) {
          try {
            longitude = double.parse(record.data['longitude'].toString());
          } catch (e) {
            debugPrint('❌ Error parsing longitude: $e');
          }
        }

        // Enhanced safe date parsing function with multiple fallbacks
        DateTime? parseDate(dynamic value) {
          if (value == null) return null;

          // If value is already a DateTime, return it directly
          if (value is DateTime) {
            return value;
          }

          String strValue = value.toString().trim();
          if (strValue.isEmpty) return null;

          debugPrint(
            '🔍 Attempting to parse date: "$strValue" (type: ${value.runtimeType})',
          );

          try {
            // Try standard ISO format first
            debugPrint('🔍 Attempting DateTime.parse("$strValue")');
            final result = DateTime.parse(strValue);
            debugPrint('✅ Successfully parsed: $result');
            return result;
          } catch (e) {
            debugPrint(
              '⚠️ Standard date parsing failed: $e for value: $strValue',
            );

            try {
              // Try Unix timestamp (milliseconds or seconds)
              if (strValue.length >= 10 &&
                  RegExp(r'^\d+$').hasMatch(strValue)) {
                int timestamp = int.parse(strValue);
                // If it's in seconds (10 digits), convert to milliseconds
                if (strValue.length == 10) {
                  timestamp *= 1000;
                }
                return DateTime.fromMillisecondsSinceEpoch(timestamp);
              }

              // Try various date formats
              final formats = [
                {
                  'pattern': RegExp(
                    r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
                  ), // MM/DD/YYYY
                  'parser':
                      (Match match) => DateTime(
                        int.parse(match.group(3)!), // year
                        int.parse(match.group(1)!), // month
                        int.parse(match.group(2)!), // day
                      ),
                },
                {
                  'pattern': RegExp(
                    r'^(\d{4})-(\d{1,2})-(\d{1,2})$',
                  ), // YYYY-MM-DD
                  'parser':
                      (Match match) => DateTime(
                        int.parse(match.group(1)!), // year
                        int.parse(match.group(2)!), // month
                        int.parse(match.group(3)!), // day
                      ),
                },
                {
                  'pattern': RegExp(
                    r'^(\d{1,2})-(\d{1,2})-(\d{4})$',
                  ), // DD-MM-YYYY
                  'parser':
                      (Match match) => DateTime(
                        int.parse(match.group(3)!), // year
                        int.parse(match.group(2)!), // month
                        int.parse(match.group(1)!), // day
                      ),
                },
                {
                  'pattern': RegExp(
                    r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$',
                  ), // DD.MM.YYYY
                  'parser':
                      (Match match) => DateTime(
                        int.parse(match.group(3)!), // year
                        int.parse(match.group(2)!), // month
                        int.parse(match.group(1)!), // day
                      ),
                },
                {
                  'pattern': RegExp(
                    r'^(\d{4})\/(\d{1,2})\/(\d{1,2})$',
                  ), // YYYY/MM/DD
                  'parser':
                      (Match match) => DateTime(
                        int.parse(match.group(1)!), // year
                        int.parse(match.group(2)!), // month
                        int.parse(match.group(3)!), // day
                      ),
                },
              ];

              for (var format in formats) {
                final pattern = format['pattern'] as RegExp;
                final parser = format['parser'] as DateTime Function(Match);

                if (pattern.hasMatch(strValue)) {
                  final match = pattern.firstMatch(strValue)!;
                  try {
                    return parser(match);
                  } catch (e) {
                    debugPrint(
                      '⚠️ Error parsing date with pattern ${pattern.pattern}: $e',
                    );
                    continue;
                  }
                }
              }

              // Try to parse as ISO string with different variations
              final isoVariations = [
                strValue.replaceAll(' ', 'T'), // Replace space with T
                '${strValue}T00:00:00.000Z', // Add time if missing
                '${strValue}Z', // Add Z if missing
              ];

              for (var variation in isoVariations) {
                try {
                  debugPrint('🔍 Trying ISO variation: "$variation"');
                  return DateTime.parse(variation);
                } catch (e) {
                  debugPrint('⚠️ ISO variation failed: $e for "$variation"');
                  continue;
                }
              }

              // If all else fails, return current time as fallback
              debugPrint(
                '⚠️ All date parsing attempts failed for: $strValue, using current time',
              );
              return DateTime.now();
            } catch (e2) {
              debugPrint(
                '⚠️ Alternative date parsing failed: $e2 for value: $strValue, using current time',
              );
              return DateTime.now();
            }
          }
        }

        // Create model from record
        DateTime? createdDate;
        DateTime? updatedDate;

        try {
          debugPrint(
            '🔍 Parsing created date: ${record.created} (type: ${record.created.runtimeType})',
          );
          createdDate = parseDate(record.created);
        } catch (e) {
          debugPrint('❌ Error parsing created date: $e');
          createdDate = null;
        }

        try {
          debugPrint(
            '🔍 Parsing updated date: ${record.updated} (type: ${record.updated.runtimeType})',
          );
          updatedDate = parseDate(record.updated);
        } catch (e) {
          debugPrint('❌ Error parsing updated date: $e');
          updatedDate = null;
        }

        coordinates.add(
          TripCoordinatesModel(
            id: record.id,
            collectionId: record.collectionId,
            collectionName: record.collectionName,
            trip: tripModel,
            tripId: actualTripId,
            latitude: latitude,
            longitude: longitude,
            created: createdDate,
            updated: updatedDate,
          ),
        );
      }

      return coordinates;
    } catch (e) {
      debugPrint('❌ Error getting trip coordinates: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load trip coordinates: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
