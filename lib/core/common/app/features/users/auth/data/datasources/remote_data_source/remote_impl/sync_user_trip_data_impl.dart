import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/auth_remote_base.dart';

/// Mixin that provides the [syncUserTripData] implementation for [AuthRemoteDataSrc].
mixin SyncUserTripDataImpl on AuthRemoteBase {
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
                'customers,deliveryTeam,deliveryTeam.personels,deliveryTeam.deliveryVehicle,deliveryTeam.checklist,personels,deliveryVehicle,checklist,deliveryData.customer,deliveryData.invoices,deliveryData.deliveryUpdates,deliveryData.trip,cancelledInvoice,deliveryData.invoiceItems,otp,endTripOtp',
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
        d.data['invoices'] =
            invoices.map((r) {
              final mapped = mapExpandedRecord(r);
              // Normalize refID -> refId for InvoiceDataModel compatibility
              if (mapped is Map<String, dynamic> &&
                  mapped.containsKey('refID')) {
                mapped['refId'] = mapped['refID'];
              }
              return mapped;
            }).toList();

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
        d.data['invoices'] =
            invoices.map((r) {
              final mapped = mapExpandedRecord(r);
              // Normalize refID -> refId for InvoiceDataModel compatibility
              if (mapped is Map<String, dynamic> &&
                  mapped.containsKey('refID')) {
                mapped['refId'] = mapped['refID'];
              }
              return mapped;
            }).toList();
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
        'tripTotalTime': tripRecord.data['tripTotalTime'] ?? 0,
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
