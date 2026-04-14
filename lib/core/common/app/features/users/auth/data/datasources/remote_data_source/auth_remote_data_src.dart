import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/utils/device_info_utils.dart';

abstract class AuthRemoteDataSrc {
  const AuthRemoteDataSrc();

  Future<LocalUsersModel> signIn({
    required String email,
    required String password,
  });
  Future<LocalUsersModel> refreshUserData();
  Future<LocalUsersModel> loadUser();
  Future<LocalUsersModel> getUserById(String userId);
  Future<TripModel> getUserTrip(String userId);

  // New sync methods
  Future<LocalUsersModel> syncUserData(String userId);
  Future<TripModel> syncUserTripData(String userId);
}

class AuthRemoteDataSrcImpl implements AuthRemoteDataSrc {
  const AuthRemoteDataSrcImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<LocalUsersModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting sign in for: $email');

      final authData = await _pocketBaseClient
          .collection('users')
          .authWithPassword(email, password);

      if (authData.token.isEmpty) {
        throw const ServerException(
          message: 'Authentication failed',
          statusCode: 'Auth Error',
        );
      }

      // Get the user record with expanded role data
      final userRecord = await _pocketBaseClient
          .collection('users')
          .getOne(
            authData.record.id,
            expand:
                'userRole', // Make sure this matches the field name in PocketBase
          );

      // Check if user has Team Leader role
      final userRoleData = userRecord.expand['userRole'];
      bool isTeamLeader = false;
      Map<String, dynamic>? roleJson;

      if (userRoleData != null) {
        debugPrint('🔍 User role data type: ${userRoleData.runtimeType}');

        // Handle the case where userRoleData is a List<RecordModel>
        if (userRoleData.isNotEmpty) {
          final roleRecord = userRoleData.first;
          final roleName = roleRecord.data['name']?.toString() ?? '';
          isTeamLeader = roleName == 'Team Leader' || roleName == 'Driver';
          debugPrint('👑 User role (from list): $roleName');

          roleJson = {
            'id': roleRecord.id,
            'name': roleName,
            'permissions': roleRecord.data['permissions'] ?? [],
          };
        }
      } else {
        debugPrint('⚠️ No role data found for user');
      }

      // Check user status
      final userStatus =
          userRecord.data['status']?.toString().toLowerCase() ?? '';
      if (userStatus == 'suspended') {
        throw const ServerException(
          message:
              'Your account has been suspended. Please contact the administrator.',
          statusCode: 'Account Suspended',
        );
      }

      if (!isTeamLeader) {
        throw const ServerException(
          message:
              'You don\'t have permission to sign in to this app. Please contact your admin support and try again.',
          statusCode: 'Permission Error',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> userData;

      try {
        // Prepare user data with role information
        userData = {
          'id': authData.record.id,
          'collectionId': authData.record.collectionId,
          'collectionName': authData.record.collectionName,
          'email': authData.record.data['email'],
          'name': authData.record.data['name'],
          'tripNumberId': authData.record.data['tripNumberId'],
          'tokenKey': authData.token,
        };

        // Add role data if available
        if (roleJson != null) {
          userData['expand'] = {'userRole': roleJson};
        }

        // Store properly formatted auth data
        await prefs.setString('auth_token', authData.token);
        await prefs.setString('user_data', jsonEncode(userData));

        debugPrint('✅ Authentication successful');
        debugPrint('💾 Stored user data: ${userData['name']}');
        debugPrint('   🆔 User ID: ${userData['id']}');
        debugPrint('   👑 Role: ${roleJson?['name'] ?? 'Unknown'}');
        debugPrint('   🔑 Token: ${authData.token.substring(0, 10)}...');

        // 🕓 Record login event in "authLogs" with device info
        await _recordAuthLog(
          userId: authData.record.id,
          loginTime: DateTime.now().toUtc().toIso8601String(),
        );

        return LocalUsersModel.fromJson(userData);
      } catch (e) {
        debugPrint('⚠️ Error formatting user data: ${e.toString()}');

        // Fallback data formatting
        final cleanedData = jsonEncode(authData.record.data)
            .replaceAll(RegExp(r':\s+'), '": "')
            .replaceAll(RegExp(r',\s+'), '", "')
            .replaceAll('{', '{"')
            .replaceAll('}', '"}');

        userData = jsonDecode(cleanedData);
        userData['tokenKey'] = authData.token;

        // Add role data if available
        if (roleJson != null) {
          userData['expand'] = {'userRole': roleJson};
        }

        return LocalUsersModel.fromJson(userData);
      }
    } catch (e) {
      debugPrint('❌ Authentication error: ${e.toString()}');
      throw ServerException(
        message: e is ServerException ? e.message : e.toString(),
        statusCode: e is ServerException ? e.statusCode : '500',
      );
    }
  }

  @override
  Future<LocalUsersModel> refreshUserData() async {
    try {
      debugPrint('🔄 Refreshing user data');
      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      if (storedUserData != null) {
        // Parse stored data
        final userData = jsonDecode(storedUserData);
        final userId = userData['id'];

        debugPrint('🔍 Refreshing data for user: $userId');

        final userRecord = await _pocketBaseClient
            .collection('users')
            .getOne(
              userId,
              expand:
                  'trip,deliveryTeam,trip.customers,trip.personels,trip.vehicle',
            );

        final mappedData = {
          'id': userRecord.id,
          'collectionId': userRecord.collectionId,
          'collectionName': userRecord.collectionName,
          'email': userRecord.data['email'],
          'name': userRecord.data['name'],
          'tripNumberId': userRecord.data['tripNumberId'],
          'deliveryTeam': _mapExpandedRecord(userRecord.expand['deliveryTeam']),
          'trip': _mapExpandedRecord(userRecord.expand['trip']),
          'tokenKey': userData['tokenKey'],
        };

        await prefs.setString('user_data', jsonEncode(mappedData));
        debugPrint('✅ User data refreshed successfully');
        return LocalUsersModel.fromJson(mappedData);
      }

      throw const ServerException(
        message: 'No stored user data found',
        statusCode: '404',
      );
    } catch (e) {
      debugPrint('❌ Refresh failed: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }

  @override
  Future<LocalUsersModel> loadUser() async {
    try {
      debugPrint('🔄 Loading user data from remote');

      // First try to restore auth from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      final storedUserData = prefs.getString('user_data');

      if (storedToken != null && storedUserData != null) {
        final userData = jsonDecode(storedUserData);
        debugPrint('📦 Stored user data: $userData');

        // Create user model directly from stored data
        return LocalUsersModel(
          id: userData['id'],
          email: userData['email'] ?? '',
          name: userData['name'] ?? '',
          tripNumberId: userData['tripNumberId'] ?? '',
          collectionId: '_pb_users_auth_',
          collectionName: 'users',
        );
      }

      throw const ServerException(
        message: 'No stored user data found',
        statusCode: '404',
      );
    } catch (e) {
      debugPrint('❌ Remote load failed: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }

  @override
  Future<LocalUsersModel> getUserById(String userId) async {
    try {
      // Extract actual user ID if we received a JSON object
      String actualUserId;
      if (userId.startsWith('{')) {
        final userData = jsonDecode(userId);
        actualUserId = userData['id'];
      } else {
        actualUserId = userId;
      }

      debugPrint('🔍 Fetching user by ID: $actualUserId');
      debugPrint('📊 Remote Fetch Stats:');

      final user = await _pocketBaseClient
          .collection('users')
          .getOne(actualUserId, expand: 'trip,useRole');

      debugPrint('   👤 User Found: ${user.id}');
      debugPrint('   📧 Email: ${user.data['email']}');
      debugPrint('   🚚 Trip Number: ${user.data['tripNumberId']}');

      debugPrint('📦 Expanded Relations:');

      debugPrint(
        '   ✓ Trip: ${user.expand['trip'] != null ? 'Found' : 'Not Found'}',
      );

      final Map<String, dynamic> userData = {
        ...user.data,
        'id': user.id,
        'name': user.data['name'] ?? '',
        'tripNumberId': user.data['tripNumberId'] ?? '',
        'checklist':
            user.expand['checklist']?.map((item) => item.id).toList() ?? [],
        'updateTimeline':
            user.expand['updateTimeline']?.map((item) => item.id).toList() ??
            [],
        'deliveryTeam':
            user.expand['deliveryTeam']?.map((item) => item.id).toList() ?? [],
        'completedCustomer':
            user.expand['completedCustomer']?.map((item) => item.id).toList() ??
            [],
        'returnList':
            user.expand['returnList']?.map((item) => item.id).toList() ?? [],
        'endTripChecklists':
            user.expand['endTripChecklists']?.map((item) => item.id).toList() ??
            [],
        'trip': user.expand['trip'],
      };

      debugPrint('✅ User found and mapped successfully');
      debugPrint('   👤 Name: ${userData['name']}');
      debugPrint('   🎫 Trip Number: ${userData['tripNumberId']}');
      return LocalUsersModel.fromJson(userData);
    } catch (e) {
      debugPrint('❌ User fetch failed: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }

  @override
  Future<TripModel> getUserTrip(String userId) async {
    try {
      debugPrint('🔍 Loading trip for user: $userId');

      final prefs = await SharedPreferences.getInstance();
      final storedUserData = prefs.getString('user_data');

      if (storedUserData == null) {
        throw const ServerException(
          message: 'No stored user data found',
          statusCode: '404',
        );
      }

      final userData = jsonDecode(storedUserData);

      // ✅ FIX: Use user's trip relation ID, not tripNumberId
      final userTripPBId = userData['trip'];
      debugPrint('🆔 User relation-based trip PB ID: $userTripPBId');

      if (userTripPBId == null || userTripPBId.toString().isEmpty) {
        throw const ServerException(
          message: 'User has no assigned trip (relation field empty)',
          statusCode: '404',
        );
      }

      // 🔥 DIRECT fetch — do NOT filter by tripNumberId
      final tripRecord = await _pocketBaseClient
          .collection('tripticket')
          .getOne(
            userTripPBId,
            expand: 'deliveryData,deliveryTeam,personels,vehicle,checklist',
          );

      debugPrint('🟦 Trip fetched successfully → PB ID: ${tripRecord.id}');

      final mappedData = {
        'id': tripRecord.id,
        'collectionId': tripRecord.collectionId,
        'collectionName': tripRecord.collectionName,
        ...Map<String, dynamic>.from(tripRecord.data),
        'deliveryData': _mapExpandedRecord(tripRecord.expand['deliveryData']),
        'deliveryTeam': _mapExpandedRecord(tripRecord.expand['deliveryTeam']),
        'personels': _mapExpandedRecord(tripRecord.expand['personels']),
        'deliveryVehicle': _mapExpandedRecord(tripRecord.expand['deliveryVehicle']),
        'checklist': _mapExpandedRecord(tripRecord.expand['checklist']),
      };

      await prefs.setString('user_trip_data', jsonEncode(mappedData));
      debugPrint('💾 Trip data cached successfully');

      return TripModel.fromJson(mappedData);
    } catch (e) {
      debugPrint('❌ Failed to fetch user trip: $e');
      throw ServerException(message: e.toString(), statusCode: '500');
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

  @override
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


  @override
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
  d.data['invoices'] = invoices.map((r) {
    final mapped = _mapExpandedRecord(r);
    // Normalize refID -> refId for InvoiceDataModel compatibility
    if (mapped is Map<String, dynamic> && mapped.containsKey('refID')) {
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
        d.data['invoices'] = invoices.map((r) {
          final mapped = _mapExpandedRecord(r);
          // Normalize refID -> refId for InvoiceDataModel compatibility
          if (mapped is Map<String, dynamic> && mapped.containsKey('refID')) {
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

  // TripModel _mapRecordToTripModel(RecordModel record) {
  //   try {
  //     debugPrint('🔄 Mapping record to TripModel: ${record.id}');

  //     // Debug raw data
  //     debugPrint('📋 Raw record.id: ${record.id}');
  //     debugPrint('📋 Raw keys: ${record.data.keys.toList()}');

  //     // -----------------------------
  //     // Safe string converter
  //     // -----------------------------
  //     String? safeString(dynamic value) {
  //       if (value == null) return null;
  //       if (value is String) return value.isEmpty ? null : value;
  //       if (value is List && value.isNotEmpty) return value.first.toString();
  //       return value.toString();
  //     }

  //     // -----------------------------
  //     // Safe Date Parser (no more errors!)
  //     // -----------------------------
  //     DateTime? _safeDateParse(dynamic value) {
  //       if (value == null) return null;

  //       if (value is DateTime) return value;

  //       if (value is String) {
  //         if (value.trim().isEmpty) return null;

  //         try {
  //           return DateTime.parse(value);
  //         } catch (_) {
  //           debugPrint("❌ Invalid date string: $value");
  //           return null;
  //         }
  //       }

  //       debugPrint("❌ Unknown date type: ${value.runtimeType}");
  //       return null;
  //     }

  //     // -----------------------------
  //     // DATE FIELDS (safe)
  //     // -----------------------------
  //     final timeAccepted = _safeDateParse(record.data['timeAccepted']);
  //     //final timeEndTrip = _safeDateParse(record.data['timeEndTrip']);
  //     final deliveryDate = _safeDateParse(record.data['deliveryDate']);
  //     final expectedReturnDate = _safeDateParse(
  //       record.data['expectedReturnDate'],
  //     );

  //     final created = _safeDateParse(record.data['created']);
  //     final updated = _safeDateParse(record.data['updated']);

  //     // -----------------------------
  //     // RELATIONS
  //     // -----------------------------
  //     final vehicleJson = _mapExpandedItem(record.expand['deliveryVehicle']);
  //     DeliveryVehicleModel? vehicle =
  //         vehicleJson != null
  //             ? DeliveryVehicleModel.fromJson(vehicleJson)
  //             : null;

  //     final otpJson = _mapExpandedItem(record.expand['otp']);
  //     final otp = otpJson != null ? OtpModel.fromJson(otpJson) : null;

  //     final endOtpJson = _mapExpandedItem(record.expand['endTripOtp']);
  //     final endOtp =
  //         endOtpJson != null ? EndTripOtpModel.fromJson(endOtpJson) : null;

  //     // -----------------------------
  //     // FINAL MERGED MAP
  //     // -----------------------------
  //     final mappedData = <String, dynamic>{
  //       ...record.data,

  //       // Strong overrides
  //       'id': record.id,
  //       'collectionId': record.collectionId,
  //       'collectionName': record.collectionName,

  //       // Fix string type issues
  //       'tripNumberId': safeString(record.data['tripNumberId']),
  //       'qrCode': safeString(record.data['qrCode']),
  //       'name': safeString(record.data['name']),

  //       // Relations
  //       'deliveryVehicle': vehicle,
  //       'otp': otp,
  //       'endTripOtp': endOtp,
  //       'customers': _mapExpandedList(record.expand['customers']),
  //       'personels': _mapExpandedList(record.expand['personels']),
  //       'deliveryTeam': _mapExpandedItem(record.expand['deliveryTeam']),
  //       'deliveryData': _mapExpandedList(record.expand['deliveryData']),
  //       'checklist': _mapExpandedList(record.expand['checklist']),
  //       'endTripChecklists': _mapExpandedList(
  //         record.expand['endTripChecklists'],
  //       ),
  //       'trip_update_list': _mapExpandedList(record.expand['trip_update_list']),

  //       // Dates (safe)
  //       'created': created,
  //       'updated': updated,
  //       'timeAccepted': timeAccepted,
  //       // 'timeEndTrip': timeEndTrip,
  //       'deliveryDate': deliveryDate,
  //       'expectedReturnDate': expectedReturnDate,
  //     };

  //     debugPrint('📦 Final mappedData id: ${mappedData['id']}');
  //     debugPrint(
  //       '📦 Final mappedData tripNumberId: ${mappedData['tripNumberId']}',
  //     );

  //     return TripModel.fromJson(mappedData);
  //   } catch (e) {
  //     debugPrint('❌ Error mapping record to TripModel: $e');
  //     throw ServerException(
  //       message: 'Failed to map record to TripModel: $e',
  //       statusCode: '500',
  //     );
  //   }
  // }

  // Safe date parser helper
  // DateTime? _safeParseDate(dynamic value, {String? fieldName}) {
  //   if (value == null) return null;

  //   try {
  //     if (value is DateTime) return value;
  //     if (value is String && value.trim().isNotEmpty) {
  //       return DateTime.parse(value);
  //     }
  //   } catch (e) {
  //     debugPrint(
  //       '❌ [SAFE DATE PARSE ERROR] Failed to parse date for field '
  //       '${fieldName ?? "unknown"} → value: "$value" | Error: $e',
  //     );
  //   }
  //   return null;
  // }

  // // Helper method to map expanded list items
  // List<Map<String, dynamic>> _mapExpandedList(dynamic records) {
  //   if (records == null) return [];

  //   if (records is List) {
  //     return records.map((record) {
  //       if (record is RecordModel) {
  //         return <String, dynamic>{
  //           'id': record.id,
  //           'collectionId': record.collectionId,
  //           'collectionName': record.collectionName,
  //           ...Map<String, dynamic>.from(record.data),
  //           'created': _safeParseDate(record.created, fieldName: 'created'),
  //           'updated': _safeParseDate(record.updated, fieldName: 'updated'),
  //         };
  //       }
  //       return <String, dynamic>{};
  //     }).toList();
  //   }

  //   return [];
  // }

  // // Helper method to map a single expanded item
  // Map<String, dynamic>? _mapExpandedItem(dynamic record) {
  //   if (record == null) return null;

  //   if (record is List && record.isNotEmpty) {
  //     final item = record.first;
  //     if (item is RecordModel) {
  //       return <String, dynamic>{
  //         'id': item.id,
  //         'collectionId': item.collectionId,
  //         'collectionName': item.collectionName,
  //         ...Map<String, dynamic>.from(item.data),
  //         'created': _safeParseDate(item.created, fieldName: 'created'),
  //         'updated': _safeParseDate(item.updated, fieldName: 'updated'),
  //       };
  //     }
  //   } else if (record is RecordModel) {
  //     return <String, dynamic>{
  //       'id': record.id,
  //       'collectionId': record.collectionId,
  //       'collectionName': record.collectionName,
  //       ...Map<String, dynamic>.from(record.data),
  //       'created': _safeParseDate(record.created, fieldName: 'created'),
  //       'updated': _safeParseDate(record.updated, fieldName: 'updated'),
  //     };
  //   }

  //   return null;
  // }

  /// Records authentication log with device information to authLogs collection
  Future<void> _recordAuthLog({
    required String userId,
    required String loginTime,
  }) async {
    try {
      debugPrint('🔐 Recording auth log for user: $userId');

      // Get device information (IP and IMEI/Device ID)
      final deviceInfo = await DeviceInfoUtils.getDeviceAuthInfo();

      debugPrint('📱 Device Info: $deviceInfo');

      // Prepare auth log data
      final authLogData = {
        'user': userId,
        'loginTime': loginTime,
        'deviceId': deviceInfo['deviceId'] ?? 'unknown',
        'ipAddress': deviceInfo['localIp'] ?? 'unknown',
        'platform': deviceInfo['platform'] ?? 'unknown',
        'platformVersion': deviceInfo['platformVersion'] ?? 'unknown',
        'deviceModel': deviceInfo['deviceModel'] ?? deviceInfo['deviceSystemVersion'] ?? 'unknown',
        'deviceBrand': deviceInfo['deviceBrand'] ?? 'unknown',
      };

      debugPrint('📝 Auth Log Data: $authLogData');

      // Record to authLogs collection
      await _pocketBaseClient.collection('authLogs').create(body: authLogData);

      debugPrint('✅ Auth log recorded successfully for user: $userId');
      debugPrint('   🕓 Login Time: $loginTime');
      debugPrint('   📱 Device ID: ${authLogData['deviceId']}');
      debugPrint('   🌐 IP Address: ${authLogData['ipAddress']}');
      debugPrint('   📲 Platform: ${authLogData['platform']} ${authLogData['platformVersion']}');
    } catch (e) {
      // Non-critical error - don't fail the login, just log the issue
      debugPrint('⚠️ Failed to record auth log (non-critical): $e');
      // Optionally record a minimal log entry
      try {
        await _pocketBaseClient.collection('authLogs').create(
          body: {
            'user': userId,
            'loginTime': loginTime,
            'deviceId': 'unknown',
            'ipAddress': 'unknown',
            'error': 'Failed to capture device info: $e',
          },
        );
      } catch (fallbackError) {
        debugPrint('⚠️ Even fallback auth log failed: $fallbackError');
      }
    }
  }
}
