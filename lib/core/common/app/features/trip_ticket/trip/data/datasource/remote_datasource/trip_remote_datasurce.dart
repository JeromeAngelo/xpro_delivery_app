import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../delivery_team/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import '../../../../../otp/end_trip_otp/data/model/end_trip_model.dart';
import '../../../../../otp/intransit_otp/data/models/otp_models.dart';
import '../../../../../users/auth/data/models/auth_models.dart';

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
    double longitude, {
    double? accuracy,
    String? source,
    double? totalDistance,
  });

  Future<List<String>> checkTripPersonnels(String tripId);

  // Set mismatched personnel reason in tripticket
  Future<bool> setMismatchedReason(String tripId, String reasonCode);
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
          expand:
              'customers,customers.invoices,customers.deliveryStatus,'
              'deliveryTeam,deliveryTeam.personels,deliveryTeam.vehicle,'
              'personels,vehicle,checklist,'
              'returnList,completedCustomer,undeliverableCustomer,'
              'tripUpdates,endTripChecklist,'
              'deliveryData,deliveryData.customer,deliveryData.invoice,'
              'deliveryData.deliveryUpdates,deliveryData.deliveryReceipt,'
              'invoices,invoices.products,invoices.customer,'
              'transactions,transactions.customer,transactions.invoices,'
              'user,deliveryVehicle,'
              'otp,endTripOtp',
        );

    if (records.isEmpty) {
      throw ServerException(
        message: 'No trip found for QR code: $qrData',
        statusCode: '404',
      );
    }

    final record = records.first;
    
    // DEBUG: Print RAW record data BEFORE any mapping
    debugPrint('🔔🔔🔔 RAW POCKETBASE RECORD DEBUG 🔔🔔🔔');
    debugPrint('📌 record.id = ${record.id}');
    debugPrint('📌 record.id type = ${record.id.runtimeType}');
    debugPrint('📌 record.collectionId = ${record.collectionId}');
    debugPrint('📌 record.collectionName = ${record.collectionName}');
    debugPrint('📌 record.data keys = ${record.data.keys.toList()}');
    debugPrint('📌 record.data[tripNumberId] = ${record.data['tripNumberId']}');
    debugPrint('📌 record.data[tripNumberId] type = ${record.data['tripNumberId'].runtimeType}');
    debugPrint('📌 record.data[qrCode] = ${record.data['qrCode']}');
    debugPrint('📌 record.data[qrCode] type = ${record.data['qrCode'].runtimeType}');
    debugPrint('📌 record.data[name] = ${record.data['name']}');
    debugPrint('📌 record.data[id] = ${record.data['id']}');
    debugPrint('📌 Full record.data = ${record.data}');
    debugPrint('🔔🔔🔔 END RAW DEBUG 🔔🔔🔔');

    if (record.data['isAccepted'] == true || record.data['isEndTrip'] == true) {
      throw const ServerException(
        message: 'Trip has already been accepted by another user',
        statusCode: '403',
      );
    }

    // Map record to TripModel using the helper
    debugPrint('🔔 Mapping record to TripModel using helper...');
    final trip = _mapRecordToTripModel(record);

    // Debug top-level fields
    debugPrint('✅ Trip mapping completed:');
    debugPrint('   Trip ID: ${trip.id}');
    debugPrint('   Trip Number ID: ${trip.tripNumberId}');
    debugPrint('   QR Code: ${trip.qrCode}');
    debugPrint('   Delivery Data Count: ${trip.deliveryData.length}');
    debugPrint('   Personnel Count: ${trip.personels.length}');
    debugPrint('   Checklist Count: ${trip.checklist.length}');
   

    // Validate critical fields
    if (trip.id == null || trip.tripNumberId == null) {
      debugPrint('❌ Trip data invalid: Missing ID or tripNumberId');
      throw ServerException(
        message: 'Trip data invalid: Missing ID or tripNumberId',
        statusCode: '500',
      );
    }

    return trip;
  } catch (e, stackTrace) {
    debugPrint('❌ REMOTE: QR scan error: ${e.toString()}');
    debugPrint(stackTrace.toString());
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

    // ---------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------
    String extractTripId(String raw) {
      final t = raw.trim();
      if (t.startsWith('{')) {
        final decoded = jsonDecode(t) as Map<String, dynamic>;
        return (decoded['id'] ?? '').toString();
      }
      return t;
    }

    Future<List<TOut>> _poolMap<TIn, TOut>(
      List<TIn> items,
      int concurrency,
      Future<TOut> Function(TIn item) task,
    ) async {
      final results = <TOut>[];
      var index = 0;

      final workers = List.generate(concurrency, (_) async {
        while (true) {
          final i = index++;
          if (i >= items.length) break;
          results.add(await task(items[i]));
        }
      });

      await Future.wait(workers);
      return results;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final strValue = value.toString().trim();
      if (strValue.isEmpty) return null;

      try {
        return DateTime.parse(strValue);
      } catch (_) {
        try {
          if (strValue.length >= 10 && RegExp(r'^\d+$').hasMatch(strValue)) {
            var timestamp = int.parse(strValue);
            if (strValue.length == 10) timestamp *= 1000;
            return DateTime.fromMillisecondsSinceEpoch(timestamp);
          }
          return DateTime.now();
        } catch (_) {
          return null;
        }
      }
    }

    // ---------------------------------------------------------
    // 0) Normalize trip id
    // ---------------------------------------------------------
    final actualTripId = extractTripId(tripId);
    debugPrint('🎯 Using trip ID: $actualTripId');

    // ---------------------------------------------------------
    // 1) Read userId fast
    // ---------------------------------------------------------
    final prefs = await SharedPreferences.getInstance();
    final storedUserData = prefs.getString('user_data');

    if (storedUserData == null || storedUserData.trim().isEmpty) {
      throw const ServerException(message: 'Missing user_data', statusCode: '400');
    }

    final userData = jsonDecode(storedUserData) as Map<String, dynamic>;
    final userId = (userData['id'] ?? '').toString().trim();

    if (userId.isEmpty) {
      throw const ServerException(message: 'Invalid user ID', statusCode: '400');
    }
    debugPrint('👤 Using user ID: $userId');

    // ---------------------------------------------------------
    // 2) Fetch user + trip in parallel (faster)
    // ---------------------------------------------------------
    final fetched = await Future.wait([
      _retry(
        () => _pocketBaseClient.collection('users').getOne(userId),
        label: 'GET users/$userId',
      ),
      _retry(
        () => _pocketBaseClient.collection('tripticket').getOne(
              actualTripId,
              expand: 'personels,checklist,deliveryData,deliveryVehicle',
            ),
        label: 'GET tripticket/$actualTripId',
      ),
    ]);

    final userRecord = fetched[0];
    final tripRecord = fetched[1];

    debugPrint('✅ Found user record: ${userRecord.id}');
    debugPrint('✅ Found trip record: ${tripRecord.id}');

    if (tripRecord.data['isAccepted'] == true) {
      throw const ServerException(
        message: 'Trip has already been accepted by another user',
        statusCode: '403',
      );
    }

    // ---------------------------------------------------------
    // 3) Create checklist items (already parallel)
    // ---------------------------------------------------------
    final checklistItems = [
      {
        'trip': actualTripId,
        'objectName': 'Invoices',
        'isChecked': false,
        'status': 'pending',
        'description': 'Check the number of Invoices',
        'created': DateTime.now().toIso8601String(),
      },
      {
        'trip': actualTripId,
        'objectName': 'Pushcarts',
        'isChecked': false,
        'status': 'pending',
        'description': 'Check the number of Pushcarts',
        'created': DateTime.now().toIso8601String(),
      },
      {
        'trip': actualTripId,
        'objectName': 'BLOWBAGETS',
        'isChecked': false,
        'description': 'Follow the BLOWBAGETS instructions for safety',
        'status': 'pending',
        'created': DateTime.now().toIso8601String(),
      },
    ];

    debugPrint('📝 Creating new checklist items');
    final createdItems = await Future.wait(
      checklistItems.map((item) async {
        final response = await _retry(
          () => _pocketBaseClient.collection('checklist').create(body: item),
          label: 'CREATE checklist',
        );
        debugPrint('✅ Remote Created checklist item: ${response.id}');
        return response;
      }),
    );

    final checklistIds = createdItems.map((item) => item.id).toList();

    // ---------------------------------------------------------
    // 4) Create deliveryTeam
    // ---------------------------------------------------------
    final deliveryVehicleId = tripRecord.expand['deliveryVehicle'] is List
        ? (tripRecord.expand['deliveryVehicle'] as List).first.id
        : (tripRecord.expand['deliveryVehicle'] as RecordModel?)?.id;

    final personels = (tripRecord.expand['personels'] as List? ?? []).cast<RecordModel>();
    final customers = (tripRecord.expand['deliveryData'] as List? ?? []).cast<RecordModel>();

    final deliveryTeamRecord = await _retry(
      () => _pocketBaseClient.collection('deliveryTeam').create(
        body: {
          'deliveryVehicle': deliveryVehicleId,
          'personels': personels.map((p) => p.id).toList(),
          'checklist': checklistIds,
          'tripTicket': tripRecord.id,
          'isAccepted': true,
          'activeDeliveries': customers.length.toString(),
        },
      ),
      label: 'CREATE deliveryTeam',
    );

    debugPrint('✅ deliveryTeam created: ${deliveryTeamRecord.id}');

    // ---------------------------------------------------------
    // 5) Update ALL personels in parallel (REMOVE delay)
    // ---------------------------------------------------------
    if (personels.isNotEmpty) {
      debugPrint('🧑‍🔧 Updating personels: ${personels.length}');

      await _poolMap<RecordModel, void>(
        personels,
        6, // safe concurrency to avoid PB resets
        (personnel) async {
          await _retry(
            () => _pocketBaseClient.collection('personels').update(
              personnel.id,
              body: {'deliveryTeam': deliveryTeamRecord.id, 'trip': actualTripId},
            ),
            label: 'UPDATE personels/${personnel.id}',
          );
        },
      );

      debugPrint('✅ All personels updated');
    }

    // ---------------------------------------------------------
    // 6) Fetch In Transit status once
    // ---------------------------------------------------------
    final inTransitStatus = await _retry(
      () => _pocketBaseClient
          .collection('deliveryStatusChoices')
          .getFirstListItem('title = "In Transit"'),
      label: 'GET deliveryStatusChoices In Transit',
    );

    // ---------------------------------------------------------
    // 7) For each customer: create deliveryUpdate + update deliveryData (parallel)
    // ---------------------------------------------------------
    if (customers.isNotEmpty) {
      debugPrint('📦 Creating delivery updates for customers: ${customers.length}');

      await _poolMap<RecordModel, void>(
        customers,
        6, // safe concurrency
        (customer) async {
          final deliveryUpdateRecord = await _retry(
            () => _pocketBaseClient.collection('deliveryUpdate').create(
              body: {
                'deliveryData': customer.id,
                'status': inTransitStatus.id,
                'title': inTransitStatus.data['title'],
                'subtitle': inTransitStatus.data['subtitle'],
                'created': DateTime.now().toIso8601String(),
                'time': DateTime.now().toIso8601String(),
                'isAssigned': true,
              },
            ),
            label: 'CREATE deliveryUpdate',
          );

          await _retry(
            () => _pocketBaseClient.collection('deliveryData').update(
              customer.id,
              body: {
                'deliveryUpdates+': [deliveryUpdateRecord.id],
                'invoiceStatus': 'truck',
              },
            ),
            label: 'UPDATE deliveryData/${customer.id}',
          );
        },
      );

      debugPrint('✅ Delivery updates + deliveryData updates finished');
    }

    // ---------------------------------------------------------
    // 8) Create OTP + EndTripOTP in parallel
    // ---------------------------------------------------------
    final otpResults = await Future.wait([
      _retry(
        () => _pocketBaseClient.collection('otp').create(
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
        ),
        label: 'CREATE otp',
      ),
      _retry(
        () => _pocketBaseClient.collection('endTripOtp').create(
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
        ),
        label: 'CREATE endTripOtp',
      ),
    ]);

    final otpRecord = otpResults[0];
    final endTripOtpRecord = otpResults[1];

    // ---------------------------------------------------------
    // 9) Create tripUpdates + attach (keep your flow)
    // ---------------------------------------------------------
    final tripUpdateRecord = await _retry(
      () => _pocketBaseClient.collection('tripUpdates').create(
        body: {
          'description': 'Start of trip',
          'date': DateTime.now().toIso8601String(),
          'trip': tripRecord.id,
          'status': 'generalUpdate',
          'latitude': 15.0531273,
          'longitude': 120.7067068,
        },
      ),
      label: 'CREATE tripUpdates Start of trip',
    );

    await _retry(
      () => _pocketBaseClient.collection('tripticket').update(
        tripRecord.id,
        body: {'trip_update_list+': [tripUpdateRecord.id]},
      ),
      label: 'UPDATE tripticket attach trip_update_list',
    );

    // ---------------------------------------------------------
    // 10) Update tripticket + update user in parallel
    // ---------------------------------------------------------
    await Future.wait([
      _retry(
        () => _pocketBaseClient.collection('tripticket').update(
          tripRecord.id,
          body: {
            'isAccepted': true,
            'user': userId,
            'deliveryTeam': deliveryTeamRecord.id,
            'otp': otpRecord.id,
            'endTripOtp': endTripOtpRecord.id,
            'timeAccepted': DateTime.now().toIso8601String(),
            'checklist': checklistIds,
          },
        ),
        label: 'UPDATE tripticket/${tripRecord.id}',
      ),
      _retry(
        () => _pocketBaseClient.collection('users').update(
          userId,
          body: {
            'tripNumberId': tripRecord.data['tripNumberId'],
            'trip': tripRecord.id,
            'hasTrip': 'true',
          },
        ),
        label: 'UPDATE users/$userId',
      ),
    ]);

    // ---------------------------------------------------------
    // 11) Sync userData once, update prefs fast
    // ---------------------------------------------------------
    final syncedUser = await _retry(
      () => syncUserData(userId),
      label: 'syncUserData users/$userId (expand)',
      maxAttempts: 4,
    );

    final existingPrefsUser = jsonDecode(storedUserData) as Map<String, dynamic>;
    final updatedPrefsUserData = {
      ...existingPrefsUser,
      'id': userId,
      'name': syncedUser.name ?? existingPrefsUser['name'] ?? '',
      'email': syncedUser.email ?? existingPrefsUser['email'] ?? '',
      'tripNumberId': syncedUser.tripNumberId ?? '',
      'hasTrip': true,
      'trip': {
        'id': tripRecord.id,
        'tripNumberId': tripRecord.data['tripNumberId'],
      },
      'timestamp': DateTime.now().toIso8601String(),
    };

    await prefs.setString('user_data', jsonEncode(updatedPrefsUserData));

    // ---------------------------------------------------------
    // 12) usersTripHistory (keep)
    // ---------------------------------------------------------
    await _retry(
      () => _pocketBaseClient.collection('usersTripHistory').create(
        body: {
          'users': userId,
          'trips': [tripRecord.id],
          'assignedAt': DateTime.now().toIso8601String(),
          'isActive': true,
        },
      ),
      label: 'CREATE usersTripHistory',
    );

    // ---------------------------------------------------------
    // 13) Build mapped trip cache (keep your mapper)
    // ---------------------------------------------------------
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
          'trip_update_list': _mapTripUpdates(tripRecord),
          'personels': _mapPersonels(tripRecord),
          'checklist': _mapChecklist(tripRecord),
          'timeAccepted': DateTime.now().toIso8601String(),
        };

        if (tripRecord.data['created'] != null) {
          data['created'] = parseDate(tripRecord.data['created'])?.toIso8601String();
        }
        if (tripRecord.data['updated'] != null) {
          data['updated'] = parseDate(tripRecord.data['updated'])?.toIso8601String();
        }
        if (tripRecord.data['timeEndTrip'] != null) {
          data['timeEndTrip'] =
              parseDate(tripRecord.data['timeEndTrip'])?.toIso8601String();
        }
        if (tripRecord.data['deliveryDate'] != null) {
          data['deliveryDate'] = parseDate(tripRecord.data['deliveryDate'])?.toIso8601String();
        }

        return data;
      } catch (e) {
        debugPrint('⚠️ Error extracting data: $e');
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
    await prefs.setString('user_trip_data', jsonEncode(mappedData));

    final acceptedTripModel = TripModel.fromJson(mappedData);

    // ✅ final sync (keep but do once)
    await _retry(
      () => syncUserTripData(userId),
      label: 'syncUserTripData',
      maxAttempts: 4,
    );

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



  Future<LocalUsersModel> syncUserData(String userId) async {
    try {
      debugPrint('🔄 Syncing user data from remote for ID: $userId');

      final userRecord = await _pocketBaseClient
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

  
  Future<TripModel> syncUserTripData(String userId) async {
    try {
      debugPrint('🔄 [SYNC] Starting user trip sync for user: $userId');

      // 1️⃣ Fetch user & trip
      debugPrint('📡 Fetching user record...');
      final userRecord = await _pocketBaseClient
          .collection('users')
          .getOne(userId, expand: 'trip');

      debugPrint('🧩 USER RAW DATA: ${jsonEncode(userRecord.data)}');
      debugPrint('🧩 USER EXPAND KEYS: ${userRecord.expand.keys.toList()}');

   final expandedTrip = userRecord.expand['trip'];

if (expandedTrip == null || expandedTrip.isEmpty) {
  debugPrint('ℹ️ No trip assigned to user (normal). Clearing local trip cache.');

  final prefs = await SharedPreferences.getInstance();

  // Clear trip cache so UI doesn’t render stale trip
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
      debugPrint('🆔 User’s Trip ID: $tripId');

      // 2️⃣ Fetch FULL expanded trip including relations
      debugPrint('📡 Fetching full trip from PocketBase...');
      final fullTripList = await _pocketBaseClient
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
debugPrint('📦 Delivery Data Count: ${deliveryDataList.length} (with invoiceItems)');

for (final d in deliveryDataList) {
  // Basic delivery info
  debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  debugPrint('➡️ DeliveryData ID: ${d.id}');
  debugPrint('   🔑 DeliveryData expand keys: ${d.expand.keys.toList()}');

  // -----------------------------
  // Customer (expand)
  // -----------------------------
  final customerRec =
      (d.expand['customer'] != null) ? (d.expand['customer'] as List).firstOrNull : null;

  if (customerRec == null) {
    debugPrint('   👤 customer: ❌ NULL / not expanded');
    d.data['customer'] = null;
  } else {
    debugPrint(
      '   👤 customer: ✅ id=${customerRec.id} | name=${customerRec.data['name']}',
    );
    d.data['customer'] = _mapExpandedRecord(customerRec);
  }

  // -----------------------------
  // Trip (expand)
  // -----------------------------
  final tripRec =
      (d.expand['trip'] != null) ? (d.expand['trip'] as List).firstOrNull : null;

  if (tripRec == null) {
    debugPrint('   🎫 trip: ❌ NULL / not expanded');
    d.data['trip'] = null;
  } else {
    debugPrint(
      '   🎫 trip: ✅ id=${tripRec.id} | name=${tripRec.data['name']}',
    );
    d.data['trip'] = _mapExpandedRecord(tripRec);
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
  d.data['invoices'] = invoices.map(_mapExpandedRecord).toList();

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
  d.data['deliveryUpdates'] = updates.map(_mapExpandedRecord).toList();

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
  d.data['invoiceItems'] = invoiceItems.map(_mapExpandedRecord).toList();

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
      debugPrint('📦 Cancelled Invoices Data Count: ${cancelledInvoiceList.length}');
      for (var d in cancelledInvoiceList) {
        debugPrint('   ➡️ CancelledInvoice ID: ${d.id}');
        final customer =
            (d.expand['customer'] != null)
                ? (d.expand['customer'] as List).firstOrNull
                : null;
        d.data['customer'] =
            customer != null ? _mapExpandedRecord(customer) : null;
             final deliveryData =
            (d.expand['deliveryData'] != null)
                ? (d.expand['deliveryData'] as List).firstOrNull
                : null;
        d.data['deliveryData'] =
            deliveryData != null ? _mapExpandedRecord(deliveryData) : null;
             final trip =
            (d.expand['trip'] != null)
                ? (d.expand['trip'] as List).firstOrNull
                : null;
        d.data['trip'] =
            trip != null ? _mapExpandedRecord(trip) : null;

        final invoices = d.expand['invoices'] as List? ?? [];
        d.data['invoices'] = invoices.map(_mapExpandedRecord).toList();

       
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
            vehicleRecord != null ? _mapExpandedRecord(vehicleRecord) : null;
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
          ..._mapExpandedRecord(deliveryTeamRecord),
          'deliveryVehicle': mappedVehicle,
          'personels': _mapExpandedRecord(teamPersonels),
          'checklist': _mapExpandedRecord(teamChecklist),
        };
      }

      // 5️⃣ Extract other relations
      final personels = tripRecord.expand['personels'] ?? [];
      final vehicle = tripRecord.expand['deliveryVehicle']?.firstOrNull;
      final checklistList = tripRecord.expand['checklist'] ?? [];
      final tripUpdateList = tripRecord.expand['trip_update_list'] ?? [];
     // final cancelledInvoiceList = tripRecord.expand['cancelledInvoice'] ?? [];
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
        'personels': _mapExpandedRecord(personels),
        'deliveryVehicle': _mapExpandedRecord(vehicle),
        'checklist': _mapExpandedRecord(checklistList),
        'deliveryData': _mapExpandedRecord(deliveryDataList),
        'cancelledInvoice': _mapExpandedRecord(cancelledInvoiceList),
        'trip_update_list' : _mapExpandedRecord(tripUpdateList),
        'intransitOtp' : _mapExpandedRecord(intransitOtp),
        'endTripOtp' : _mapExpandedRecord(endTripOtp),
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
//final prefs = await SharedPreferences.getInstance();
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

  dynamic _mapExpandedRecord(dynamic record) {
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
            'created': _formatDateField(r.created),
            'updated': _formatDateField(r.updated),
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
        'created': _formatDateField(record.created),
        'updated': _formatDateField(record.updated),
        ...dataMap,
      };
    }

    if (record is Map<String, dynamic>) return record;

    return null;
  }


  // ADDED: Helper method to safely format date fields
  String? _formatDateField(dynamic dateValue) {
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
          return _timestampToIso(numeric);
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
        return _timestampToIso(dateValue);
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

  /// Helper: Converts timestamps (in ms or s) → ISO8601 string
  String _timestampToIso(int timestamp) {
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
  List<Map<String, dynamic>> _mapTripUpdates(RecordModel tripRecord) {
    try {
      final timeline = tripRecord.expand['trip_update_list'] as List? ?? [];
      return timeline.map((item) {
        final record = item as RecordModel;
        return _convertRecordToJson(record);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Error mapping trip Updates: $e');
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
        'trip_update_list': _mapTripUpdates(record),
        'personels': _mapPersonels(record),
        'checklist': _mapChecklist(record),
        'isAccepted': record.data['isAccepted'],
        'deliveryVehicle': record.data['deliveryVehicle'],
        'timeAccepted': record.data['timeAccepted'],
        'name': record.data['name'],
        'deliveryDate': record.data['deliveryDate'],
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
              'customers,deliveryTeam,deliveryTeam.personels,deliveryTeam.deliveryVehicle,deliveryTeam.checklist,personels,deliveryVehicle,checklist,deliveryData.customer,deliveryData.invoices,deliveryData.deliveryUpdates',
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

      // Clear personnel assignments and update isAssigned status
      final personnelsList = tripRecord.expand['personels'] as List? ?? [];
      debugPrint(
        '🔄 Processing ${personnelsList.length} personnel assignments',
      );

      for (var personnel in personnelsList) {
        final personnelRecord = personnel as RecordModel;
        await _pocketBaseClient
            .collection('personels')
            .update(
              personnelRecord.id,
              body: {'deliveryTeam': null, 'trip': null, 'isAssigned': false},
            );
        debugPrint(
          '✅ Personnel ${personnelRecord.id} assignment cleared and isAssigned set to false',
        );
      }

      // Additionally, process any personnel IDs directly from tripticket data if expand failed
      final personnelsFromData = tripRecord.data['personels'];
      if (personnelsFromData != null) {
        List<String> personnelIds = [];

        if (personnelsFromData is List) {
          personnelIds = personnelsFromData.cast<String>();
        } else if (personnelsFromData is String &&
            personnelsFromData.isNotEmpty) {
          personnelIds = [personnelsFromData];
        }

        debugPrint(
          '🔄 Processing ${personnelIds.length} additional personnel IDs from data',
        );

        for (String personnelId in personnelIds) {
          try {
            // Check if this personnel ID wasn't already processed in the expand
            final alreadyProcessed = personnelsList.any(
              (p) => (p as RecordModel).id == personnelId,
            );

            if (!alreadyProcessed) {
              await _pocketBaseClient
                  .collection('personels')
                  .update(
                    personnelId,
                    body: {
                      'deliveryTeam': null,
                      'trip': null,
                      'isAssigned': false,
                    },
                  );
              debugPrint(
                '✅ Additional personnel $personnelId assignment cleared and isAssigned set to false',
              );
            }
          } catch (e) {
            debugPrint('⚠️ Failed to update personnel $personnelId: $e');
            // Continue processing other personnel even if one fails
          }
        }
      }

      final mappedData = {
        'id': tripRecord.id,
        'collectionId': tripRecord.collectionId,
        'collectionName': tripRecord.collectionName,
        ...tripRecord.data,
        'isEndTrip': true,
        'timeEndTrip': DateTime.now().toIso8601String(),
        'trip_update_list': _mapTripUpdates(tripRecord),
        'personels': _mapPersonels(tripRecord),
        'checklist': _mapChecklist(tripRecord),
      };

      // Clear stored trip data
      await prefs.remove('user_trip_data');
      debugPrint('🧹 Cleared cached trip data');

      // ✅ STEP — Sync user again from remote (expand) then cache locally
// ---------------------------------------------------------
final syncedUser = await _retry(
  () => syncUserData(userId),
  label: 'syncUserData users/$userId (expand)',
  maxAttempts: 4,
);

debugPrint('✅ Remote user re-synced after trip assignment');
debugPrint('   👤 name=${syncedUser.name}');
debugPrint('   🎫 tripNumberId=${syncedUser.tripNumberId}');
debugPrint('   🛣 trip=${syncedUser.trip.target?.id ?? 'NO TRIP'}');


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
  double longitude, {
  double? accuracy,
  String? source,
  double? totalDistance,
}) async {
  try {
    debugPrint('🔄 REMOTE: Updating enhanced trip location for ID: $tripId');
    debugPrint(
      '📍 Coordinates: Lat: ${latitude.toStringAsFixed(6)}, Long: ${longitude.toStringAsFixed(6)}',
    );
    debugPrint(
      '🎯 Accuracy: ${accuracy?.toStringAsFixed(2) ?? 'Unknown'} meters',
    );
    debugPrint('📡 Source: ${source ?? 'GPS_Enhanced'}');

    // Extract trip ID if it's a JSON string
    String actualTripId;
    if (tripId.startsWith('{')) {
      final tripData = jsonDecode(tripId);
      actualTripId = tripData['id'];
    } else {
      actualTripId = tripId;
    }

    debugPrint('🎯 Using trip ID: $actualTripId');

    RecordModel? tripRecord;

    // Try fetching by actual PB trip ID
    try {
      tripRecord = await _pocketBaseClient
          .collection('tripticket')
          .getOne(
            actualTripId,
            expand:               'customers,deliveryTeam,deliveryTeam.personels,deliveryTeam.deliveryVehicle,deliveryTeam.checklist,personels,deliveryVehicle,checklist,deliveryData.customer,deliveryData.invoices,deliveryData.deliveryUpdates',

          );
    } catch (e) {
      debugPrint('⚠️ Failed to get trip by PB ID: $e');
      // Fallback: try finding by tripNumberId
      debugPrint('🔍 Attempting fallback by tripNumberId...');
      final filterRecords = await _pocketBaseClient
          .collection('tripticket')
          .getFullList(
            filter: 'tripNumberId="$actualTripId"',
          );

      if (filterRecords.isEmpty) {
        debugPrint('❌ No trip found with tripNumberId=$actualTripId');
        throw ServerException(
          message: 'Trip not found using tripNumberId: $actualTripId',
          statusCode: '404',
        );
      }

      tripRecord = filterRecords.first;
      actualTripId = tripRecord.id;
      debugPrint('✅ Fallback succeeded, using PB ID: $actualTripId');
    }

    // Update the trip with new coordinates and accuracy info
    final updatedRecord = await _pocketBaseClient
        .collection('tripticket')
        .update(
          actualTripId,
          body: {
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
            'locationAccuracy': accuracy?.toString() ?? '0',
            'locationSource': source ?? 'GPS_Enhanced',
            'updated': DateTime.now().toIso8601String(),
          },
        );

    // Use total distance passed from the LocationService
    final distanceToRecord = totalDistance ?? 0.0;
    debugPrint(
      '📊 REMOTE: Using total distance for recording: ${distanceToRecord.toStringAsFixed(3)} km',
    );

    // Create enhanced record in tripCoordinatesUpdates collection
    await _createTripCoordinateUpdate(
      actualTripId,
      latitude,
      longitude,
      accuracy: accuracy,
      source: source,
      totalDistance: distanceToRecord,
    );

    debugPrint('✅ Trip location updated successfully');

    // Prepare TripModel from updated record
    final mappedData = _prepareTripDataSafely(
      tripRecord,
      updatedRecord,
      latitude,
      longitude,
    );
    return TripModel.fromJson(mappedData);
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

  // Enhanced trip coordinate update creation with distance tracking
  Future<void> _createTripCoordinateUpdate(
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
      await _pocketBaseClient
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
      await _updateDeliveryTeamDistance(tripId, totalDistance);
    } catch (e) {
      debugPrint(
        '⚠️ REMOTE: Error creating enhanced coordinate update record: $e',
      );

      try {
        // Attempt a simplified version with minimal required fields
        await _pocketBaseClient
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
        await _updateDeliveryTeamDistance(tripId, totalDistance);
      } catch (e2) {
        debugPrint(
          '❌ REMOTE: Failed to create coordinate update record (both attempts): $e2',
        );
      }
    }
  }

  // Update delivery team total distance traveled
  Future<void> _updateDeliveryTeamDistance(
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
      final deliveryTeamRecords = await _pocketBaseClient
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
      await _pocketBaseClient
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

  @override
  Future<List<String>> checkTripPersonnels(String tripId) async {
    try {
      debugPrint('🔍 REMOTE: Checking trip personnels for tripId: $tripId');

      // Step 1: Get the current logged-in user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      if (storedUserData == null) {
        throw const ServerException(
          message: 'No user data found. Please log in again.',
          statusCode: '401',
        );
      }

      final userData = jsonDecode(storedUserData);
      final currentUserId = userData['id'];
      debugPrint('👤 Current logged-in user ID: $currentUserId');

      // Step 2: Get the tripticket record with expanded personnel data to get more details
      final tripRecord = await _pocketBaseClient
          .collection('tripticket')
          .getOne(tripId, expand: 'personels');

      // Step 3: Extract personnel IDs from the "personels" field as a list
      final personnelIds = tripRecord.data['personels'] as List? ?? [];
      debugPrint(
        '👥 Found ${personnelIds.length} personnel IDs in trip: $personnelIds',
      );

      if (personnelIds.isEmpty) {
        throw const ServerException(
          message: 'No personnel assigned to this trip',
          statusCode: '404',
        );
      }

      // Step 4: Check each personnel record to find matching user ID
      bool userFound = false;
      List<String> matchedPersonnelIds = [];

      debugPrint('🔍 Starting personnel verification...');
      debugPrint('   Looking for user ID: $currentUserId');
      debugPrint('   Total personnel to check: ${personnelIds.length}');

      for (int i = 0; i < personnelIds.length; i++) {
        String personnelId = personnelIds[i];
        try {
          debugPrint(
            '🔍 [${'$i'.padLeft(2)}/${personnelIds.length}] Checking personnel ID: $personnelId',
          );

          // Get the personnel record from "personel" collection
          final personnelRecord = await _pocketBaseClient
              .collection('personels')
              .getOne(personnelId);

          final personnelData = personnelRecord.data;
          final personnelUserId = personnelData['user'];
          final personnelName = personnelData['name'] ?? 'Unknown';
          final personnelRole = personnelData['role'] ?? 'Unknown';

          debugPrint('   Personnel Details:');
          debugPrint('     - ID: $personnelId');
          debugPrint('     - Name: $personnelName');
          debugPrint('     - Role: $personnelRole');
          debugPrint('     - User ID: $personnelUserId');
          debugPrint('     - User ID Type: ${personnelUserId.runtimeType}');
          debugPrint(
            '     - Current User ID Type: ${currentUserId.runtimeType}',
          );

          // Convert both to strings for comparison to handle type mismatches
          final personnelUserIdStr = personnelUserId?.toString();
          final currentUserIdStr = currentUserId?.toString();

          debugPrint(
            '     - Personnel User ID (String): "$personnelUserIdStr"',
          );
          debugPrint('     - Current User ID (String): "$currentUserIdStr"');

          // Check if this personnel's user ID matches the current user
          if (personnelUserIdStr != null &&
              currentUserIdStr != null &&
              personnelUserIdStr == currentUserIdStr) {
            debugPrint(
              '✅ MATCH FOUND! Personnel $personnelId ($personnelName) belongs to current user',
            );
            debugPrint(
              '   ✓ Personnel User ID: "$personnelUserIdStr" == Current User ID: "$currentUserIdStr"',
            );
            userFound = true;
            matchedPersonnelIds.add(personnelId);
          } else {
            debugPrint(
              '❌ No match for personnel $personnelId ($personnelName)',
            );
            debugPrint(
              '   ✗ Personnel User ID: "$personnelUserIdStr" != Current User ID: "$currentUserIdStr"',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error checking personnel $personnelId: $e');
          debugPrint(
            '   This personnel record may be corrupted or inaccessible',
          );
          continue; // Continue checking other personnel
        }
      }

      debugPrint('🔍 Personnel verification summary:');
      debugPrint('   - Total personnel checked: ${personnelIds.length}');
      debugPrint('   - Matches found: ${matchedPersonnelIds.length}');
      debugPrint('   - User authorized: $userFound');

      if (!userFound) {
        final errorMessage =
            'User $currentUserId is not assigned as personnel to this trip.\n'
            'Trip has ${personnelIds.length} personnel assigned, but none match your user ID.\n'
            'Please contact your supervisor to verify your assignment to this trip.';

        debugPrint('❌ AUTHORIZATION FAILED: $errorMessage');
        throw ServerException(message: errorMessage, statusCode: '403');
      }

      debugPrint(
        '✅ REMOTE: User authorized! Found ${matchedPersonnelIds.length} matching personnel records',
      );
      debugPrint('   Matched Personnel IDs: $matchedPersonnelIds');

      return matchedPersonnelIds;
    } catch (e) {
      debugPrint('❌ REMOTE: Error checking trip personnels: $e');
      throw ServerException(
        message:
            e is ServerException
                ? e.message
                : 'Failed to check trip personnels: $e',
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }

  @override
  Future<bool> setMismatchedReason(String tripId, String reasonCode) async {
    try {
      debugPrint(
        '📝 REMOTE: Setting mismatched personnel reason for trip: $tripId',
      );
      debugPrint('   📋 Reason Code: $reasonCode');

      // Update the tripticket record with the chosen reason
      await _pocketBaseClient
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

 // Helper method to map a record to a TripModel
  TripModel _mapRecordToTripModel(RecordModel record) {
    try {
      debugPrint('🔄 Mapping record to TripModel: ${record.id}');
      
      // Debug the raw record data first
      debugPrint('📋 Raw record.id: ${record.id}');
      debugPrint('📋 Raw record.data keys: ${record.data.keys.toList()}');
      debugPrint('📋 Raw tripNumberId from data: ${record.data['tripNumberId']}');
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

      // Handle delivery vehicle - Use helper function to map expanded data
      final vehicleJsonData = _mapExpandedItem(
        record.expand['deliveryVehicle'],
      );
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
      final otpJsonData = _mapExpandedItem(record.expand['otp']);
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
      final endTripOtpJsonData = _mapExpandedItem(record.expand['endTripOtp']);
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
        'id': record.id, // PocketBase record ID - MUST use record.id, not record.data['id']
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        // Safely extract string fields that might have wrong types in record.data
        'tripNumberId': safeString(record.data['tripNumberId']),
        'qrCode': safeString(record.data['qrCode']),
        'name': safeString(record.data['name']),
        // Expanded relations
        'customers': _mapExpandedList(record.expand['customers']),
        'deliveryTeam': _mapExpandedItem(record.expand['deliveryTeam']),
        'personels': _mapExpandedList(record.expand['personels']),
        'deliveryVehicle': vehicleModel,
        'otp': otpData,
        'endTripOtp': endTripOtpData,
        'deliveryData': _mapExpandedList(record.expand['deliveryData']),
        'dispatcher': record.data['dispatcher'],
        'checklist': _mapExpandedList(record.expand['checklist']),
        'endTripChecklists': _mapExpandedList(
          record.expand['endTripChecklists'],
        ),
        'trip_update_list': _mapExpandedList(record.expand['trip_update_list']),
        // Dates - use parsed values
        'created': record.created,
        'updated': record.updated,
        'timeAccepted': timeAccepted?.toIso8601String(),
        'timeEndTrip': timeEndTrip?.toIso8601String(),
        'deliveryDate': deliveryDate?.toIso8601String(),
        'expectedReturnDate': expectedReturnDate?.toIso8601String(),
        // Other fields
        'longitude': record.data['longitude'],
        'latitude': record.data['latitude'],
        'volumeRate': record.data['volumeRate'],
        'weightRate': record.data['weightRate'],
        'averageFillRate': record.data['averageFillRate'],
      };

      // Debug the final mapped data
      debugPrint('📦 Final mappedData id: ${mappedData['id']}');
      debugPrint('📦 Final mappedData tripNumberId: ${mappedData['tripNumberId']}');
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

  // Helper method to map expanded list items
  List<Map<String, dynamic>> _mapExpandedList(dynamic records) {
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

  // Helper method to map a single expanded item
  Map<String, dynamic>? _mapExpandedItem(dynamic record) {
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
  
Future<T> _retry<T>(
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
        debugPrint('❌${label != null ? " [$label]" : ""} Retry stopped (attempt $attempt/$maxAttempts): $e');
        rethrow;
      }

      // exponential backoff + small jitter
      final expMs = (initialDelay.inMilliseconds * pow(backoffFactor, attempt - 1)).toInt();
      final jitterMs = rng.nextInt(150); // 0..149ms
      final delayMs = min(expMs + jitterMs, maxDelay.inMilliseconds);

      debugPrint('🔁${label != null ? " [$label]" : ""} Retry $attempt/$maxAttempts after ${delayMs}ms بسبب error: $e');
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }
}
 
}
