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
          .getList(
            expand:
                'customers,customers.deliveryStatus,customers.invoices(customer),customers.invoices.productList,personels,vehicle,checklist,invoices',
          );

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
                  customerData.expand['deliveryStatus'] as List? ?? [];
              final invoices = customerData.expand['invoices'] as List? ?? [];

              return {
                ...customerData.data,
                'id': customerData.id,
                'deliveryStatus':
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
            expand: 'customers,timeline,personels,vehicle,checklist',
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

      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        ...record.data,
        'timeline': _mapTimeline(record),
        'personels': _mapPersonels(record),
        'checklist': _mapChecklist(record),
        'vehicle': _mapVehicle(record),
        'isAccepted': record.data['isAccepted'],
        'timeAccepted': record.data['timeAccepted'],
      };

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
                'customers,customers.deliveryStatus,personels,vehicle,checklist',
          );

      if (records.isEmpty) {
        throw ServerException(
          message: 'Trip number $tripNumberId not found or already assigned',
          statusCode: '404',
        );
      }

      final record = records.first;
      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        ...record.data,
        'customers':
            (record.expand['customers'] as List?)?.map((c) {
              final customerData = c as RecordModel;
              return {
                'id': customerData.id,
                ...customerData.data,
                'expand': {
                  'deliveryStatus':
                      customerData.expand['deliveryStatus']
                          ?.map((status) => (status).data)
                          .toList() ??
                      [],
                },
              };
            }).toList() ??
            [],
        'personels': _mapPersonels(record),
        'checklist': _mapChecklist(record),
        'vehicle': _mapVehicle(record),
        'isAccepted': record.data['isAccepted'],
        'timeAccepted': record.data['timeAccepted'],
      };

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
            expand: 'customers,timeline,personels,vehicle,checklist',
          );

      if (tripRecord.data['isAccepted'] == true) {
        throw const ServerException(
          message: 'Trip has already been accepted by another user',
          statusCode: '403',
        );
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
          .collection('delivery_team')
          .create(
            body: {
              'vehicle':
                  tripRecord.expand['vehicle'] is List
                      ? (tripRecord.expand['vehicle'] as List).first.id
                      : (tripRecord.expand['vehicle'] as RecordModel?)?.id,
              'personels':
                  (tripRecord.expand['personels'] as List?)
                      ?.map((p) => (p as RecordModel).id)
                      .toList() ??
                  [],
              'checklist': checklistIds,
              'tripTicket': tripRecord.id,
              'isAccepted': true,
              'activeDeliveries':
                  (tripRecord.expand['customers'] as List?)?.length
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
                'delivery_team': deliveryTeamRecord.id,
                'trip': actualTripId, // Add trip reference to personnel
              },
            );
        debugPrint(
          '✅ Assigned delivery team and trip to personnel: ${personnel.id}',
        );
      }

      // After assigning delivery team to vehicle
      if (tripRecord.expand['vehicle'] is List) {
        await Future.delayed(delay);
        final vehicleId = (tripRecord.expand['vehicle'] as List).first.id;
        await _pocketBaseClient
            .collection('vehicle')
            .update(
              vehicleId,
              body: {
                'delivery_team': deliveryTeamRecord.id,
                'trip': actualTripId, // Add trip reference to vehicle
              },
            );
        debugPrint('✅ Assigned delivery team and trip to vehicle: $vehicleId');
      }

      final inTransitStatus = await _pocketBaseClient
          .collection('delivery_status_choices')
          .getFirstListItem('title = "In Transit"');

      final customers = tripRecord.expand['customers'] as List? ?? [];
      for (var customer in customers) {
        final deliveryUpdateRecord = await _pocketBaseClient
            .collection('delivery_update')
            .create(
              body: {
                'customer': customer.id,
                'status': inTransitStatus.id,
                'title': inTransitStatus.data['title'],
                'subtitle': inTransitStatus.data['subtitle'],
                'created': DateTime.now().toIso8601String(),
                'time': DateTime.now().toIso8601String(),
                'isAssigned': true,
              },
            );

        await _pocketBaseClient
            .collection('customers')
            .update(
              customer.id,
              body: {
                'deliveryStatus+': [deliveryUpdateRecord.id],
              },
            );

        final customerInvoices = await _pocketBaseClient
            .collection('invoices')
            .getList(filter: 'customer = "${customer.id}"');

        for (var invoice in customerInvoices.items) {
          await _pocketBaseClient
              .collection('invoices')
              .update(invoice.id, body: {'status': 'truck'});
        }
      }

      final trackingRecord = await _pocketBaseClient
          .collection('tracking')
          .create(
            body: {
              'trip': tripRecord.id,
              'startTime': DateTime.now().toIso8601String(),
              'distanceTraveled': 0,
            },
          );

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
          .collection('end_trip_otp')
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
              'delivery_team': deliveryTeamRecord.id,
              'tracking': trackingRecord.id,
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
              'deliveryTeam': deliveryTeamRecord.id,
            },
          );

      await _pocketBaseClient
          .collection('tripticket')
          .update(tripRecord.id, body: {'user': userId});

      final mappedData = {
        'id': tripRecord.id,
        'collectionId': tripRecord.collectionId,
        'collectionName': tripRecord.collectionName,
        ...tripRecord.data,
        'isAccepted': true,
        'delivery_team': deliveryTeamRecord.toJson(),
        'tracking': trackingRecord.toJson(),
        'otp': otpRecord.toJson(),
        'endTripOtp': endTripOtpRecord.toJson(),
        'timeline': _mapTimeline(tripRecord),
        'personels': _mapPersonels(tripRecord),
        'checklist': _mapChecklist(tripRecord),
        'vehicle': _mapVehicle(tripRecord),
        'timeAccepted': DateTime.now().toIso8601String(),
      };

      await prefs.setString('user_trip_data', jsonEncode(mappedData));
      debugPrint('💾 Cached new trip assignment data');

      final acceptedTripModel = TripModel.fromJson(mappedData);
      await _tripLocalDatasource.autoSaveTrip(acceptedTripModel);

      debugPrint('✅ Trip acceptance completed');
      return (acceptedTripModel, trackingRecord.id);
    } catch (e) {
      debugPrint('❌ Error in acceptTrip: $e');
      throw ServerException(
        message: 'Failed to accept trip: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  dynamic _mapTimeline(RecordModel tripRecord) {
    debugPrint('🔄 Mapping timeline');
    if (tripRecord.expand['timeline'] is List) {
      final timeline =
          (tripRecord.expand['timeline'] as List).first as RecordModel;
      return {
        ...timeline.data,
        'id': timeline.id,
        'created': null,
        'updated': null,
      };
    }
    return null;
  }

  List<Map<String, dynamic>> _mapPersonels(RecordModel tripRecord) {
    debugPrint('👥 Mapping personnel');
    return (tripRecord.expand['personels'] as List?)?.map((p) {
          final personnel = p as RecordModel;
          return {
            ...personnel.data,
            'id': personnel.id,
            'created': null,
            'updated': null,
          };
        }).toList() ??
        [];
  }

  List<Map<String, dynamic>> _mapChecklist(RecordModel tripRecord) {
    debugPrint('📋 Mapping checklist');
    return (tripRecord.expand['checklist'] as List?)?.map((c) {
          final checklist = c as RecordModel;
          return {
            ...checklist.data,
            'id': checklist.id,
            'created': null,
            'updated': null,
          };
        }).toList() ??
        [];
  }

  dynamic _mapVehicle(RecordModel tripRecord) {
    debugPrint('🚗 Mapping vehicle');
    if (tripRecord.expand['vehicle'] is List) {
      final vehicle =
          (tripRecord.expand['vehicle'] as List).first as RecordModel;
      return {
        ...vehicle.data,
        'id': vehicle.id,
        'created': null,
        'updated': null,
      };
    }
    return null;
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
        filters.add('delivery_team = "$deliveryTeamId"');
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
          .collection('end_trip_otp')
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
                'customers,customers.deliveryStatus,customers.invoices(customer),customers.invoices.productList,personels,vehicle,checklist,invoices,invoices.productList,delivery_team',
          );

      final mappedData = {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        ...record.data,
        'customers':
            (record.expand['customers'] as List?)?.map((c) {
              final customerData = c as RecordModel;
              final deliveryStatus =
                  customerData.expand['deliveryStatus'] as List? ?? [];
              final invoices = customerData.expand['invoices'] as List? ?? [];

              return {
                ...customerData.data,
                'id': customerData.id,
                'deliveryStatus':
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
            expand: 'customers,timeline,personels,vehicle,checklist',
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
            .update(vehicleId, body: {'delivery_team': null, 'trip': null});
        debugPrint('✅ Vehicle assignment cleared');
      }

      // Clear personnel assignments
      for (var personnel in tripRecord.expand['personels'] as List? ?? []) {
        await _pocketBaseClient
            .collection('personels')
            .update(
              (personnel as RecordModel).id,
              body: {'delivery_team': null, 'trip': null},
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

      debugPrint('✅ Trip location updated successfully');

      // Create a TripModel from the updated record
      final mappedData = {
        'id': updatedRecord.id,
        'collectionId': updatedRecord.collectionId,
        'collectionName': updatedRecord.collectionName,
        ...updatedRecord.data,
        'timeline': _mapTimeline(tripRecord),
        'personels': _mapPersonels(tripRecord),
        'checklist': _mapChecklist(tripRecord),
        'vehicle': _mapVehicle(tripRecord),
        'latitude': latitude,
        'longitude': longitude,
      };

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
}
