import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/remote_datasource/trip_remote_imp/trip_remote_base.dart';

mixin AcceptTripImpl on TripRemoteBase {
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

      Future<List<TOut>> poolMap<TIn, TOut>(
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
        throw const ServerException(
          message: 'Missing user_data',
          statusCode: '400',
        );
      }

      final userData = jsonDecode(storedUserData) as Map<String, dynamic>;
      final userId = (userData['id'] ?? '').toString().trim();

      if (userId.isEmpty) {
        throw const ServerException(
          message: 'Invalid user ID',
          statusCode: '400',
        );
      }
      debugPrint('👤 Using user ID: $userId');

      // ---------------------------------------------------------
      // 2) Fetch user + trip in parallel (faster)
      // ---------------------------------------------------------
      final fetched = await Future.wait([
        retry(
          () => pocketBaseClient.collection('users').getOne(userId),
          label: 'GET users/$userId',
        ),
        retry(
          () => pocketBaseClient
              .collection('tripticket')
              .getOne(
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
          final response = await retry(
            () => pocketBaseClient.collection('checklist').create(body: item),
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
      final deliveryVehicleId =
          tripRecord.expand['deliveryVehicle'] is List
              ? (tripRecord.expand['deliveryVehicle'] as List).first.id
              : (tripRecord.expand['deliveryVehicle'] as RecordModel?)?.id;

      final personels =
          (tripRecord.expand['personels'] as List? ?? []).cast<RecordModel>();
      final customers =
          (tripRecord.expand['deliveryData'] as List? ?? [])
              .cast<RecordModel>();

      final deliveryTeamRecord = await retry(
        () => pocketBaseClient
            .collection('deliveryTeam')
            .create(
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

        await poolMap<RecordModel, void>(
          personels,
          6, // safe concurrency to avoid PB resets
          (personnel) async {
            await retry(
              () => pocketBaseClient
                  .collection('personels')
                  .update(
                    personnel.id,
                    body: {
                      'deliveryTeam': deliveryTeamRecord.id,
                      'trip': actualTripId,
                    },
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
      final inTransitStatus = await retry(
        () => pocketBaseClient
            .collection('deliveryStatusChoices')
            .getFirstListItem('title = "In Transit"'),
        label: 'GET deliveryStatusChoices In Transit',
      );

      // ---------------------------------------------------------
      // 7) For each customer: create deliveryUpdate + update deliveryData (parallel)
      // ---------------------------------------------------------
      if (customers.isNotEmpty) {
        debugPrint(
          '📦 Creating delivery updates for customers: ${customers.length}',
        );

        await poolMap<RecordModel, void>(
          customers,
          6, // safe concurrency
          (customer) async {
            final deliveryUpdateRecord = await retry(
              () => pocketBaseClient
                  .collection('deliveryUpdate')
                  .create(
                    body: {
                      'deliveryData': customer.id,
                      'status': inTransitStatus.id,
                      'title': inTransitStatus.data['title'],
                      'subtitle': inTransitStatus.data['subtitle'],
                      'created': DateTime.now().toIso8601String(),
                      'time': DateTime.now().toLocal().toIso8601String(),
                      'isAssigned': true,
                    },
                  ),
              label: 'CREATE deliveryUpdate',
            );

            await retry(
              () => pocketBaseClient
                  .collection('deliveryData')
                  .update(
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
        retry(
          () => pocketBaseClient
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
              ),
          label: 'CREATE otp',
        ),
        retry(
          () => pocketBaseClient
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
              ),
          label: 'CREATE endTripOtp',
        ),
      ]);

      final otpRecord = otpResults[0];
      final endTripOtpRecord = otpResults[1];

      // ---------------------------------------------------------
      // 9) Create tripUpdates + attach (keep your flow)
      // ---------------------------------------------------------
      final tripUpdateRecord = await retry(
        () => pocketBaseClient
            .collection('tripUpdates')
            .create(
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

      await retry(
        () => pocketBaseClient
            .collection('tripticket')
            .update(
              tripRecord.id,
              body: {
                'trip_update_list+': [tripUpdateRecord.id],
              },
            ),
        label: 'UPDATE tripticket attach trip_update_list',
      );

      // ---------------------------------------------------------
      // 10) Update tripticket + update user in parallel
      // ---------------------------------------------------------
      await Future.wait([
        retry(
          () => pocketBaseClient
              .collection('tripticket')
              .update(
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
        retry(
          () => pocketBaseClient
              .collection('users')
              .update(
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
      final syncedUser = await retry(
        () => syncUserData(userId),
        label: 'syncUserData users/$userId (expand)',
        maxAttempts: 4,
      );

      final existingPrefsUser =
          jsonDecode(storedUserData) as Map<String, dynamic>;
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
      await retry(
        () => pocketBaseClient
            .collection('usersTripHistory')
            .create(
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
            'deliveryTeam': convertRecordToJson(deliveryTeamRecord),
            'deliveryData': mapDeliveryData(tripRecord),
            'otp': convertRecordToJson(otpRecord),
            'deliveryVehicle': tripRecord.data['deliveryVehicle'],
            'endTripOtp': convertRecordToJson(endTripOtpRecord),
            'trip_update_list': mapTripUpdates(tripRecord),
            'personels': mapPersonels(tripRecord),
            'checklist': mapChecklist(tripRecord),
            'timeAccepted': DateTime.now().toIso8601String(),
          };

          if (tripRecord.data['created'] != null) {
            data['created'] =
                parseDate(tripRecord.data['created'])?.toIso8601String();
          }
          if (tripRecord.data['updated'] != null) {
            data['updated'] =
                parseDate(tripRecord.data['updated'])?.toIso8601String();
          }
          if (tripRecord.data['timeEndTrip'] != null) {
            data['timeEndTrip'] =
                parseDate(tripRecord.data['timeEndTrip'])?.toIso8601String();
          }
          if (tripRecord.data['deliveryDate'] != null) {
            data['deliveryDate'] =
                parseDate(tripRecord.data['deliveryDate'])?.toIso8601String();
          }

          return data;
        } catch (e) {
          debugPrint('⚠️ Error extracting data: $e');
          return {
            'id': tripRecord.id,
            'collectionId': tripRecord.collectionId,
            'collectionName': tripRecord.collectionName,
            'isAccepted': true,
            'deliveryTeam': convertRecordToJson(deliveryTeamRecord),
            'otp': convertRecordToJson(otpRecord),
            'endTripOtp': convertRecordToJson(endTripOtpRecord),
            'timeAccepted': DateTime.now().toIso8601String(),
          };
        }
      }

      final mappedData = extractData();
      await prefs.setString('user_trip_data', jsonEncode(mappedData));

      final acceptedTripModel = TripModel.fromJson(mappedData);

      // ✅ final sync (keep but do once)
      await retry(
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
}
