import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/datasource/local_datasource/trip_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class TripRemoteDatasurce {
  Future<TripModel> loadTrip();
  Future<TripModel> getTripById(String id);
  Future<TripModel> searchTripByNumber(String tripNumberId);
  Future<TripModel> scanTripByQR(String qrData);
  Future<(TripModel, String)> acceptTrip(
    String tripId,
  ); // Modified to return tuple with tracking ID
  Future<bool> checkEndTripOtpStatus(String tripId);
  Future<List<TripModel>> searchTrips({
    String? tripNumberId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAccepted,
    bool? isEndTrip,
    String? deliveryTeamId,
    String? vehicleId,
    String? personnelId,
  });
  Future<List<TripModel>> getTripsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  Future<String> calculateTotalTripDistance(String tripId);
  Future<TripModel> endTrip(String tripId);

  // Add the new method to update trip location
  Future<TripModel> updateTripLocation(
    String tripId,
    double latitude,
    double longitude,
  );
}

class TripRemoteDatasurceImpl implements TripRemoteDatasurce {
  const TripRemoteDatasurceImpl({
    required PocketBase pocketBaseClient,
    required TripLocalDatasource tripLocalDatasource,
  }) : _pocketBaseClient = pocketBaseClient,
       _tripLocalDatasource = tripLocalDatasource;

  final PocketBase _pocketBaseClient;
  final TripLocalDatasource _tripLocalDatasource;

  @override
  Future<TripModel> loadTrip() async {
    try {
      final records = await _pocketBaseClient
          .collection('tripticket')
          .getList(expand: 'customers,personels,checklist,');

      // In the loadTrip method

      if (records.items.isEmpty) {
        throw const ServerException(
          message: 'No trip found',
          statusCode: '404',
        );
      }

      final record = records.items.first;
      final mappedData = {
        'id': record.id,
        ...record.data,
        'customers':
            (record.expand['customers'] as List?)?.map((c) {
              final customerData = c as RecordModel;
              final deliveryStatus =
                  customerData.expand['deliveryUpdates'] as List? ?? [];
              final invoices = customerData.expand['invoices'] as List? ?? [];

              return {
                ...customerData.data,
                'id': customerData.id,
                'deliveryUpdates':
                    deliveryStatus.map((status) => status.data).toList(),
                'invoices':
                    invoices.map((invoice) {
                      final products =
                          invoice.expand['productList'] as List? ?? [];
                      return {
                        ...invoice.data,
                        'id': invoice.id,
                        'productList':
                            products.map((product) => product.data).toList(),
                      };
                    }).toList(),
              };
            }).toList() ??
            [],
        'personels':
            (record.expand['personels'] as List?)
                ?.map((p) => p is RecordModel ? p.data : p)
                .toList() ??
            [],
        'vehicle':
            record.expand['vehicle'] is List
                ? ((record.expand['vehicle'] as List).first as RecordModel).data
                : (record.expand['vehicle'] as RecordModel?)?.data,
        'checklist':
            (record.expand['checklist'] as List?)
                ?.map((c) => c is RecordModel ? c.data : c)
                .toList() ??
            [],
        'isAccepted': record.data['isAccepted'],
      };

      return TripModel.fromJson(mappedData);
    } catch (e) {
      throw ServerException(
        message: 'Failed to load trip: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<TripModel> scanTripByQR(String qrData) async {
    try {
      debugPrint('🔍 REMOTE: Scanning QR code data: $qrData');

      final records = await _pocketBaseClient
          .collection('tripticket')
          .getFullList(
            filter: 'qrCode = "$qrData"',
            expand: 'timeline,personels,checklist,deliveryData,deliveryVehicle',
          );

      if (records.isEmpty) {
        throw ServerException(
          message: 'No trip found for QR code: $qrData',
          statusCode: '404',
        );
      }

      final record = records.first;
      if (record.data['isAccepted'] || record.data['isEndTrip'] == true) {
        throw const ServerException(
          message: 'Trip has already been accepted by another user',
          statusCode: '403',
        );
      }

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

          data['deliveryData'] = _mapDeliveryData(record);

          // Handle date fields
          data['timeAccepted'] = parseDate(record.data['timeAccepted']);
          data['created'] = parseDate(record.data['created']);
          data['updated'] = parseDate(record.data['updated']);
          data['timeEndTrip'] = parseDate(record.data['timeEndTrip']);

          // Handle relations
          data['personels'] = _mapPersonels(record);
          data['checklist'] = _mapChecklist(record);

          // Handle deliveryData if available
          if (record.expand.containsKey('deliveryData') &&
              record.expand['deliveryData'] != null) {
            data['deliveryData'] =
                (record.expand['deliveryData'] as List).map((item) {
                  final deliveryData = item as RecordModel;
                  return {'id': deliveryData.id, ...deliveryData.data};
                }).toList();
          }

          return data;
        } catch (e) {
          debugPrint('⚠️ Error extracting data: $e');
          // Return minimal valid data to avoid further errors
          return {
            'id': record.id,
            'collectionId': record.collectionId,
            'collectionName': record.collectionName,
            'isAccepted': false,
            'isEndTrip': false,
          };
        }
      }

      final mappedData = extractData();

      debugPrint('✅ REMOTE: Trip found for QR code');
      return TripModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ REMOTE: QR scan error: ${e.toString()}');
      throw ServerException(
        message: 'Failed to scan QR code: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<TripModel> searchTripByNumber(String tripNumberId) async {
    try {
      debugPrint('🔍 REMOTE: Searching for trip number: $tripNumberId');

      final records = await _pocketBaseClient
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
            data['personels'] = _mapPersonels(record);
          }

          if (record.expand.containsKey('checklist') &&
              record.expand['checklist'] != null) {
            data['checklist'] = _mapChecklist(record);
          }

          // Handle deliveryData if available
          if (record.expand.containsKey('deliveryData') &&
              record.expand['deliveryData'] != null) {
            data['deliveryData'] = _mapDeliveryData(record);
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

  @override
  Future<(TripModel, String)> acceptTrip(String tripId) async {
    try {
      debugPrint('🔄 Starting trip acceptance flow for ID: $tripId');

      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }
      debugPrint('🎯 Using trip ID: $actualTripId');

      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      Map<String, dynamic> userData = jsonDecode(storedUserData!);
      debugPrint('📦 Parsed user data: $userData');

      final userId = userData['id'];
      if (userId == null || userId.toString().isEmpty) {
        throw const ServerException(
          message: 'Invalid user ID',
          statusCode: '400',
        );
      }
      debugPrint('👤 Using user ID: $userId');

      final userRecord = await _pocketBaseClient
          .collection('users')
          .getOne(userId);
      debugPrint('✅ Found user record: ${userRecord.id}');

      const delay = Duration(milliseconds: 500);

      final tripRecord = await _pocketBaseClient
          .collection('tripticket')
          .getOne(
            actualTripId,
            expand: 'personels,checklist,deliveryData,deliveryVehicle',
          );

      if (tripRecord.data['isAccepted'] == true) {
        throw const ServerException(
          message: 'Trip has already been accepted by another user',
          statusCode: '403',
        );
      }

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

      final checklistItems = [
        {
          'trip': actualTripId,
          'objectName': 'Invoices',
          'isChecked': false,
          'status': 'pending',
          'created': DateTime.now().toIso8601String(),
        },
        {
          'trip': actualTripId,
          'objectName': 'Pushcarts',
          'isChecked': false,
          'status': 'pending',
          'created': DateTime.now().toIso8601String(),
        },
        {
          'trip': actualTripId,
          'objectName': 'BLOWBAGETS',
          'isChecked': false,
          'status': 'pending',
          'created': DateTime.now().toIso8601String(),
        },
      ];

      debugPrint('📝 Creating new checklist items');
      final createdItems = await Future.wait(
        checklistItems.map((item) async {
          final response = await _pocketBaseClient
              .collection('checklist')
              .create(body: item);
          debugPrint('✅ Created checklist item: ${response.id}');
          return response;
        }),
      );

      final checklistIds = createdItems.map((item) => item.id).toList();

      final deliveryTeamRecord = await _pocketBaseClient
          .collection('deliveryTeam')
          .create(
            body: {
              'deliveryVehicle':
                  tripRecord.expand['deliveryVehicle'] is List
                      ? (tripRecord.expand['deliveryVehicle'] as List).first.id
                      : (tripRecord.expand['deliveryVehicle'] as RecordModel?)
                          ?.id,
              'personels':
                  (tripRecord.expand['personels'] as List?)
                      ?.map((p) => (p as RecordModel).id)
                      .toList() ??
                  [],
              'checklist': checklistIds,
              'tripTicket': tripRecord.id,
              'isAccepted': true,
              'activeDeliveries':
                  (tripRecord.expand['deliveryData'] as List?)?.length
                      .toString() ??
                  '0',
            },
          );

      // After assigning delivery team to personnel
      for (var personnel in tripRecord.expand['personels'] as List? ?? []) {
        await Future.delayed(delay);
        await _pocketBaseClient
            .collection('personels')
            .update(
              (personnel as RecordModel).id,
              body: {
                'deliveryTeam': deliveryTeamRecord.id,
                'trip': actualTripId, // Add trip reference to personnel
              },
            );
        debugPrint(
          '✅ Assigned delivery team and trip to personnel: ${personnel.id}',
        );
      }

      final inTransitStatus = await _pocketBaseClient
          .collection('deliveryStatusChoices')
          .getFirstListItem('title = "In Transit"');

      final customers = tripRecord.expand['deliveryData'] as List? ?? [];
      for (var customer in customers) {
        final deliveryUpdateRecord = await _pocketBaseClient
            .collection('deliveryUpdate')
            .create(
              body: {
                'deliveryData': customer.id,
                'status': inTransitStatus.id,
                'title': inTransitStatus.data['title'],
                'subtitle': inTransitStatus.data['subtitle'],
                'created': DateTime.now().toIso8601String(),
                'time': DateTime.now().toIso8601String(),
                'isAssigned': true,
              },
            );

        await _pocketBaseClient
            .collection('deliveryData')
            .update(
              customer.id,
              body: {
                'deliveryUpdates+': [deliveryUpdateRecord.id],
                'invoiceStatus': 'truck',
              },
            );
      }

      final otpRecord = await _pocketBaseClient
          .collection('otp')
          .create(
            body: {
              'otpCode': null,
              'isVerified': false,
              'verifiedAt': null,
              'generatedCode': '123456',
              'trip': tripRecord.id,
              'intransitOdometer': null,
              'created': DateTime.now().toIso8601String(),
              'updated': DateTime.now().toIso8601String(),
            },
          );

      final endTripOtpRecord = await _pocketBaseClient
          .collection('endTripOtp')
          .create(
            body: {
              'otpCode': null,
              'isVerified': false,
              'verifiedAt': null,
              'generatedCode': '123456',
              'trip': tripRecord.id,
              'endTripOdometer': null,
              'created': DateTime.now().toIso8601String(),
              'updated': DateTime.now().toIso8601String(),
              'otpType': 'endDelivery',
            },
          );

      await _pocketBaseClient
          .collection('tripticket')
          .update(
            tripRecord.id,
            body: {
              'isAccepted': true,
              'deliveryTeam': deliveryTeamRecord.id,
              'otp': otpRecord.id,
              'endTripOtp': endTripOtpRecord.id,
              'timeAccepted': DateTime.now().toIso8601String(),
              'checklist': checklistIds,
            },
          );

      await _pocketBaseClient
          .collection('users')
          .update(
            userId,
            body: {
              'tripNumberId': tripRecord.data['tripNumberId'],
              'trip': tripRecord.id,
              'hasTrip': 'true',
              // 'deliveryTeam': deliveryTeamRecord.id,
            },
          );

      // Record trip history in usersTripHistory collection
      debugPrint(
        '📝 Recording trip history for user: $userId and trip: ${tripRecord.id}',
      );
      final userTripHistoryRecord = await _pocketBaseClient
          .collection('usersTripHistory')
          .create(
            body: {
              'users': userId, // Single relation to users collection
              'trips': [
                tripRecord.id,
              ], // List relation to tripticket collection
              'assignedAt': DateTime.now().toIso8601String(),
              'isActive': true,
            },
          );
      debugPrint('✅ Created trip history record: ${userTripHistoryRecord.id}');

      await _pocketBaseClient
          .collection('tripticket')
          .update(tripRecord.id, body: {'user': userId});

      // Update user performance - increment total deliveries
      try {
        debugPrint('📊 Updating user performance for user: $userId');

        // Get current delivery count from the trip
        final deliveryCount =
            (tripRecord.expand['deliveryData'] as List?)?.length ?? 0;
        debugPrint('📦 Current trip delivery count: $deliveryCount');

        if (deliveryCount > 0) {
          // Find user performance record
          final userPerformanceRecords = await _pocketBaseClient
              .collection('userPerformance')
              .getList(filter: 'userId = "$userId"');

          if (userPerformanceRecords.items.isNotEmpty) {
            // Update existing record
            final userPerformanceRecord = userPerformanceRecords.items.first;
            final currentTotalDeliveries =
                userPerformanceRecord.data['totalDeliveries'] ?? 0;
            final newTotalDeliveries =
                (currentTotalDeliveries is String)
                    ? (int.tryParse(currentTotalDeliveries) ?? 0) +
                        deliveryCount
                    : (currentTotalDeliveries as int) + deliveryCount;

            debugPrint(
              '📈 Incrementing total deliveries: $currentTotalDeliveries → $newTotalDeliveries',
            );

            await _pocketBaseClient
                .collection('userPerformance')
                .update(
                  userPerformanceRecord.id,
                  body: {
                    'totalDeliveries': newTotalDeliveries.toString(),
                    'updated': DateTime.now().toIso8601String(),
                  },
                );

            debugPrint('✅ User performance updated successfully');
          } else {
            // Create new user performance record if none exists
            debugPrint('📝 Creating new user performance record');

            await _pocketBaseClient
                .collection('userPerformance')
                .create(
                  body: {
                    'user': userId,

                    'totalDeliveries': deliveryCount.toString(),
                    'successfulDeliveries': '0',
                    'cancelledDeliveries': '0',
                    'deliveryAccuracy': '0',
                    'performanceStatus': 'New',
                    'created': DateTime.now().toIso8601String(),
                    'updated': DateTime.now().toIso8601String(),
                  },
                );

            debugPrint('✅ New user performance record created');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Failed to update user performance: $e');
        // Don't throw error here as trip acceptance should still succeed
      }

      // Safely extract data from the record and ensure all DateTime objects are converted to strings
      Map<String, dynamic> extractData() {
        try {
          final data = {
            'id': tripRecord.id,
            'collectionId': tripRecord.collectionId,
            'collectionName': tripRecord.collectionName,
            ...Map<String, dynamic>.from(tripRecord.data),
            'isAccepted': true,
            'deliveryTeam': _convertRecordToJson(deliveryTeamRecord),
            'deliveryData': _mapDeliveryData(tripRecord),
            'otp': _convertRecordToJson(otpRecord),
            'deliveryVehicle': tripRecord.data['deliveryVehicle'],
            'endTripOtp': _convertRecordToJson(endTripOtpRecord),
            'timeline': _mapTimeline(tripRecord),
            'personels': _mapPersonels(tripRecord),
            'checklist': _mapChecklist(tripRecord),
            'vehicle': _mapVehicle(tripRecord),
            'timeAccepted': DateTime.now().toIso8601String(),
          };

          // Handle date fields - convert all DateTime objects to ISO8601 strings
          if (tripRecord.data['created'] != null) {
            final createdDate = parseDate(tripRecord.data['created']);
            data['created'] = createdDate?.toIso8601String();
          }

          if (tripRecord.data['updated'] != null) {
            final updatedDate = parseDate(tripRecord.data['updated']);
            data['updated'] = updatedDate?.toIso8601String();
          }

          if (tripRecord.data['timeEndTrip'] != null) {
            final timeEndTripDate = parseDate(tripRecord.data['timeEndTrip']);
            data['timeEndTrip'] = timeEndTripDate?.toIso8601String();
          }

          return data;
        } catch (e) {
          debugPrint('⚠️ Error extracting data: $e');
          // Return minimal valid data to avoid further errors
          return {
            'id': tripRecord.id,
            'collectionId': tripRecord.collectionId,
            'collectionName': tripRecord.collectionName,
            'isAccepted': true,
            'deliveryTeam': _convertRecordToJson(deliveryTeamRecord),
            'otp': _convertRecordToJson(otpRecord),
            'endTripOtp': _convertRecordToJson(endTripOtpRecord),
            'timeAccepted': DateTime.now().toIso8601String(),
          };
        }
      }

      final mappedData = extractData();

      // Ensure the data is JSON-serializable before storing
      final jsonString = jsonEncode(mappedData);
      await prefs.setString('user_trip_data', jsonString);
      debugPrint('💾 Cached new trip assignment data');

      final acceptedTripModel = TripModel.fromJson(mappedData);
      await _tripLocalDatasource.autoSaveTrip(acceptedTripModel);

      debugPrint('✅ Trip acceptance completed');
      return (acceptedTripModel, tripRecord.id);
    } catch (e) {
      debugPrint('❌ Error in acceptTrip: $e');
      throw ServerException(
        message: 'Failed to accept trip: $e',
        statusCode: '500',
      );
    }
  }

  List<Map<String, dynamic>> _mapDeliveryData(RecordModel tripRecord) {
    try {
      final deliveryData = tripRecord.expand['deliveryData'] as List? ?? [];
      return deliveryData.map((item) {
        final record = item as RecordModel;
        return _convertRecordToJson(record);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping delivery data: $e');
      return [];
    }
  }

  // Helper methods to ensure JSON-serializable objects
  List<Map<String, dynamic>> _mapTimeline(RecordModel tripRecord) {
    try {
      final timeline = tripRecord.expand['timeline'] as List? ?? [];
      return timeline.map((item) {
        final record = item as RecordModel;
        return _convertRecordToJson(record);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping timeline: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _mapPersonels(RecordModel tripRecord) {
    try {
      final personels = tripRecord.expand['personels'] as List? ?? [];
      return personels.map((item) {
        final record = item as RecordModel;
        return _convertRecordToJson(record);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping personels: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _mapChecklist(RecordModel tripRecord) {
    try {
      final checklist = tripRecord.expand['checklist'] as List? ?? [];
      return checklist.map((item) {
        final record = item as RecordModel;
        return _convertRecordToJson(record);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping checklist: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _mapVehicle(RecordModel tripRecord) {
    try {
      final vehicle = tripRecord.expand['vehicle'] as List? ?? [];
      return vehicle.map((item) {
        final record = item as RecordModel;
        return _convertRecordToJson(record);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping vehicle: $e');
      return [];
    }
  }

  Map<String, dynamic> _convertRecordToJson(RecordModel record) {
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

  @override
  Future<bool> checkEndTripOtpStatus(String tripId) async {
    try {
      debugPrint('🔍 Checking end trip OTP status for trip: $tripId');

      final tripRecord = await _pocketBaseClient
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

  @override
  Future<List<TripModel>> searchTrips({
    String? tripNumberId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAccepted,
    bool? isEndTrip,
    String? deliveryTeamId,
    String? vehicleId,
    String? personnelId,
  }) async {
    try {
      debugPrint('🔍 Starting advanced trip search');

      List<String> filters = [];

      if (tripNumberId != null) {
        filters.add('tripNumberId ~ "$tripNumberId"');
      }
      if (startDate != null) {
        filters.add('created >= "${startDate.toIso8601String()}"');
      }
      if (endDate != null) {
        filters.add('created <= "${endDate.toIso8601String()}"');
      }
      if (isAccepted != null) {
        filters.add('isAccepted = $isAccepted');
      }
      if (isEndTrip != null) {
        filters.add('isEndTrip = $isEndTrip');
      }
      if (deliveryTeamId != null) {
        filters.add('deliveryTeam = "$deliveryTeamId"');
      }
      if (vehicleId != null) {
        filters.add('vehicle = "$vehicleId"');
      }
      if (personnelId != null) {
        filters.add('personels ~ "$personnelId"');
      }

      final filterString = filters.join(' && ');
      debugPrint('🔍 Applied filters: $filterString');

      final records = await _pocketBaseClient
          .collection('tripticket')
          .getFullList(
            filter: filterString,
            expand: 'customers,timeline,personels,vehicle,checklist',
          );

      return records
          .map((record) => TripModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      debugPrint('❌ Search trips error: ${e.toString()}');
      throw ServerException(
        message: 'Failed to search trips: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<TripModel>> getTripsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint(
        '📅 Fetching trips between ${startDate.toIso8601String()} and ${endDate.toIso8601String()}',
      );

      final records = await _pocketBaseClient
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

  @override
  Future<String> calculateTotalTripDistance(String tripId) async {
    try {
      debugPrint('📊 Starting total trip distance calculation');

      // Extract trip ID if we received a JSON object
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🎯 Using trip ID: $actualTripId');

      // Get start odometer from in-transit OTP
      final otpRecords = await _pocketBaseClient
          .collection('otp')
          .getList(filter: 'trip = "$actualTripId"', sort: '-created');

      // Get end odometer from end-trip OTP
      final endTripOtpRecords = await _pocketBaseClient
          .collection('endTripOtp')
          .getList(filter: 'trip = "$actualTripId"', sort: '-created');

      if (otpRecords.items.isEmpty || endTripOtpRecords.items.isEmpty) {
        debugPrint('⚠️ Missing OTP records for distance calculation');
        throw const ServerException(
          message: 'Missing OTP records',
          statusCode: '404',
        );
      }

      final startOdometer =
          otpRecords.items.first.data['intransitOdometer'] ?? '0';
      final endOdometer =
          endTripOtpRecords.items.first.data['endTripOdometer'] ?? '0';

      debugPrint('🔢 Start Odometer: $startOdometer');
      debugPrint('🔢 End Odometer: $endOdometer');

      final totalDistance =
          (int.parse(endOdometer) - int.parse(startOdometer)).toString();
      debugPrint('📏 Calculated total distance: $totalDistance');

      // Update trip with total distance
      await _pocketBaseClient
          .collection('tripticket')
          .update(actualTripId, body: {'totalTripDistance': totalDistance});

      debugPrint('✅ Total trip distance updated successfully');
      return totalDistance;
    } catch (e) {
      debugPrint('❌ Failed to calculate trip distance: $e');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }

  // Add implementation
  @override
  Future<TripModel> getTripById(String id) async {
    try {
      debugPrint('🔄 Fetching trip by ID: $id');
      final record = await _pocketBaseClient
          .collection('tripticket')
          .getOne(
            id,
            expand:
                'customers,customers.deliveryUpdates,customers.invoices(customer),customers.invoices.productList,personels,vehicle,checklist,invoices,invoices.productList,deliveryTeam,deliveryData,deliveryVehicle',
          );

      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        ...record.data,
        'deliveryData':
            (record.expand['deliveryData'] as List?)?.map((c) {
              final customerData = c as RecordModel;
              final deliveryStatus =
                  customerData.expand['deliveryStatus'] as List? ?? [];

              return {
                ...customerData.data,
                'id': customerData.id,
                'deliveryUpdates':
                    deliveryStatus.map((status) => status.data).toList(),
              };
            }).toList() ??
            [],
        'customers':
            (record.expand['customers'] as List?)?.map((c) {
              final customerData = c as RecordModel;
              final deliveryStatus =
                  customerData.expand['deliveryUpdates'] as List? ?? [];
              final invoices = customerData.expand['invoices'] as List? ?? [];

              return {
                ...customerData.data,
                'id': customerData.id,
                'deliveryUpdates':
                    deliveryStatus.map((status) => status.data).toList(),
                'invoices':
                    invoices.map((invoice) {
                      final products =
                          invoice.expand['productList'] as List? ?? [];
                      return {
                        ...invoice.data,
                        'id': invoice.id,
                        'productList':
                            products.map((product) => product.data).toList(),
                      };
                    }).toList(),
              };
            }).toList() ??
            [],
        'invoices':
            (record.expand['invoices'] as List?)?.map((invoice) {
              final invoiceData = invoice as RecordModel;
              return {
                ...invoiceData.data,
                'id': invoiceData.id,
                'productList':
                    invoiceData.expand['productList']
                        ?.map((product) => product.data)
                        .toList() ??
                    [],
              };
            }).toList() ??
            [],
        'timeline': _mapTimeline(record),
        'personels': _mapPersonels(record),
        'checklist': _mapChecklist(record),
        'vehicle': _mapVehicle(record),
        'isAccepted': record.data['isAccepted'],
        'deliveryVehicle': record.data['deliveryVehicle'],
        'timeAccepted': record.data['timeAccepted'],
        'longitude': record.data['longitude'],
        'latitude': record.data['latitude'],
      };

      debugPrint('✅ Trip data retrieved successfully');
      return TripModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error fetching trip: $e');
      throw ServerException(
        message: 'Failed to fetch trip: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<TripModel> endTrip(String tripId) async {
    try {
      debugPrint('🔄 Starting trip end flow for ID: $tripId');

      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }
      debugPrint('🎯 Using trip ID: $actualTripId');

      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      Map<String, dynamic> userData = jsonDecode(storedUserData!);
      debugPrint('📦 Parsed user data: $userData');

      final userId = userData['id'];
      if (userId == null || userId.toString().isEmpty) {
        throw const ServerException(
          message: 'Invalid user ID',
          statusCode: '400',
        );
      }
      debugPrint('👤 Using user ID: $userId');

      final userRecord = await _pocketBaseClient
          .collection('users')
          .getOne(userId);
      debugPrint('✅ Found user record: ${userRecord.id}');

      const delay = Duration(milliseconds: 500);

      final tripRecord = await _pocketBaseClient
          .collection('tripticket')
          .getOne(
            actualTripId,
            expand:
                'customers,timeline,personels,vehicle,checklist,deliveryData,deliveryVehicle',
          );

      // Update trip status
      await Future.delayed(delay);
      await _pocketBaseClient
          .collection('tripticket')
          .update(
            actualTripId,
            body: {
              'isEndTrip': true,
              'timeEndTrip': DateTime.now().toIso8601String(),
              'isAccepted': false,
            },
          );
      debugPrint('✅ Trip status updated');

      // Clear user assignment
      await Future.delayed(delay);
      await _pocketBaseClient
          .collection('users')
          .update(
            userId,
            body: {'tripNumberId': null, 'trip': null, 'deliveryTeam': null},
          );
      debugPrint('✅ User assignment cleared');

      // Clear vehicle assignment
      if (tripRecord.expand['vehicle'] is List) {
        final vehicleId = (tripRecord.expand['vehicle'] as List).first.id;
        await _pocketBaseClient
            .collection('vehicle')
            .update(vehicleId, body: {'deliveryTeam': null, 'trip': null});
        debugPrint('✅ Vehicle assignment cleared');
      }

      // Clear personnel assignments
      for (var personnel in tripRecord.expand['personels'] as List? ?? []) {
        await _pocketBaseClient
            .collection('personels')
            .update(
              (personnel as RecordModel).id,
              body: {'deliveryTeam': null, 'trip': null},
            );
        debugPrint('✅ Personnel assignment cleared');
      }

      final mappedData = {
        'id': tripRecord.id,
        'collectionId': tripRecord.collectionId,
        'collectionName': tripRecord.collectionName,
        ...tripRecord.data,
        'isEndTrip': true,
        'timeEndTrip': DateTime.now().toIso8601String(),
        'timeline': _mapTimeline(tripRecord),
        'personels': _mapPersonels(tripRecord),
        'checklist': _mapChecklist(tripRecord),
        'vehicle': _mapVehicle(tripRecord),
      };

      // Clear stored trip data
      await prefs.remove('user_trip_data');
      debugPrint('🧹 Cleared cached trip data');

      debugPrint('✅ Trip end process completed');
      return TripModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Error in endTrip: $e');
      throw ServerException(
        message: 'Failed to end trip: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<TripModel> updateTripLocation(
    String tripId,
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('🔄 REMOTE: Updating trip location for ID: $tripId');
      debugPrint('📍 Coordinates: Lat: $latitude, Long: $longitude');

      // Extract trip ID if we received a JSON object
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🎯 Using trip ID: $actualTripId');

      // Get the current trip record
      final tripRecord = await _pocketBaseClient
          .collection('tripticket')
          .getOne(
            actualTripId,
            expand: 'customers,timeline,personels,vehicle,checklist',
          );

      // Update the trip with new coordinates
      final updatedRecord = await _pocketBaseClient
          .collection('tripticket')
          .update(
            actualTripId,
            body: {
              'latitude': latitude.toString(),
              'longitude': longitude.toString(),
              'updated': DateTime.now().toIso8601String(),
            },
          );

      // Create a new record in tripCoordinatesUpdates collection
      await _createTripCoordinateUpdate(actualTripId, latitude, longitude);

      debugPrint('✅ Trip location updated successfully');

      // Create a TripModel from the updated record with safe data preparation
      final mappedData = _prepareTripDataSafely(
        tripRecord,
        updatedRecord,
        latitude,
        longitude,
      );
      final updatedTripModel = TripModel.fromJson(mappedData);
      return updatedTripModel;
    } catch (e) {
      debugPrint('❌ Error updating trip location: $e');
      throw ServerException(
        message: 'Failed to update trip location: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  // Safe helper method to prepare trip data with proper type handling
  Map<String, dynamic> _prepareTripDataSafely(
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
        data[key] = _convertValueSafely(key, value);
      });

      // Add expanded relations with safe mapping
      data['timeline'] = _mapTimelineSafely(tripRecord);
      data['personels'] = _mapPersonelsSafely(tripRecord);
      data['checklist'] = _mapChecklistSafely(tripRecord);
      data['vehicle'] = _mapVehicleSafely(tripRecord);

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

  // Safe value conversion method
  dynamic _convertValueSafely(String key, dynamic value) {
    try {
      if (value == null) return null;

      // Handle DateTime objects
      if (value is DateTime) {
        return value.toIso8601String();
      }

      // Handle date fields that might be strings
      if (_isDateField(key)) {
        if (value is String && value.isNotEmpty) {
          final parsedDate = _parseDateSafely(value);
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

  // Enhanced and safer date parsing function
  DateTime? _parseDateSafely(dynamic value) {
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

  // Helper method to check if a field is a date field
  bool _isDateField(String fieldName) {
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

  // Safe mapping methods
  List<Map<String, dynamic>> _mapTimelineSafely(RecordModel tripRecord) {
    try {
      final timeline = tripRecord.expand['timeline'] as List? ?? [];
      return timeline.map((item) {
        if (item is RecordModel) {
          return _convertRecordToJsonSafely(item);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping timeline: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _mapPersonelsSafely(RecordModel tripRecord) {
    try {
      final personels = tripRecord.expand['personels'] as List? ?? [];
      return personels.map((item) {
        if (item is RecordModel) {
          return _convertRecordToJsonSafely(item);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping personels: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _mapChecklistSafely(RecordModel tripRecord) {
    try {
      final checklist = tripRecord.expand['checklist'] as List? ?? [];
      return checklist.map((item) {
        if (item is RecordModel) {
          return _convertRecordToJsonSafely(item);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping checklist: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _mapVehicleSafely(RecordModel tripRecord) {
    try {
      final vehicle = tripRecord.expand['vehicle'] as List? ?? [];
      return vehicle.map((item) {
        if (item is RecordModel) {
          return _convertRecordToJsonSafely(item);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping vehicle: $e');
      return [];
    }
  }

  // Safe record conversion with proper type handling
  Map<String, dynamic> _convertRecordToJsonSafely(RecordModel record) {
    try {
      final data = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
      };

      // Add all data fields with safe conversion
      record.data.forEach((key, value) {
        data[key] = _convertValueSafely(key, value);
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

  // Enhanced trip coordinate update creation with better error handling
  Future<void> _createTripCoordinateUpdate(
    String tripId,
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('🔄 Creating trip coordinate update record');

      final now = DateTime.now();
      final timestamp = now.toIso8601String();

      // Create the record in tripCoordinatesUpdates collection
      await _pocketBaseClient
          .collection('tripCoordinatesUpdates')
          .create(
            body: {
              'trip': tripId,
              'latitude': latitude.toString(),
              'longitude': longitude.toString(),
              'created': timestamp,
              'updated': timestamp,
            },
          );

      debugPrint('✅ Trip coordinate update record created successfully');
    } catch (e) {
      debugPrint('⚠️ Error creating trip coordinate update record: $e');

      try {
        // Attempt a simplified version
        await _pocketBaseClient
            .collection('tripCoordinatesUpdates')
            .create(
              body: {
                'trip': tripId,
                'latitude': latitude.toString(),
                'longitude': longitude.toString(),
                'created': DateTime.now().toIso8601String(),
              },
            );
        debugPrint('✅ Trip coordinate update record created (simplified)');
      } catch (e2) {
        debugPrint('❌ Failed to create coordinate update record: $e2');
      }
    }
  }
}
