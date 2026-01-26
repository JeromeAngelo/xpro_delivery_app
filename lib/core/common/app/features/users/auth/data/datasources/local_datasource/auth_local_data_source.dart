import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/data/model/customer_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';

import '../../../../../../../../enums/sync_status_enums.dart';
import '../../../../../../../../services/objectbox.dart';
import '../../../../../checklists/intransit_checklist/data/model/checklist_model.dart';
import '../../../../../delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import '../../../../../delivery_data/invoice_items/data/model/invoice_items_model.dart';
import '../../../../../otp/end_trip_otp/data/model/end_trip_model.dart';
import '../../../../../trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import '../../../../../trip_ticket/delivery_collection/data/model/collection_model.dart';
import '../../../../../trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import '../../../../../checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import '../../../../../delivery_data/delivery_update/data/models/delivery_update_model.dart';
import '../../../../../delivery_team/delivery_vehicle_data/data/model/delivery_vehicle_model.dart';
import '../../../../../delivery_team/personels/data/models/personel_models.dart';
import '../../../../../otp/intransit_otp/data/models/otp_models.dart';
import '../../../../../trip_ticket/trip_updates/data/model/trip_update_model.dart';

abstract class AuthLocalDataSrc {
  Future<LocalUsersModel> getLocalUser();
  Future<LocalUsersModel> loadLocalUserById(String userId);
  Future<void> saveUser(LocalUsersModel user);
  Future<void> clearUser();
  Future<bool> hasUser();
  Future<TripModel> loadLocalUserTrip(String userId);
  // New sync methods
  Future<void> cacheUserData(LocalUsersModel user);
  Future<void> cacheUserTripData(TripModel trip);
  Future<void> saveUserTripByUserId(String userId, TripModel trip);
  Future<TripModel> forceReloadLocalUserTrip(String userId);
  Future<LocalUsersModel> forceReloadLocalUserById(String userId);
}

class AuthLocalDataSrcImpl implements AuthLocalDataSrc {
  final ObjectBoxStore objectBoxStore;
  final Box<LocalUsersModel> _box;
  final SharedPreferences _prefs;
  Box<ChecklistModel> get checklistBox => objectBoxStore.checklistBox;

  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<DeliveryTeamModel> get deliveryTeamBox => objectBoxStore.deliveryTeamBox;

  Box<DeliveryVehicleModel> get vehicleBox => objectBoxStore.deliveryVehicleBox;
  Box<PersonelModel> get personnelBox => objectBoxStore.personelBox;
  Box<OtpModel> get otpBox => objectBoxStore.store.box<OtpModel>();
  Box<EndTripOtpModel> get endTripOtpBox => objectBoxStore.endTripOtpBox;

  Box<CustomerDataModel> get customerBox => objectBoxStore.customerBox;
  Box<InvoiceDataModel> get invoiceBox => objectBoxStore.invoiceBox;

    Box<InvoiceItemsModel> get invoiceItemsBox => objectBoxStore.invoiceItemsBox;
  
  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;
  Box<EndTripChecklistModel> get endTripChecklistBox =>
      objectBoxStore.endTripChecklistBox;
  Box<TripUpdateModel> get tripUpdateBox => objectBoxStore.tripUpdatesBox;
  Box<CancelledInvoiceModel> get cancelledInvoiceBox =>
      objectBoxStore.cancelledInvoiceBox;
  Box<CollectionModel> get deliveryCollectonBox =>
      objectBoxStore.deliveryCollectonBox;

  Box<DeliveryReceiptModel> get deliveryReceiptBox =>
      objectBoxStore.deliveryReceiptBox;

  AuthLocalDataSrcImpl({
    required this.objectBoxStore,
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       _box = objectBoxStore.userBox;
  @override
  Future<LocalUsersModel> getLocalUser() async {
    try {
      debugPrint('🔍 Fetching user from local storage');
      final storedData = _prefs.getString('user_data');

      if (storedData != null) {
        debugPrint('📦 Raw stored user data: $storedData');
        final userData = jsonDecode(storedData);

        // Create model with proper token mapping
        final user = LocalUsersModel(
          id: userData['id'],
          collectionId: userData['collectionId'],
          collectionName: userData['collectionName'],
          email: userData['email'],
          name: userData['name'],
          tripNumberId: userData['tripNumberId'],
          token: userData['tokenKey'], // Map tokenKey to token
        );

        debugPrint('✅ Successfully loaded user from local storage');
        debugPrint('   👤 User: ${user.name}');
        debugPrint('   🎫 Trip ID: ${user.tripId}');
        debugPrint('   🔑 Token: ${user.token?.substring(0, 10)}...');

        return user;
      }
      throw const CacheException(message: 'No stored user data found');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<LocalUsersModel> loadLocalUserById(String userId) async {
    try {
      debugPrint('🔍 Fetching user by ID from local storage: $userId');

      // Step 1️⃣: Try SharedPreferences first
      final storedData = _prefs.getString('user_data');

      if (storedData != null) {
        final userData = jsonDecode(storedData);
        if (userData['id'] == userId) {
          debugPrint('📦 Found user in SharedPreferences');
          debugPrint('   👤 Name: ${userData['name']}');
          debugPrint('   📧 Email: ${userData['email']}');
          debugPrint('   🎫 Trip Number ID: ${userData['tripNumberId']}');
          debugPrint(
            '   🔑 Token: ${userData['tokenKey']?.substring(0, 10)}...',
          );
          debugPrint('   Timestamp: ${userData['timestamp']}');

          return LocalUsersModel(
            id: userData['id'],
            collectionId: userData['collectionId'],
            collectionName: userData['collectionName'],
            email: userData['email'],
            name: userData['name'],
            tripNumberId: userData['tripNumberId'],
            token: userData['tokenKey'],
          );
        } else {
          debugPrint(
            '⚠️ User in SharedPreferences does not match requested ID',
          );
        }
      } else {
        debugPrint('📦 No user data found in SharedPreferences');
      }

      // Step 2️⃣: Fallback to ObjectBox
      debugPrint('🏛️ Searching ObjectBox for user ID: $userId');

      final user =
          _box
              .query(LocalUsersModel_.pocketbaseId.equals(userId))
              .build()
              .findFirst();

      if (user == null) {
        debugPrint('⚠️ User not found in ObjectBox for ID: $userId');
        throw const CacheException(message: 'User not found in local storage');
      }

      // Step 3️⃣: Massive debug logs for loaded user
      debugPrint('✅ Successfully loaded user from ObjectBox');
      debugPrint('   👤 Name: ${user.name}');
      debugPrint('   📧 Email: ${user.email}');
      debugPrint('   🎫 Trip Number ID: ${user.tripNumberId}');
      debugPrint('   🔑 Token: ${user.token?.substring(0, 10)}...');
      debugPrint('   🆔 Pocketbase ID: ${user.pocketbaseId}');
      debugPrint('   ObjectBox ID: ${user.objectBoxId}');

      // Trip info
      debugPrint('   🏷️ Trip Info:');
      debugPrint('      Trip ID: ${user.trip.target?.id ?? 'N/A'}');
      debugPrint('      Trip Name: ${user.trip.target?.name ?? 'N/A'}');

      return user;
    } catch (e) {
      debugPrint('❌ Local storage error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
Future<LocalUsersModel> forceReloadLocalUserById(String userId) async {
  try {
    final safeUserId = userId.trim();
    debugPrint('🔁 LOCAL: Force reloading user by ID="$safeUserId"');

    if (safeUserId.isEmpty) {
      debugPrint('⚠️ LOCAL: userId is empty. Cannot query ObjectBox safely.');
      throw const CacheException(message: 'Invalid userId (empty)');
    }

    // -----------------------------------------------------
    // 1️⃣ Reload User from ObjectBox (fresh query)
    // -----------------------------------------------------
    final userQuery =
        _box.query(LocalUsersModel_.pocketbaseId.equals(safeUserId)).build();
    final user = userQuery.findFirst();
    userQuery.close();

    if (user == null) {
      // ❌ User itself must exist (this is the only hard fail)
      throw const CacheException(message: 'User not found in local DB');
    }

    debugPrint('👤 User reloaded → ${user.name} (OBX: ${user.objectBoxId})');

    // -----------------------------------------------------
    // 2️⃣ Reload Trip relation (NULL-SAFE + BROKEN-RELATION SAFE)
    // -----------------------------------------------------
    try {
      // Prefer targetId because it’s the real ObjectBox relation id
      final tripObxId = user.trip.targetId;

      // ✅ If no trip is set or invalid → clear it safely and continue
      if (tripObxId == 0) {
        debugPrint('ℹ️ User has no active trip (targetId=0). Clearing & bypassing.');
        user.trip
          ..target = null
          ..targetId = 0;
      } else {
        final fullTrip = tripBox.get(tripObxId);

        if (fullTrip != null) {
          user.trip
            ..target = fullTrip
            ..targetId = fullTrip.objectBoxId;

          debugPrint('📦 Trip relation reloaded → ${fullTrip.name} (OBX: ${fullTrip.objectBoxId})');
        } else {
          // ✅ Relation points to missing Trip record → clear safely
          debugPrint('⚠️ Trip targetId=$tripObxId but trip record missing. Clearing relation.');
          user.trip
            ..target = null
            ..targetId = 0;
        }
      }
    } catch (e) {
      // ✅ Trip MUST NEVER break the flow
      debugPrint('⚠️ Trip reload failed (ignored): $e');
      user.trip
        ..target = null
        ..targetId = 0;
    }

    // -----------------------------------------------------
    // 3️⃣ Persist User so listeners/UI refresh
    // -----------------------------------------------------
    _box.put(user);

    // -----------------------------------------------------
    // 4️⃣ Debug logs
    // -----------------------------------------------------
    debugPrint('✅ LOCAL: User force reload COMPLETE');
    debugPrint('   👤 Name: ${user.name}');
    debugPrint('   📧 Email: ${user.email}');
    debugPrint('   🎫 Trip Number ID: ${user.tripNumberId}');
    debugPrint('   🆔 Pocketbase ID: ${user.pocketbaseId}');
    debugPrint('   ObjectBox ID: ${user.objectBoxId}');
    debugPrint('   🏷️ Trip OBX ID: ${user.trip.targetId == 0 ? 'NO ACTIVE TRIP' : user.trip.targetId}');
    debugPrint('   🏷️ Trip PB ID: ${user.trip.target?.id ?? 'NO ACTIVE TRIP'}');

    return user;
  } catch (e, st) {
    debugPrint('❌ forceReloadLocalUserById ERROR: $e\n$st');
    throw CacheException(message: e.toString());
  }
}


  @override
  Future<void> saveUser(LocalUsersModel user) async {
    try {
      debugPrint(
        '💾 [OFFLINE-FIRST] Saving user data locally for offline use...',
      );

      // Step 1️⃣: Clear existing local user data (optional, prevents duplicates)
      await clearUser();

      // Step 2️⃣: Save/update user in ObjectBox
      final existingUser =
          _box
              .query(LocalUsersModel_.pocketbaseId.equals(user.pocketbaseId!))
              .build()
              .findFirst();

      LocalUsersModel updatedUser;

      if (existingUser != null) {
        debugPrint('🔄 Updating existing user in ObjectBox: ${user.name}');
        updatedUser = existingUser;

        // Update fields
        updatedUser.name = user.name;
        updatedUser.email = user.email;
        updatedUser.tripNumberId = user.tripNumberId;
        updatedUser.token = user.token;

        // Update related fields
        updatedUser.trip.target = user.trip.target;
        

        _box.put(updatedUser);
      } else {
        debugPrint('➕ Adding new user to ObjectBox: ${user.name}');
        _box.put(user);
        updatedUser = user;
      }

      debugPrint(
        '✅ User saved in ObjectBox successfully → OBX ID: ${updatedUser.objectBoxId} for ${updatedUser.name} ${updatedUser.pocketbaseId} with trip number id: ${updatedUser.tripNumberId}',
      );

      // Step 3️⃣: Save lightweight data in SharedPreferences
      final userData = {
        'id': updatedUser.id,
        'collectionId': updatedUser.collectionId,
        'collectionName': updatedUser.collectionName,
        'email': updatedUser.email,
        'name': updatedUser.name,
        'tripNumberId': updatedUser.tripNumberId,
        'tokenKey': updatedUser.token,
        'savedOffline': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs.setString('user_data', jsonEncode(userData));
      await _prefs.setString('auth_token', updatedUser.token ?? '');

      debugPrint('✅ User data cached in SharedPreferences for offline access');
      debugPrint('   👤 User: ${updatedUser.name}');
      debugPrint('   📧 Email: ${updatedUser.email}');
      debugPrint('   🆔 ID: ${updatedUser.id}');
      debugPrint('   🔑 Token: ${updatedUser.token?.substring(0, 10)}...');
    } catch (e) {
      debugPrint('❌ Failed to save user locally: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> clearUser() async {
    debugPrint('🧹 Clearing user data from local storage');
    _box.removeAll();
    await _prefs.remove('user_data');
    await _prefs.remove('user_trip_data');
  }

  @override
  Future<bool> hasUser() async {
    final query =
        _box.query(LocalUsersModel_.pocketbaseId.notEquals('')).build();
    final count = query.count();
    final hasStoredUser = _prefs.containsKey('user_data');
    debugPrint('📊 Current users in storage: $count');
    debugPrint('📦 Has stored user data: $hasStoredUser');
    return count > 0 && hasStoredUser;
  }

  @override
  Future<TripModel> loadLocalUserTrip(String userId) async {
    try {
      debugPrint('LOCAL 🔄 loadLocalUserTrip for user: $userId');

      // 1️⃣ Load User By PB ID
      final user =
          _box
              .query(LocalUsersModel_.pocketbaseId.equals(userId))
              .build()
              .findFirst();

      if (user == null) {
        debugPrint('⚠️ User not found in local DB');
        throw const CacheException(message: 'User not found in local DB');
      }

      final trip = user.trip.target;

      if (trip == null) {
        debugPrint('⚠️ No Trip assigned to this user');
        throw const CacheException(message: 'No trip found for this user');
      }

      debugPrint(
        '📦 Trip found → ${trip.name} (OBX: ${trip.objectBoxId}) with delivery data length → ${trip.deliveryData.length}',
      );

      // 2️⃣ Load Delivery Team safely
      final dtRef = trip.deliveryTeam.target;
      if (dtRef != null) {
        final fullDT = deliveryTeamBox.get(dtRef.objectBoxId);
        if (fullDT != null) {
          trip.deliveryTeam.target = fullDT;
          trip.deliveryTeam.targetId = fullDT.objectBoxId;
          debugPrint('👥 Delivery Team loaded → ${fullDT.id}');
        }
      }
      // 2️⃣ Load Delivery Team safely
      final otpRef = trip.otp.target;
      if (otpRef != null) {
        final fullOtp = otpBox.get(otpRef.dbId);
        if (fullOtp != null) {
          trip.otp.target = fullOtp;
          trip.otp.targetId = fullOtp.dbId;
          debugPrint('👥 intransit OTP loaded → ${fullOtp.id}');
        }
      }
      // 2️⃣ Load Delivery Team safely
      final endTripOtpRef = trip.endTripOtp.target;
      if (endTripOtpRef != null) {
        final fullOtp = endTripOtpBox.get(endTripOtpRef.dbId);
        if (fullOtp != null) {
          trip.endTripOtp.target = fullOtp;
          trip.endTripOtp.targetId = fullOtp.dbId;
          debugPrint('👥 end trip OTP loaded → ${fullOtp.id}');
        }
      }

      // 3️⃣ Load Delivery Data safely
      final ddList = trip.deliveryData.toList();
      final cleanedDD = <DeliveryDataModel>[];
      for (var d in ddList) {
        final fullDD = deliveryDataBox.get(d.objectBoxId);
        if (fullDD != null) {
          cleanedDD.add(fullDD);
          debugPrint(
            '📦 DeliveryData loaded → ${fullDD.ownerName} (OBX: ${fullDD.objectBoxId})',
          );
        }
      }
      trip.deliveryData.clear();
      trip.deliveryData.addAll(cleanedDD);

      // 4️⃣ Load End Trip Checklist safely
      final endChecklists = trip.endTripChecklist.toList();
      final cleanedChecklist = <EndTripChecklistModel>[];
      for (var c in endChecklists) {
        final fullChecklist = endTripChecklistBox.get(c.dbId);
        if (fullChecklist != null) {
          cleanedChecklist.add(fullChecklist);
          debugPrint(
            '📋 EndTrip Checklist loaded → ${fullChecklist.objectName}',
          );
        }
      }
      trip.endTripChecklist.clear();
      trip.endTripChecklist.addAll(cleanedChecklist);

      // 5️⃣ Load Trip Updates safely
      final tripUpdates = trip.tripUpdates.toList();
      final cleanedUpdates = <TripUpdateModel>[];
      for (var u in tripUpdates) {
        final fullUpdate = tripUpdateBox.get(u.dbId);
        if (fullUpdate != null) {
          cleanedUpdates.add(fullUpdate);
          debugPrint('📋 Trip Update loaded → ${fullUpdate.description}');
        }
      }
      trip.tripUpdates.clear();
      trip.tripUpdates.addAll(cleanedUpdates);

      // 6️⃣ Load Cancelled Invoices safely
      final cancelledInvoices = trip.cancelledInvoices.toList();
      final cleanedInvoices = <CancelledInvoiceModel>[];
      for (var i in cancelledInvoices) {
        final fullInvoice = cancelledInvoiceBox.get(i.objectBoxId);
        if (fullInvoice != null) {
          cleanedInvoices.add(fullInvoice);
          debugPrint('📋 Cancelled Invoice loaded → ${fullInvoice.id}');
        }
      }
      trip.cancelledInvoices.clear();
      trip.cancelledInvoices.addAll(cleanedInvoices);

      final deliveryCollection = trip.deliveryCollection.toList();
      final cleanedCollection = <CollectionModel>[];
      for (var c in deliveryCollection) {
        final fullCollection = deliveryCollectonBox.get(c.objectBoxId);
        if (fullCollection != null) {
          cleanedCollection.add(fullCollection);
          debugPrint('📋 Delivery Collection loaded → ${fullCollection.id}');
        }
      }
      trip.deliveryCollection.clear();
      trip.deliveryCollection.addAll(cleanedCollection);

      // 4️⃣ Load intransit Trip Checklist safely
      final intransitChecklist = trip.checklist.toList();
      final cleanedIntransitChecklist = <ChecklistModel>[];
      for (var c in intransitChecklist) {
        final fullChecklist = checklistBox.get(c.dbId);
        if (fullChecklist != null) {
          cleanedIntransitChecklist.add(fullChecklist);
          debugPrint(
            '📋 In-transit Checklist loaded → ${fullChecklist.objectName}',
          );
        }
      }
      trip.checklist.clear();
      trip.checklist.addAll(cleanedIntransitChecklist);

      debugPrint('✅ Trip fully loaded with required relations');
      return trip;
    } catch (e) {
      debugPrint('LOCAL ❌ loadLocalUserTrip ERROR: $e');
      throw CacheException(message: e.toString());
    }
  }
@override
Future<TripModel> forceReloadLocalUserTrip(String userId) async {
  try {
    debugPrint('🔁 LOCAL: Force reloading FULL trip for user=$userId');

    final userQuery =
        _box.query(LocalUsersModel_.pocketbaseId.equals(userId)).build();
    final user = userQuery.findFirst();
    userQuery.close();

    if (user == null) {
      throw const CacheException(message: 'User not found in local DB');
    }

    final tripRef = user.trip.target;
    if (tripRef == null) {
      throw const CacheException(message: 'No trip assigned to this user');
    }

    final tripObxId = tripRef.objectBoxId;
    if (tripObxId <= 0) {
      debugPrint('⚠️ Trip target exists but has invalid OBX id=$tripObxId');
      throw const CacheException(message: 'Trip has invalid local ObjectBox ID');
    }

    final trip = tripBox.get(tripObxId);
    if (trip == null) {
      throw const CacheException(message: 'Trip record missing in DB');
    }

    debugPrint('📦 Trip reloaded → ${trip.name} (OBX: ${trip.objectBoxId})');

    // -----------------------------------------------------
    // 2️⃣ Reload Delivery Team
    // -----------------------------------------------------
    final dtRef = trip.deliveryTeam.target;
    if (dtRef != null && dtRef.objectBoxId > 0) {
      final fullDT = deliveryTeamBox.get(dtRef.objectBoxId);
      if (fullDT != null) {
        trip.deliveryTeam
          ..target = fullDT
          ..targetId = fullDT.objectBoxId;
        debugPrint('👥 DeliveryTeam reloaded → ${fullDT.id}');
      }
    }

    // -----------------------------------------------------
    // 3️⃣ Reload In-Transit OTP
    // -----------------------------------------------------
    final otpRef = trip.otp.target;
    final otpObxId = otpRef?.dbId ?? 0;
    if (otpRef != null && otpObxId > 0) {
      final fullOtp = otpBox.get(otpObxId);
      if (fullOtp != null) {
        trip.otp
          ..target = fullOtp
          ..targetId = fullOtp.dbId;
        debugPrint('🔐 In-transit OTP reloaded → ${fullOtp.id}');
      }
    } else if (otpRef != null) {
      debugPrint('⚠️ OTP target exists but has invalid dbId=$otpObxId');
    }

    // -----------------------------------------------------
    // 4️⃣ Reload End Trip OTP
    // -----------------------------------------------------
    final endOtpRef = trip.endTripOtp.target;
    final endOtpObxId = endOtpRef?.dbId ?? 0;
    if (endOtpRef != null && endOtpObxId > 0) {
      final fullOtp = endTripOtpBox.get(endOtpObxId);
      if (fullOtp != null) {
        trip.endTripOtp
          ..target = fullOtp
          ..targetId = fullOtp.dbId;
        debugPrint('🔐 EndTrip OTP reloaded → ${fullOtp.id}');
      }
    } else if (endOtpRef != null) {
      debugPrint('⚠️ EndTripOtp target exists but has invalid dbId=$endOtpObxId');
    }

    // -----------------------------------------------------
    // 5️⃣ Reload Delivery Data
    // -----------------------------------------------------
    final deliveryList = trip.deliveryData.toList();
    final refreshedDeliveries = <DeliveryDataModel>[];

    for (final d in deliveryList) {
      final id = d.objectBoxId;
      if (id <= 0) {
        debugPrint('⚠️ DeliveryData has invalid OBX id=$id (pbId=${d.id})');
        continue;
      }
      final fullDD = deliveryDataBox.get(id);
      if (fullDD != null) {
        refreshedDeliveries.add(fullDD);
        debugPrint('📦 DeliveryData reloaded → ${fullDD.ownerName}');
      }
    }

    trip.deliveryData
      ..clear()
      ..addAll(refreshedDeliveries);

    // -----------------------------------------------------
    // 6️⃣ Reload End Trip Checklist
    // -----------------------------------------------------
    final checklistList = trip.endTripChecklist.toList();
    final refreshedChecklist = <EndTripChecklistModel>[];

    for (final c in checklistList) {
      final id = c.dbId;
      if (id <= 0) {
        debugPrint('⚠️ EndTripChecklist has invalid dbId=$id (pbId=${c.id})');
        continue;
      }
      final full = endTripChecklistBox.get(id);
      if (full != null) {
        refreshedChecklist.add(full);
        debugPrint('📋 Checklist reloaded → ${full.objectName}');
      }
    }

    trip.endTripChecklist
      ..clear()
      ..addAll(refreshedChecklist);

    // -----------------------------------------------------
    // 7️⃣ Reload Trip Updates  ✅ FIXED
    // -----------------------------------------------------
    final updatesList = trip.tripUpdates.toList();
    final refreshedUpdates = <TripUpdateModel>[];

    debugPrint('🧾 TripUpdates: linkedCount=${updatesList.length}');
    for (final u in updatesList) {
      final id = u.dbId; // or u.objectBoxId (use whichever is your OBX id field)
      if (id <= 0) {
        debugPrint('⚠️ TripUpdate has invalid dbId=$id (pbId=${u.id}) — skipping get()');
        continue;
      }

      final full = tripUpdateBox.get(id);
      if (full != null) {
        refreshedUpdates.add(full);
        debugPrint('📋 TripUpdate reloaded → ${full.description}');
      } else {
        debugPrint('⚠️ TripUpdate missing in box for dbId=$id (pbId=${u.id})');
      }
    }

    trip.tripUpdates
      ..clear()
      ..addAll(refreshedUpdates);

    // -----------------------------------------------------
    // 8️⃣ Reload Cancelled Invoices
    // -----------------------------------------------------
    final cancelledList = trip.cancelledInvoices.toList();
    final refreshedInvoices = <CancelledInvoiceModel>[];

    for (final i in cancelledList) {
      final id = i.objectBoxId;
      if (id <= 0) {
        debugPrint('⚠️ CancelledInvoice has invalid OBX id=$id (pbId=${i.id})');
        continue;
      }
      final full = cancelledInvoiceBox.get(id);
      if (full != null) {
        refreshedInvoices.add(full);
        debugPrint('📋 CancelledInvoice reloaded → ${full.id}');
      }
    }

    trip.cancelledInvoices
      ..clear()
      ..addAll(refreshedInvoices);

    // -----------------------------------------------------
    // 9️⃣ Reload Delivery Collection
    // -----------------------------------------------------
    final collectionList = trip.deliveryCollection.toList();
    final refreshedCollection = <CollectionModel>[];

    for (final c in collectionList) {
      final id = c.objectBoxId;
      if (id <= 0) {
        debugPrint('⚠️ Collection has invalid OBX id=$id (pbId=${c.id})');
        continue;
      }
      final full = deliveryCollectonBox.get(id);
      if (full != null) {
        refreshedCollection.add(full);
        debugPrint('📋 Collection reloaded → ${full.id}');
      }
    }

    trip.deliveryCollection
      ..clear()
      ..addAll(refreshedCollection);

    tripBox.put(trip);

    debugPrint('✅ LOCAL: Force reload trip COMPLETE');
    debugPrint('   ✅ tripUpdatesReloaded=${refreshedUpdates.length}');
    return trip;
  } catch (e, st) {
    debugPrint('❌ forceReloadLocalUserTrip ERROR: $e\n$st');
    throw CacheException(message: e.toString());
  }
}


  @override
  Future<void> cacheUserData(LocalUsersModel user) async {
    try {
      debugPrint('💾 Caching user data locally');

      // Clear existing user data
      await clearUser();

      // Save to ObjectBox
      _box.put(user);

      // Save to SharedPreferences for quick access
      final userData = {
        'id': user.id,
        'collectionId': user.collectionId,
        'collectionName': user.collectionName,
        'email': user.email,
        'name': user.name,
        'tripNumberId': user.tripNumberId,
        'deliveryTeam':
            user.deliveryTeam.target?.id, // Store ID for ToOne relation
      };

      await _prefs.setString('user_data', jsonEncode(userData));

      debugPrint('✅ User cached successfully');
      debugPrint('   👤 User: ${user.name}');
      debugPrint('   📧 Email: ${user.email}');
      debugPrint('   🎫 Trip Number: ${user.tripNumberId}');
    } catch (e) {
      debugPrint('❌ Cache operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheUserTripData(TripModel trip) async {
    try {
      debugPrint('💾 Caching trip data locally');

      // Save to SharedPreferences with null-safe parameters
      final tripData = {
        'id': trip.id,
        'tripNumberId': trip.tripNumberId,
        'isAccepted': trip.isAccepted,
        'deliveryTeam':
            trip.deliveryTeam.target?.id, // Consistent serialization
        'personels': trip.personels.map((p) => p.toJson()).toList(),
        'deliveryVehicle': trip.deliveryVehicle.target?.toJson(),
        'checklist': trip.checklist.map((c) => c.toJson()).toList(),
        'deliveryData': trip.deliveryData.map((d) => d.toJson()).toList(),
        'otp': trip.otp.target?.toJson(),
        'endTripOtp': trip.endTripOtp.target?.toJson(),
        'endTripChecklist':
            trip.endTripChecklist.map((e) => e.toJson()).toList(),
        'tripUpdates': trip.tripUpdates.map((u) => u.toJson()).toList(),
        'user': trip.user.target?.toJson(),
        'totalTripDistance': trip.totalTripDistance,
        'latitude': trip.latitude?.toString(),
        'longitude': trip.longitude?.toString(),
        'timeAccepted': trip.timeAccepted?.toIso8601String(),
        'isEndTrip': trip.isEndTrip,
        'timeEndTrip': trip.timeEndTrip?.toIso8601String(),
        'created': trip.created?.toIso8601String(),
        'updated': trip.updated?.toIso8601String(),
        'qrCode': trip.qrCode,
      };

      await _prefs.setString('user_trip_data', jsonEncode(tripData));

      debugPrint('✅ Trip cached successfully');
      debugPrint('   🎫 Trip Number: ${trip.tripNumberId ?? 'N/A'}');
      debugPrint(
        '   🚛 Delivery Vehicle: ${trip.deliveryVehicle.target?.plateNo ?? 'Not assigned'}',
      );
      debugPrint('   📦 Delivery Data: ${trip.deliveryData.length}');
      debugPrint('   🔑 OTP: ${trip.otp.target?.id ?? 'Not set'}');
      debugPrint('   📋 End Trip Checklist: ${trip.endTripChecklist.length}');
      debugPrint('   📍 Trip Updates: ${trip.tripUpdates.length}');
    } catch (e) {
      debugPrint('❌ Trip cache operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  /// --- Updated helper: removes duplicate trips AND null-ID trips
  Future<void> _removeDuplicateTrips() async {
    final allTrips = tripBox.getAll();

    final seenIds = <String>{};
    int removedDuplicates = 0;
    int removedNullTrips = 0;

    for (final trip in allTrips) {
      // --- Case 1: Trip has NO valid ID → remove it.
      if (trip.id == null || trip.id!.trim().isEmpty) {
        tripBox.remove(trip.objectBoxId);
        removedNullTrips++;
        continue;
      }

      // --- Case 2: Duplicate ID → remove it.
      if (seenIds.contains(trip.id)) {
        tripBox.remove(trip.objectBoxId);
        removedDuplicates++;
      } else {
        seenIds.add(trip.id!);
      }
    }

    debugPrint(
      '🧹 _removeDuplicateTrips(): '
      'Removed $removedNullTrips null-ID trips, '
      'Removed $removedDuplicates duplicate trips. '
      'Remaining trips: ${tripBox.count()}',
    );
  }

  @override
  Future<void> saveUserTripByUserId(String userId, TripModel trip) async {
    try {
      debugPrint("💾 LOCAL SYNC: Saving trip for user ID: $userId");

      // ---------------------------------------------------------
      // STEP 0 — Check if the user already has a Trip
      // ---------------------------------------------------------
      final existingUser =
          _box
              .query(LocalUsersModel_.pocketbaseId.equals(userId))
              .build()
              .findFirst();

      TripModel? existingTrip;

      if (existingUser != null && existingUser.trip.target != null) {
        existingTrip = existingUser.trip.target;
        debugPrint(
          "🔍 Existing trip detected → OBX ID: ${existingTrip?.objectBoxId}",
        );
      }

      // ---------------------------------------------------------
      // STEP 1 — If a trip exists, remove duplicates BEFORE syncing
      // ---------------------------------------------------------
      if (existingTrip != null) {
        debugPrint("🧹 Running duplicate cleanup BEFORE syncing trip...");
        await _removeDuplicateTrips();
      }

      // ---------------------------------------------------------
      // STEP 2 — Check if incoming trip exists (reuse OBX ID)
      // ---------------------------------------------------------
      final dbTrip =
          tripBox
              .query(TripModel_.id.equals(trip.id ?? ""))
              .build()
              .findFirst();

      if (dbTrip != null) {
        trip.objectBoxId = dbTrip.objectBoxId;
        debugPrint("🔄 Trip exists → Reusing OBX ID: ${trip.objectBoxId}");
      }

      // ---------------------------------------------------------
      // STEP 3 — Clean related data before inserting new relation data
      // ---------------------------------------------------------
      await _cleanDeliveryData();
      await _cleanDeliveryTeam();
      await _cleanPersonnel(); //← if needed
      await _cleanTripUpdates();
      await _cleanCancelledInvoices();
      await _cleanInTransitOtp();
      await _cleanEndTripOtp();
      await _cleanDeliveryCollections();
      await _cleanEndTripChecklist();
      await _cleanChecklistData();
      // ---------------------------------------------------------
      // STEP 4 — Sync related data
      // ---------------------------------------------------------
      await _syncDeliveryDataForTrip(trip);
      await _syncDeliveryTeamForTrip(trip);
      await _syncVehicleForTrip(trip);
      await _syncPersonnelsForTrip(trip); //← if needed
      await _syncTripUpdatesForTrip(trip);
      await _syncCancelledInvoicesForTrip(trip);
      await _syncInTransitOtpForTrip(trip);
      await _syncEndTripOtpForTrip(trip);
      await _syncCollectionsForTrip(trip);
      await _syncEndTripChecklistForTrip(trip);
      await _syncIntransitChecklistForTrip(trip);
      // ---------------------------------------------------------
      // STEP 5 — Save Trip to ObjectBox
      // ---------------------------------------------------------
      final tripObxId = tripBox.put(trip);
      debugPrint(
        "🟦 Trip saved → OBX ID: $tripObxId | Name: ${trip.name}  Delivery Team Ids: ${trip.deliveryTeam.target?.id} DeliveryData Length ${trip.deliveryData.length}",
      );

      // ---------------------------------------------------------
      // STEP 6 — Link Trip to User
      // ---------------------------------------------------------
      LocalUsersModel? user = existingUser;

      if (user == null) {
        debugPrint("⚠️ User not found. Creating new user entry...");
        user = LocalUsersModel(id: userId);
      }

      user.trip.target = trip;
      _box.put(user);

      debugPrint(
        "👤 User synced → PB ID: $userId | Trip OBX: ${trip.objectBoxId}",
      );
      debugPrint("✅ LOCAL SYNC COMPLETE → saveUserTripByUserId()");
    } catch (e) {
      debugPrint("❌ ERROR: saveUserTripByUserId() → $e");
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _syncIntransitChecklistForTrip(TripModel trip) async {
    final List<ChecklistModel> updatedChecklist = [];

    for (final c in trip.checklist) {
      debugPrint(
        '📋 Syncing Checklist → ${c.objectName}, '
        'PB: ${c.pocketbaseId}, OBX: ${c.objectBoxId}',
      );

      // -------------------------------------------------------------
      // 1️⃣ Find existing checklist by PocketBase ID
      // -------------------------------------------------------------
      final existing =
          checklistBox
              .query(ChecklistModel_.pocketbaseId.equals(c.pocketbaseId))
              .build()
              .findFirst();

      ChecklistModel updated;

      if (existing != null) {
        final full = checklistBox.get(existing.objectBoxId);

        if (full == null) {
          debugPrint('⚠️ Skipped: existing checklist OBX object was null');
          continue;
        }

        // -------------------------------------------------------------
        // 2️⃣ UPDATE fields
        // -------------------------------------------------------------
        full.id = c.id;
        full.objectName = c.objectName;
        full.description = c.description;
        full.status = c.status;
        full.isChecked = c.isChecked;
        full.timeCompleted = c.timeCompleted;

        // -------------------------------------------------------------
        // 3️⃣ SYNC: Trip relation (ToOne)
        // -------------------------------------------------------------
        if (c.trip.target != null) {
          final remoteTrip = c.trip.target!;

          final existingTrip =
              tripBox
                  .query(
                    TripModel_.pocketbaseId.equals(
                      remoteTrip.pocketbaseId ?? '',
                    ),
                  )
                  .build()
                  .findFirst();

          if (existingTrip != null) {
            full.trip.target = tripBox.get(existingTrip.objectBoxId);
          } else {
            final newTripId = tripBox.put(
              TripModel()
                ..id = remoteTrip.id
                ..pocketbaseId = remoteTrip.pocketbaseId
                ..name = remoteTrip.name,
            );
            full.trip.target = tripBox.get(newTripId);
          }
        } else {
          full.trip.target = null;
        }

        checklistBox.put(full);
        updated = full;

        debugPrint('🔁 Checklist updated → ${updated.objectName}');
      } else {
        // -------------------------------------------------------------
        // 4️⃣ NEW checklist
        // -------------------------------------------------------------
        final newId = checklistBox.put(c);
        final fresh = checklistBox.get(newId)!;

        // --- Trip relation ---
        if (c.trip.target != null) {
          final remoteTrip = c.trip.target!;

          final existingTrip =
              tripBox
                  .query(
                    TripModel_.pocketbaseId.equals(
                      remoteTrip.pocketbaseId ?? '',
                    ),
                  )
                  .build()
                  .findFirst();

          if (existingTrip != null) {
            fresh.trip.target = tripBox.get(existingTrip.objectBoxId);
          } else {
            final newTripId = tripBox.put(
              TripModel()
                ..id = remoteTrip.id
                ..pocketbaseId = remoteTrip.pocketbaseId
                ..name = remoteTrip.name,
            );
            fresh.trip.target = tripBox.get(newTripId);
          }
        }

        checklistBox.put(fresh);
        updated = fresh;

        debugPrint('✅ New Checklist saved → ${updated.objectName}');
      }

      updatedChecklist.add(updated);
    }

    // -------------------------------------------------------------
    // 5️⃣ Re-attach checklist to trip & save
    // -------------------------------------------------------------
    trip.checklist.clear();
    trip.checklist.addAll(updatedChecklist);
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → ${trip.name} '
      'Checklist count: ${trip.checklist.length}',
    );
  }

  Future<void> _syncVehicleForTrip(TripModel trip) async {
    final vehicle = trip.deliveryVehicle.target;
    if (vehicle == null) return;

    debugPrint(
      '🔍 Syncing vehicle for trip "${trip.name}" → PB: ${vehicle.pocketbaseId}, Name: ${vehicle.name}',
    );

    final existingVehicle =
        vehicleBox
            .query(
              DeliveryVehicleModel_.pocketbaseId.equals(vehicle.pocketbaseId),
            )
            .build()
            .findFirst();

    DeliveryVehicleModel updatedVehicle;

    if (existingVehicle != null) {
      // Load existing vehicle from ObjectBox
      final fullVehicle = vehicleBox.get(existingVehicle.objectBoxId);
      if (fullVehicle != null) {
        // ✅ Update the name (and any other fields you want to sync)
        fullVehicle.name = vehicle.name;
                fullVehicle.type = vehicle.type;
                fullVehicle.make = vehicle.make;
                fullVehicle.volumeCapacity = vehicle.volumeCapacity;
                fullVehicle.weightCapacity = vehicle.weightCapacity;

        // Add more fields if needed, e.g., type, plateNumber
        vehicleBox.put(fullVehicle);

        updatedVehicle = fullVehicle;

        debugPrint(
          '🔁 Vehicle updated → PB: ${updatedVehicle.pocketbaseId}, Name: ${updatedVehicle.name}, OBX: ${updatedVehicle.objectBoxId}',
        );
      } else {
        debugPrint(
          '⚠️ Could not load full vehicle for PB: ${vehicle.pocketbaseId}',
        );
        return;
      }
    } else {
      // New vehicle
      final newId = vehicleBox.put(vehicle);
      updatedVehicle = vehicleBox.get(newId)!;

      debugPrint(
        '✅ New vehicle saved → PB: ${updatedVehicle.pocketbaseId}, Name: ${updatedVehicle.name}, OBX: $newId',
      );
    }

    // Assign fully updated vehicle to trip
    trip.deliveryVehicle.target = updatedVehicle; // keep this
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → Trip ID: ${trip.id}, ObjectBox ID: ${trip.objectBoxId}, Vehicle OBX ID: ${trip.deliveryVehicle.targetId}, Vehicle Name Using target: ${trip.deliveryVehicle.target?.name}',
    );
  }

  Future<void> _syncDeliveryTeamForTrip(TripModel trip) async {
    final deliveryTeam = trip.deliveryTeam.target;
    if (deliveryTeam == null) return;

    debugPrint(
      '🔍 Syncing DeliveryTeam for trip "${trip.name}" '
      '→ PB: ${deliveryTeam.pocketbaseId}, ActiveDeliveries: ${deliveryTeam.activeDeliveries}',
    );

    // -----------------------------
    // 1️⃣ Sync DeliveryVehicle first
    // -----------------------------
    final pbVehicle = deliveryTeam.deliveryVehicle.target;
    DeliveryVehicleModel? syncedVehicle;

    if (pbVehicle != null) {
      // Save or update the vehicle in ObjectBox
      final existingVehicle =
          vehicleBox
              .query(
                DeliveryVehicleModel_.pocketbaseId.equals(
                  pbVehicle.pocketbaseId,
                ),
              )
              .build()
              .findFirst();

      if (existingVehicle != null) {
        // Update existing vehicle
        existingVehicle.plateNo = pbVehicle.plateNo;
        existingVehicle.make = pbVehicle.make;
        existingVehicle.name = pbVehicle.name;
        // ... add other fields if needed

        vehicleBox.put(existingVehicle);
        syncedVehicle = existingVehicle;

        debugPrint(
          '🚗 DeliveryVehicle updated → PB: ${syncedVehicle.pocketbaseId}, OBX: ${syncedVehicle.objectBoxId}, Plate: ${syncedVehicle.name}',
        );
      } else {
        // New vehicle
        final newVehicleId = vehicleBox.put(pbVehicle);
        syncedVehicle = vehicleBox.get(newVehicleId)!;

        debugPrint(
          '🚗 DeliveryVehicle saved → PB: ${syncedVehicle.pocketbaseId}, OBX: $newVehicleId, Plate: ${syncedVehicle.plateNo}',
        );
      }
    }

    // -----------------------------
    // 2️⃣ Sync DeliveryTeam
    // -----------------------------
    final existingTeam =
        deliveryTeamBox
            .query(
              DeliveryTeamModel_.pocketbaseId.equals(deliveryTeam.pocketbaseId),
            )
            .build()
            .findFirst();

    DeliveryTeamModel updatedTeam;

    if (existingTeam != null) {
      final fullTeam = deliveryTeamBox.get(existingTeam.objectBoxId);
      if (fullTeam != null) {
        // Update team fields
        fullTeam.id = deliveryTeam.id;
        fullTeam.activeDeliveries = deliveryTeam.activeDeliveries;
        fullTeam.totalDelivered = deliveryTeam.totalDelivered;
        fullTeam.undeliveredCustomers = deliveryTeam.undeliveredCustomers;
        fullTeam.totalDistanceTravelled = deliveryTeam.totalDistanceTravelled;

        // Update personnel and checklist
        fullTeam.personels
          ..clear()
          ..addAll(deliveryTeam.personels);
        fullTeam.checklist
          ..clear()
          ..addAll(deliveryTeam.checklist);

        // Link vehicle
        fullTeam.deliveryVehicle.target = syncedVehicle;
        fullTeam.deliveryVehicle.targetId = syncedVehicle?.objectBoxId ?? 0;

        // Link team <-> trip
        fullTeam.trip.target = trip;

        deliveryTeamBox.put(fullTeam);
        updatedTeam = fullTeam;

        debugPrint(
          '🔁 DeliveryTeam updated → PB: ${updatedTeam.pocketbaseId}, OBX: ${updatedTeam.objectBoxId}, Vehicle OBX: ${syncedVehicle?.objectBoxId} Vehicle id: ${syncedVehicle?.pocketbaseId}, Vehicle id: ${syncedVehicle?.name}',
        );
      } else {
        debugPrint('⚠️ Could not load full existing DeliveryTeam from OBX');
        return;
      }
    } else {
      // New team
      if (syncedVehicle != null) {
        deliveryTeam.deliveryVehicle.target = syncedVehicle;
        deliveryTeam.deliveryVehicle.targetId = syncedVehicle.objectBoxId;
      }

      final newTeamId = deliveryTeamBox.put(deliveryTeam);
      updatedTeam = deliveryTeamBox.get(newTeamId)!;

      // Link to trip
      updatedTeam.trip.target = trip;

      debugPrint(
        '✅ New DeliveryTeam saved → PB: ${updatedTeam.pocketbaseId}, OBX: $newTeamId, Vehicle OBX: ${syncedVehicle?.objectBoxId}',
      );
    }

    // -----------------------------
    // 3️⃣ Assign updated team to trip
    // -----------------------------
    trip.deliveryTeam.target = updatedTeam;
    tripBox.put(trip);

    debugPrint(
      '🟦 Delivery Team saved to Trip → '
      'Trip ID: ${trip.id}, OBX: ${trip.objectBoxId}, '
      'DeliveryTeam OBX: ${trip.deliveryTeam.targetId}, '
      'Team Vehicle ID: ${trip.deliveryTeam.target?.deliveryVehicle.target?.name}, '
      'ActiveDeliveries: ${trip.deliveryTeam.target?.activeDeliveries}, '
      'Personnel: ${trip.deliveryTeam.target?.personels.length}',
    );
  }

  Future<void> _syncInTransitOtpForTrip(TripModel trip) async {
    final otp = trip.otp.target;
    if (otp == null) return;

    debugPrint(
      '🔍 Syncing InTransit OTP for trip "${trip.name}" '
      '→ OTP ID: ${otp.id}, Verified: ${otp.isVerified}',
    );

    // -------------------------------------------------
    // 1️⃣ Find existing OTP by PB ID
    // -------------------------------------------------
    final existingOtp =
        otpBox.query(OtpModel_.id.equals(otp.id)).build().findFirst();

    OtpModel syncedOtp;

    if (existingOtp != null) {
      // -------------------------------------------------
      // 2️⃣ Update existing OTP
      // -------------------------------------------------
      final fullOtp = otpBox.get(existingOtp.dbId);
      if (fullOtp == null) {
        debugPrint('⚠️ Failed to load existing OTP from ObjectBox');
        return;
      }

      fullOtp
        ..otpCode = otp.otpCode
        ..generatedCode = otp.generatedCode
        ..isVerified = otp.isVerified
        ..createdAt = otp.createdAt
        ..expiresAt = otp.expiresAt
        ..verifiedAt = otp.verifiedAt
        ..otpType = otp.otpType;

      // Link trip
      fullOtp.trip.target = trip;
      fullOtp.trip.targetId = trip.objectBoxId;

      otpBox.put(fullOtp);
      syncedOtp = fullOtp;

      debugPrint(
        '🔁 OTP updated → PB: ${syncedOtp.id}, OBX: ${syncedOtp.dbId}, '
        'Verified: ${syncedOtp.isVerified}',
      );
    } else {
      // -------------------------------------------------
      // 3️⃣ New OTP
      // -------------------------------------------------
      otp.trip.target = trip;
      otp.trip.targetId = trip.objectBoxId;

      final newOtpId = otpBox.put(otp);
      syncedOtp = otpBox.get(newOtpId)!;

      debugPrint(
        '✅ New OTP saved → PB: ${syncedOtp.id}, OBX: $newOtpId, '
        'Verified: ${syncedOtp.isVerified}',
      );
    }

    // -------------------------------------------------
    // 4️⃣ Attach OTP back to Trip
    // -------------------------------------------------
    trip.otp.target = syncedOtp;
    trip.otp.targetId = syncedOtp.dbId;
    tripBox.put(trip);

    debugPrint(
      '🟦 OTP linked to Trip → '
      'Trip ID: ${trip.id}, OBX: ${trip.objectBoxId}, '
      'OTP OBX: ${trip.otp.targetId}, '
      'OTP Code: ${syncedOtp.otpCode}, '
      'Verified: ${syncedOtp.isVerified}',
    );
  }

  Future<void> _syncEndTripOtpForTrip(TripModel trip) async {
    final endTripOtp = trip.endTripOtp.target;
    if (endTripOtp == null) return;

    debugPrint(
      '🔍 Syncing EndTrip OTP for trip "${trip.name}" '
      '→ OTP ID: ${endTripOtp.id}, Verified: ${endTripOtp.isVerified}',
    );

    // -------------------------------------------------
    // 1️⃣ Find existing EndTrip OTP by PB ID
    // -------------------------------------------------
    final existingOtp =
        endTripOtpBox
            .query(EndTripOtpModel_.id.equals(endTripOtp.id))
            .build()
            .findFirst();

    EndTripOtpModel syncedOtp;

    if (existingOtp != null) {
      // -------------------------------------------------
      // 2️⃣ Update existing EndTrip OTP
      // -------------------------------------------------
      final fullOtp = endTripOtpBox.get(existingOtp.dbId);
      if (fullOtp == null) {
        debugPrint('⚠️ Failed to load existing EndTrip OTP from ObjectBox');
        return;
      }

      fullOtp
        ..otpCode = endTripOtp.otpCode
        ..generatedCode = endTripOtp.generatedCode
        ..isVerified = endTripOtp.isVerified
        ..createdAt = endTripOtp.createdAt
        ..expiresAt = endTripOtp.expiresAt
        ..verifiedAt = endTripOtp.verifiedAt
        ..otpType = endTripOtp.otpType;

      // Link trip
      fullOtp.trip.target = trip;
      fullOtp.trip.targetId = trip.objectBoxId;

      endTripOtpBox.put(fullOtp);
      syncedOtp = fullOtp;

      debugPrint(
        '🔁 EndTrip OTP updated → PB: ${syncedOtp.id}, '
        'OBX: ${syncedOtp.dbId}, Verified: ${syncedOtp.isVerified}',
      );
    } else {
      // -------------------------------------------------
      // 3️⃣ New EndTrip OTP
      // -------------------------------------------------
      endTripOtp.trip.target = trip;
      endTripOtp.trip.targetId = trip.objectBoxId;

      final newOtpId = endTripOtpBox.put(endTripOtp);
      syncedOtp = endTripOtpBox.get(newOtpId)!;

      debugPrint(
        '✅ New EndTrip OTP saved → PB: ${syncedOtp.id}, '
        'OBX: $newOtpId, Verified: ${syncedOtp.isVerified}',
      );
    }

    // -------------------------------------------------
    // 4️⃣ Attach EndTrip OTP back to Trip
    // -------------------------------------------------
    trip.endTripOtp.target = syncedOtp;
    trip.endTripOtp.targetId = syncedOtp.dbId;
    tripBox.put(trip);

    debugPrint(
      '🟦 EndTrip OTP linked to Trip → '
      'Trip ID: ${trip.id}, OBX: ${trip.objectBoxId}, '
      'EndTrip OTP OBX: ${trip.endTripOtp.targetId}, '
      'OTP Code: ${syncedOtp.otpCode}, '
      'Verified: ${syncedOtp.isVerified}',
    );
  }

  Future<void> _syncTripUpdatesForTrip(TripModel trip) async {
    final List<TripUpdateModel> updatedTripUpdates = [];

    for (var update in trip.tripUpdates) {
      debugPrint(
        '📝 Syncing TripUpdate → Trip: ${trip.name}, PB: ${update.pocketbaseId}, db: ${update.objectBoxId}, Status: ${update.status}',
      );

      final existing =
          tripUpdateBox
              .query(TripUpdateModel_.pocketbaseId.equals(update.pocketbaseId))
              .build()
              .findFirst();

      TripUpdateModel updated;

      if (existing != null) {
        final full = tripUpdateBox.get(existing.objectBoxId);
        if (full != null) {
          // Update fields
          full.status = update.status;
          full.date = update.date;
          full.image = update.image;
          full.description = update.description;
          full.latitude = update.latitude;
          full.longitude = update.longitude;
          full.collectionId = update.collectionId;
          full.collectionName = update.collectionName;
          full.trip.target = trip; // ensure relation
          full.tripId = trip.id;

          tripUpdateBox.put(full);
          updated = full;
          debugPrint(
            '🔁 TripUpdate updated → PB: ${updated.pocketbaseId} (OBX: ${updated.objectBoxId})',
          );
        } else {
          continue;
        }
      } else {
        // New record
        update.trip.target = trip;
        update.tripId = trip.id;
        final newId = tripUpdateBox.put(update);
        updated = tripUpdateBox.get(newId)!;
        debugPrint(
          '✅ New TripUpdate saved → PB: ${updated.pocketbaseId} (OBX: ${updated.objectBoxId})',
        );
      }

      updatedTripUpdates.add(updated);
    }

    // Assign fully updated TripUpdates to trip
    trip.tripUpdates.clear();
    trip.tripUpdates.addAll(updatedTripUpdates);
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → Trip ID: ${trip.id}, ObjectBox ID: ${trip.objectBoxId}, '
      'TripUpdates count: ${trip.tripUpdates.length}',
    );
  }

  Future<void> _syncPersonnelsForTrip(TripModel trip) async {
    final List<PersonelModel> updatedPersonnels = [];

    for (var p in trip.personels) {
      debugPrint(
        '👥 Syncing personnel → Trip: ${trip.name}, PB: ${p.pocketbaseId}, db: ${p.objectBoxId}, Name: ${p.name}',
      );

      final existing =
          personnelBox
              .query(PersonelModel_.pocketbaseId.equals(p.pocketbaseId))
              .build()
              .findFirst();

      PersonelModel updated;

      if (existing != null) {
        final full = personnelBox.get(existing.objectBoxId);
        if (full != null) {
          full.name = p.name;
          full.role = p.role;

          personnelBox.put(full);
          updated = full;

          debugPrint(
            '🔁 Personnel updated → ${updated.name} (OBX: ${updated.objectBoxId})',
          );
        } else {
          continue;
        }
      } else {
        final newId = personnelBox.put(p);
        updated = personnelBox.get(newId)!;

        debugPrint(
          '✅ New personnel saved → ${updated.name} (OBX: ${updated.objectBoxId})',
        );
      }

      updatedPersonnels.add(updated);
    }

    // Assign fully updated personnels to trip
    trip.personels.clear();
    trip.personels.addAll(updatedPersonnels);
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → Trip ID: ${trip.id}, ObjectBox ID: ${trip.objectBoxId}, '
      'Personnels count: ${trip.personels.length}',
    );
  }


Future<void> _syncDeliveryDataForTrip(TripModel trip) async {
  // ✅ Snapshot first to avoid concurrent modification on ToMany
  final incomingDeliveries = trip.deliveryData.toList();

  // ✅ Ensure trip has OBX id before linking relations
  if (trip.objectBoxId == 0) {
    trip.objectBoxId = tripBox.put(trip);
  }

  final Map<String, DeliveryDataModel> uniqueDeliveries = {};

  for (final d in incomingDeliveries) {
    final deliveryPbId = (d.pocketbaseId).trim();
    if (deliveryPbId.isEmpty) {
      debugPrint('⚠️ Skipping delivery: missing pocketbaseId/id');
      continue;
    }

    debugPrint('📦 Syncing deliveryData → ${d.ownerName} PB: $deliveryPbId');

    // -------------------------------------------------------------
    // 1️⃣ Load existing or create new DeliveryData
    // -------------------------------------------------------------
    final existing =
        deliveryDataBox
            .query(DeliveryDataModel_.pocketbaseId.equals(deliveryPbId))
            .build()
            .findFirst();

    final fresh = existing != null
        ? deliveryDataBox.get(existing.objectBoxId)!
        : DeliveryDataModel();

    // Copy base fields
    fresh
      ..id = d.id
      ..pocketbaseId = deliveryPbId
      ..ownerName = d.ownerName
      ..deliveryNumber = d.deliveryNumber
      ..province = d.province
      ..municipality = d.municipality
      ..barangay = d.barangay
      ..paymentMode = d.paymentMode
      ..storeName = d.storeName
      ..updated = d.updated
      ..isUnloaded = d.isUnloaded
      ..isUnloading = d.isUnloading
      ..created = d.created
      ..totalDeliveryTime = d.totalDeliveryTime
      ..tripId = trip.id;

    // ✅ Always link to the current trip instance (avoid extra Trip creation)
    fresh.trip.target = trip;

    // -------------------------------------------------------------
    // 2️⃣ Sync Customer (ToOne)
    // -------------------------------------------------------------
    final cust = d.customer.target;
    if (cust != null) {
      final custPbId = (cust.pocketbaseId ).trim();

      if (custPbId.isNotEmpty) {
        final existingCust =
            customerBox
                .query(CustomerDataModel_.pocketbaseId.equals(custPbId))
                .build()
                .findFirst();

        if (existingCust == null) {
          final newCust =
              CustomerDataModel()
                ..id = cust.id
                ..pocketbaseId = custPbId
                ..name = cust.name
                ..province = cust.province
                ..municipality = cust.municipality
                ..barangay = cust.barangay;

          final newId = customerBox.put(newCust);
          fresh.customer.target = customerBox.get(newId);
        } else {
          fresh.customer.target = customerBox.get(existingCust.objectBoxId);
        }
      } else {
        fresh.customer.target = null;
      }
    } else {
      fresh.customer.target = null;
    }

    // -------------------------------------------------------------
    // 3️⃣ Sync Invoices (ToMany) — snapshot first
    // -------------------------------------------------------------
    final invoiceList = <InvoiceDataModel>[];
    final incomingInvoices = d.invoices.toList();

    for (final inv in incomingInvoices) {
      final invPbId = (inv.pocketbaseId ).trim();
      if (invPbId.isEmpty) continue;

      final existingInv =
          invoiceBox
              .query(InvoiceDataModel_.pocketbaseId.equals(invPbId))
              .build()
              .findFirst();

      if (existingInv == null) {
        final newInv =
            InvoiceDataModel()
              ..id = inv.id
              ..pocketbaseId = invPbId
              ..name = inv.name
              ..refId = inv.refId
              ..documentDate = inv.documentDate
              ..volume = inv.volume
              ..weight = inv.weight
            
              ..totalAmount = inv.totalAmount;

        final newId = invoiceBox.put(newInv);
        invoiceList.add(invoiceBox.get(newId)!);
      } else {
        invoiceList.add(invoiceBox.get(existingInv.objectBoxId)!);
      }
    }

    fresh.invoices
      ..clear()
      ..addAll(invoiceList);

      // -------------------------------------------------------------
// 3️⃣ Sync InvoiceItems (ToMany) — snapshot first + link invoiceData ToOne
// -------------------------------------------------------------
final List<InvoiceItemsModel> syncedInvoiceItems = <InvoiceItemsModel>[];

// If d.invoiceItems is dynamic, make it explicit:
final List<InvoiceItemsModel> incomingInvoiceItems =
    d.invoiceItems.toList().cast<InvoiceItemsModel>();

// -------------------------------------------------------------
// ✅ Build invoice lookup from already-synced fresh.invoices
// -------------------------------------------------------------
final Map<String, InvoiceDataModel> invoiceByPbId = {};
final Map<String, InvoiceDataModel> invoiceById = {};

try {
  final invs = fresh.invoices.toList();
  for (final inv in invs) {
    final pb = (inv.pocketbaseId).trim();
    final id = (inv.id ?? '').toString().trim();
    if (pb.isNotEmpty) invoiceByPbId[pb] = inv;
    if (id.isNotEmpty) invoiceById[id] = inv;
  }
} catch (_) {}

debugPrint(
  '🧾 [INVOICE ITEMS] Incoming invoice items for delivery '
  'PB=$deliveryPbId → count=${incomingInvoiceItems.length}',
);
debugPrint(
  '🧾 [INVOICE ITEMS] Invoice lookup: '
  'byPbId=${invoiceByPbId.length}, byId=${invoiceById.length}',
);

for (final InvoiceItemsModel inv in incomingInvoiceItems) {
  final invPbId = (inv.pocketbaseId).trim();

  if (invPbId.isEmpty) {
    debugPrint('⚠️ [INVOICE ITEMS] Skipped item with EMPTY pocketbaseId');
    continue;
  }

  // -------------------------------------------------------------
  // ✅ Find the invoice ID from incoming item
  // Priority:
  // 1) inv.invoiceData.target?.pocketbaseId (if expanded)
  // 2) inv.invoiceDataId (raw string)
  // 3) inv.invoiceData.target?.id
  // -------------------------------------------------------------
  String incomingInvoicePbId = '';
  String incomingInvoiceId = '';

  try {
    incomingInvoicePbId = (inv.invoiceData.target?.id ?? '').trim();
  } catch (_) {}

  try {
    incomingInvoiceId = (inv.invoiceDataId ?? '').toString().trim();
  } catch (_) {}

  if (incomingInvoiceId.isEmpty) {
    try {
      incomingInvoiceId = (inv.invoiceData.target?.id ?? '').toString().trim();
    } catch (_) {}
  }

  debugPrint(
    '🔍 [INVOICE ITEMS] Processing item PB=$invPbId | name=${inv.name} '
    '| invPb=$incomingInvoicePbId | invId=$incomingInvoiceId',
  );

  // -------------------------------------------------------------
  // ✅ Resolve invoice locally using the maps
  // -------------------------------------------------------------
  InvoiceDataModel? resolvedInvoice;
  if (incomingInvoicePbId.isNotEmpty) {
    resolvedInvoice = invoiceByPbId[incomingInvoicePbId];
  }
  resolvedInvoice ??= invoiceById[incomingInvoiceId];

  if (resolvedInvoice == null &&
      (incomingInvoicePbId.isNotEmpty || incomingInvoiceId.isNotEmpty)) {
    debugPrint(
      '⚠️ [INVOICE ITEMS] No matching invoice found locally for item PB=$invPbId '
      '(invPb=$incomingInvoicePbId, invId=$incomingInvoiceId)',
    );
  }

  // -------------------------------------------------------------
  // ✅ Find existing local InvoiceItem by pocketbaseId
  // -------------------------------------------------------------
  final q = invoiceItemsBox
      .query(InvoiceItemsModel_.pocketbaseId.equals(invPbId))
      .build();
  final existingInv = q.findFirst();
  q.close();

  InvoiceItemsModel localItem;

  if (existingInv == null) {
    debugPrint('🆕 [INVOICE ITEMS] Creating new item → PB=$invPbId');

    final newInv = InvoiceItemsModel()
      ..id = inv.id
      ..pocketbaseId = invPbId
      ..name = inv.name
      ..brand = inv.brand
      ..refId = inv.refId
      ..uom = inv.uom
      ..quantity = inv.quantity
      ..uomPrice = inv.uomPrice
      ..totalAmount = inv.totalAmount
      ..totalBaseQuantity = inv.totalBaseQuantity
      ..created = inv.created
      ..updated = inv.updated;

    // ✅ LINK invoiceData ToOne + raw field
    if (resolvedInvoice != null) {
      newInv.invoiceData.target = resolvedInvoice;
      newInv.invoiceDataId = (resolvedInvoice.id ?? '').toString();
      debugPrint(
        '🔗 [INVOICE ITEMS] Linked NEW item → invoiceData '
        'pb=${resolvedInvoice.pocketbaseId} id=${resolvedInvoice.id}',
      );
    } else {
      // still store the raw invoiceDataId if present, for future re-link
      if (incomingInvoiceId.isNotEmpty) {
        newInv.invoiceDataId = incomingInvoiceId;
        debugPrint(
          '🧷 [INVOICE ITEMS] NEW item saved with raw invoiceDataId=$incomingInvoiceId (no ToOne link yet)',
        );
      }
    }

    final newObxId = invoiceItemsBox.put(newInv);
    localItem = invoiceItemsBox.get(newObxId)!;
    syncedInvoiceItems.add(localItem);

    debugPrint('✅ [INVOICE ITEMS] Saved new item PB=$invPbId → OBX=$newObxId');
  } else {
    debugPrint(
      '♻️ [INVOICE ITEMS] Existing item found PB=$invPbId → OBX=${existingInv.objectBoxId}',
    );

    // ✅ Load the persisted instance and update fields
    localItem = invoiceItemsBox.get(existingInv.objectBoxId)!;

    localItem
      ..id = inv.id
      ..name = inv.name
      ..brand = inv.brand
      ..refId = inv.refId
      ..uom = inv.uom
      ..quantity = inv.quantity
      ..uomPrice = inv.uomPrice
      ..totalAmount = inv.totalAmount
      ..totalBaseQuantity = inv.totalBaseQuantity
      ..created = inv.created
      ..updated = inv.updated;

    // ✅ Ensure invoice relation is linked
    if (resolvedInvoice != null) {
      localItem.invoiceData.target = resolvedInvoice;
      localItem.invoiceDataId = (resolvedInvoice.id ?? '').toString();

      debugPrint(
        '🔗 [INVOICE ITEMS] Linked EXISTING item → invoiceData '
        'pb=${resolvedInvoice.pocketbaseId} id=${resolvedInvoice.id}',
      );
    } else {
      // keep raw if we have it
      if ((localItem.invoiceDataId ?? '').trim().isEmpty &&
          incomingInvoiceId.isNotEmpty) {
        localItem.invoiceDataId = incomingInvoiceId;
        debugPrint(
          '🧷 [INVOICE ITEMS] EXISTING item stored raw invoiceDataId=$incomingInvoiceId (no ToOne link yet)',
        );
      }
    }

    // ✅ Persist changes
    invoiceItemsBox.put(localItem);
    syncedInvoiceItems.add(localItem);
  }
}

// BEFORE attach
debugPrint(
  '📦 [INVOICE ITEMS] Attaching ${syncedInvoiceItems.length} items '
  'to DeliveryData PB=$deliveryPbId (previous=${fresh.invoiceItems.length})',
);

// Attach to delivery
fresh.invoiceItems
  ..clear()
  ..addAll(syncedInvoiceItems);

// IMPORTANT: persist parent (depending on your overall flow)
deliveryDataBox.put(fresh);

// AFTER attach
debugPrint(
  '✅ [INVOICE ITEMS] DeliveryData PB=$deliveryPbId now has '
  '${fresh.invoiceItems.length} invoice items',
);

// -------------------------------------------------------------
// ✅ Debug: verify invoice links on first few items
// -------------------------------------------------------------
for (int i = 0; i < fresh.invoiceItems.length && i < 5; i++) {
  final it = fresh.invoiceItems[i];
  debugPrint(
    '🧾 [VERIFY] Item ${i + 1}: ${it.name} '
    '| itemPB=${it.pocketbaseId} '
    '| invTarget=${it.invoiceData.target?.id} '
    '| invPB=${it.invoiceData.target?.id} '
    '| invRaw=${it.invoiceDataId}',
  );
}


    // -------------------------------------------------------------
    // 4️⃣ Sync DeliveryUpdates (ToMany) — snapshot first
    // -------------------------------------------------------------
    final updatesList = <DeliveryUpdateModel>[];
    final incomingUpdates = d.deliveryUpdates.toList();

    // ✅ Cleanup by deliveryDataPbId (this is what forceReload uses)
    try {
      final cleanupQuery =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.deliveryDataPbId.equals(deliveryPbId))
              .build();

      final existingForDelivery = cleanupQuery.find();
      cleanupQuery.close();

      if (existingForDelivery.isNotEmpty) {
        deliveryUpdateBox.removeMany(
          existingForDelivery.map((e) => e.objectBoxId).toList(),
        );

        debugPrint(
          '🧹 Removed ${existingForDelivery.length} existing DeliveryUpdates for delivery PB:$deliveryPbId',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to cleanup DeliveryUpdates for $deliveryPbId: $e');
    }

    for (final up in incomingUpdates) {
      final upId = (up.id ?? '').trim();
      if (upId.isEmpty) {
        debugPrint('⚠️ Skipping DeliveryUpdate: missing update id');
        continue;
      }

      debugPrint(
        "🕒 PB update → id=$upId, title=${up.title}, time=${up.time}, created=${up.created}",
      );

      final existingUp =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.id.equals(upId))
              .build()
              .findFirst();

      final model = existingUp != null
          ? deliveryUpdateBox.get(existingUp.objectBoxId)!
          : (DeliveryUpdateModel()..id = upId);

      // ✅ CRITICAL for forceReloadDeliveryUpdatesByTripId queries
      model.deliveryDataPbId = deliveryPbId;

      model
        ..title = up.title
        ..subtitle = up.subtitle
        ..time = up.time
        ..created = up.created
        ..updated = up.updated
        ..lastLocalUpdatedAt = up.lastLocalUpdatedAt;

      final savedObxId = deliveryUpdateBox.put(model);
      updatesList.add(deliveryUpdateBox.get(savedObxId)!);

      debugPrint(
        "✅ Saved DeliveryUpdate → id=$upId, deliveryPB=$deliveryPbId, obx=$savedObxId",
      );
    }

    fresh.deliveryUpdates
      ..clear()
      ..addAll(updatesList);

    // -------------------------------------------------------------
    // 5️⃣ Save DeliveryData
    // -------------------------------------------------------------
    final obxId = deliveryDataBox.put(fresh);
    uniqueDeliveries[deliveryPbId] = deliveryDataBox.get(obxId)!;

    debugPrint(
      '🔁 DeliveryData synced → ${fresh.ownerName} OBX: $obxId '
      'Invoices: ${fresh.invoices.length}, Updates: ${fresh.deliveryUpdates.length}',
    );
  }

  // ✅ IMPORTANT: Update Trip relation ONLY AFTER LOOP (prevents concurrent modification)
  trip.deliveryData
    ..clear()
    ..addAll(uniqueDeliveries.values);

  tripBox.put(trip);

  debugPrint(
    '🟦 Trip saved → ${trip.name} with ${trip.deliveryData.length} delivery items',
  );
}


  Future<void> _syncEndTripChecklistForTrip(TripModel trip) async {
    final Map<String, EndTripChecklistModel> uniqueChecklist = {};

    for (final e in trip.endTripChecklist) {
      debugPrint(
        '📋 Syncing End Trip Checklist → Trip: ${trip.name}, PB: ${e.pocketbaseId}, Item: ${e.objectName}',
      );

      // -------------------------------------------------------------
      // 1️⃣ Load existing or create new checklist
      // -------------------------------------------------------------
      EndTripChecklistModel fresh;

      final existing =
          endTripChecklistBox
              .query(EndTripChecklistModel_.pocketbaseId.equals(e.pocketbaseId))
              .build()
              .findFirst();

      if (existing != null) {
        fresh = endTripChecklistBox.get(existing.dbId)!;
        debugPrint('🔁 Existing checklist found → OBX: ${fresh.dbId}');
      } else {
        fresh =
            EndTripChecklistModel()
              ..id = e.id
              ..pocketbaseId = e.pocketbaseId;
        debugPrint('🆕 Creating new end trip checklist locally');
      }

      // -------------------------------------------------------------
      // 2️⃣ Copy fields
      // -------------------------------------------------------------
      fresh.objectName = e.objectName;
      fresh.description = e.description;
      fresh.status = e.status;
      fresh.isChecked = e.isChecked;
      fresh.timeCompleted = e.timeCompleted;

      // -------------------------------------------------------------
      // 3️⃣ Sync Trip relation
      // -------------------------------------------------------------
      if (e.tripModel != null) {
        final remoteTrip = e.tripModel!;

        final tripQuery =
            tripBox
                .query(
                  TripModel_.pocketbaseId.equals(remoteTrip.pocketbaseId ?? ''),
                )
                .build();
        final existingTrip = tripQuery.findFirst();
        tripQuery.close();

        if (existingTrip == null) {
          final newTrip =
              TripModel()
                ..id = remoteTrip.id
                ..pocketbaseId = remoteTrip.pocketbaseId
                ..name = remoteTrip.name;

          final newTripId = tripBox.put(newTrip);
          fresh.tripModel = tripBox.get(newTripId);

          debugPrint('✅ Trip created & linked → ${newTrip.name}');
        } else {
          fresh.tripModel = tripBox.get(existingTrip.objectBoxId);
          debugPrint('ℹ️ Trip linked → ${existingTrip.name}');
        }
      } else {
        fresh.tripModel = null;
        debugPrint('⚠️ Checklist has no linked trip');
      }

      // -------------------------------------------------------------
      // 4️⃣ Save checklist
      // -------------------------------------------------------------
      final obxId = endTripChecklistBox.put(fresh);
      uniqueChecklist[fresh.pocketbaseId] = endTripChecklistBox.get(obxId)!;

      debugPrint('✅ End checklist synced → ${fresh.objectName} (OBX: $obxId)');
    }

    // -------------------------------------------------------------
    // 5️⃣ Assign checklist to trip & save
    // -------------------------------------------------------------
    trip.endTripChecklist
      ..clear()
      ..addAll(uniqueChecklist.values);
    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → ${trip.name} with ${trip.endTripChecklist.length} end checklist items',
    );
  }

  Future<void> _syncCollectionsForTrip(TripModel trip) async {
    final Map<String, CollectionModel> uniqueCollections = {};

    debugPrint('🔁 Syncing collections for trip → ${trip.name}');

    for (final c in trip.deliveryCollection) {
      debugPrint(
        '📦 Syncing Collection → ${c.collectionName} PB: ${c.pocketbaseId}',
      );

      // ------------------------------------------------------------
      // LOAD OR CREATE COLLECTION
      // ------------------------------------------------------------
      CollectionModel fresh;

      final existing =
          deliveryCollectonBox
              .query(CollectionModel_.pocketbaseId.equals(c.pocketbaseId))
              .build()
              .findFirst();

      if (existing != null) {
        fresh = deliveryCollectonBox.get(existing.objectBoxId)!;
      } else {
        fresh =
            CollectionModel()
              ..id = c.id
              ..pocketbaseId = c.pocketbaseId
              ..collectionId = c.collectionId
              ..collectionName = c.collectionName
              ..totalAmount = c.totalAmount
              ..created = c.created
              ..updated = c.updated
              ..tripId = trip.id
              ..syncStatus = SyncStatus.synced.name;
      }

      // ------------------------------------------------------------
      // SYNC CUSTOMER
      // ------------------------------------------------------------
      if (c.customer.target != null) {
        final cust = c.customer.target!;

        final existingCust =
            customerBox
                .query(
                  CustomerDataModel_.pocketbaseId.equals(cust.pocketbaseId),
                )
                .build()
                .findFirst();

        if (existingCust == null) {
          final newCust =
              CustomerDataModel()
                ..id = cust.id
                ..pocketbaseId = cust.pocketbaseId
                ..name = cust.name
                ..province = cust.province
                ..municipality = cust.municipality
                ..barangay = cust.barangay;

          final newId = customerBox.put(newCust);
          fresh.customer.target = customerBox.get(newId);
        } else {
          fresh.customer.target = customerBox.get(existingCust.objectBoxId);
        }

        fresh.customerId = cust.id;
      } else {
        fresh.customer.target = null;
        fresh.customerId = null;
      }

      // ------------------------------------------------------------
      // SYNC DELIVERY DATA
      // ------------------------------------------------------------
      if (c.deliveryData.target != null) {
        final d = c.deliveryData.target!;

        final existingDelivery =
            deliveryDataBox
                .query(DeliveryDataModel_.pocketbaseId.equals(d.pocketbaseId))
                .build()
                .findFirst();

        if (existingDelivery != null) {
          fresh.deliveryData.target = deliveryDataBox.get(
            existingDelivery.objectBoxId,
          );
          fresh.deliveryDataId = d.id;
        } else {
          debugPrint(
            '⚠️ DeliveryData not found locally for PB: ${d.pocketbaseId}',
          );
          fresh.deliveryData.target = null;
          fresh.deliveryDataId = null;
        }
      }

      // ------------------------------------------------------------
      // SYNC TRIP
      // ------------------------------------------------------------
      fresh.trip.target = trip;
      fresh.tripId = trip.id;

      // ------------------------------------------------------------
      // SYNC INVOICES (CLEAR + REATTACH)
      // ------------------------------------------------------------
      final invoiceList = <InvoiceDataModel>[];

      for (final inv in c.invoices) {
        final existingInv =
            invoiceBox
                .query(InvoiceDataModel_.pocketbaseId.equals(inv.pocketbaseId))
                .build()
                .findFirst();

        if (existingInv == null) {
          final newInv =
              InvoiceDataModel()
                ..id = inv.id
                ..pocketbaseId = inv.pocketbaseId
                ..name = inv.name
                ..totalAmount = inv.totalAmount;

          final newId = invoiceBox.put(newInv);
          invoiceList.add(invoiceBox.get(newId)!);
        } else {
          invoiceList.add(invoiceBox.get(existingInv.objectBoxId)!);
        }
      }

      fresh.invoices
        ..clear()
        ..addAll(invoiceList);

      // ------------------------------------------------------------
      // SYNC DELIVERY RECEIPT (OPTIONAL)
      // ------------------------------------------------------------
      if (c.deliveryReceipt.target != null) {
        final receipt = c.deliveryReceipt.target!;

        final existingReceipt =
            deliveryReceiptBox
                .query(
                  DeliveryReceiptModel_.pocketbaseId.equals(
                    receipt.pocketbaseId,
                  ),
                )
                .build()
                .findFirst();

        if (existingReceipt == null) {
          final newReceipt =
              DeliveryReceiptModel()
                ..id = receipt.id
                ..pocketbaseId = receipt.pocketbaseId
                ..customerImagesString = receipt.customerImagesString
                ..created = receipt.created;

          final newId = deliveryReceiptBox.put(newReceipt);
          fresh.deliveryReceipt.target = deliveryReceiptBox.get(newId);
        } else {
          fresh.deliveryReceipt.target = deliveryReceiptBox.get(
            existingReceipt.objectBoxId,
          );
        }
      } else {
        fresh.deliveryReceipt.target = null;
      }

      // ------------------------------------------------------------
      // SAVE COLLECTION
      // ------------------------------------------------------------
      final obxId = deliveryCollectonBox.put(fresh);
      uniqueCollections[fresh.pocketbaseId] = deliveryCollectonBox.get(obxId)!;

      debugPrint(
        '✅ Collection synced → ${fresh.collectionName} OBX:$obxId '
        'Invoices:${fresh.invoices.length}',
      );
    }

    // ------------------------------------------------------------
    // ATTACH COLLECTIONS TO TRIP
    // ------------------------------------------------------------
    trip.deliveryCollection
      ..clear()
      ..addAll(uniqueCollections.values);

    tripBox.put(trip);

    debugPrint(
      '🟦 Trip saved → ${trip.name} with ${trip.deliveryCollection.length} collections',
    );
  }

  Future<void> _syncCancelledInvoicesForTrip(TripModel trip) async {
    debugPrint('🔁 Syncing CancelledInvoices for trip → ${trip.name}');

    final Map<String, CancelledInvoiceModel> uniqueCancelled = {};

    for (final ci in trip.cancelledInvoices) {
      debugPrint(
        '🚫 Syncing CancelledInvoice → PB:${ci.id} reason=${ci.reason}',
      );

      // ---------------------------------------------------------
      // 1️⃣ Load existing or create new CancelledInvoice
      // ---------------------------------------------------------
      CancelledInvoiceModel fresh;

      final existingQuery =
          cancelledInvoiceBox
              .query(
                CancelledInvoiceModel_.pocketbaseId.equals(ci.pocketbaseId),
              )
              .build();
      final existing = existingQuery.findFirst();
      existingQuery.close();

      if (existing != null) {
        fresh = cancelledInvoiceBox.get(existing.objectBoxId)!;
      } else {
        fresh =
            CancelledInvoiceModel()
              ..id = ci.id
              ..pocketbaseId = ci.pocketbaseId
              ..collectionId = ci.collectionId
              ..collectionName = ci.collectionName
              ..reason = ci.reason
              ..image = ci.image
              ..created = ci.created
              ..updated = ci.updated
              ..tripId = trip.id;
      }

      // ---------------------------------------------------------
      // 2️⃣ Sync DeliveryData (ToOne)
      // ---------------------------------------------------------
      if (ci.deliveryData.target != null) {
        final dd = ci.deliveryData.target!;
        final ddQuery =
            deliveryDataBox
                .query(DeliveryDataModel_.pocketbaseId.equals(dd.pocketbaseId))
                .build();
        final existingDD = ddQuery.findFirst();
        ddQuery.close();

        if (existingDD != null) {
          fresh.deliveryData.target = deliveryDataBox.get(
            existingDD.objectBoxId,
          );
        } else {
          final newDD =
              DeliveryDataModel()
                ..id = dd.id
                ..pocketbaseId = dd.pocketbaseId
                ..ownerName = dd.ownerName
                ..deliveryNumber = dd.deliveryNumber
                ..storeName = dd.storeName
                ..province = dd.province
                ..municipality = dd.municipality
                ..barangay = dd.barangay
                ..paymentMode = dd.paymentMode
                ..tripId = trip.id;

          final newId = deliveryDataBox.put(newDD);
          fresh.deliveryData.target = deliveryDataBox.get(newId);
        }
      } else {
        fresh.deliveryData.target = null;
      }

      // ---------------------------------------------------------
      // 3️⃣ Sync Trip (ToOne)
      // ---------------------------------------------------------
      final tripQuery =
          tripBox
              .query(TripModel_.pocketbaseId.equals(trip.pocketbaseId ?? ''))
              .build();
      final existingTrip = tripQuery.findFirst();
      tripQuery.close();

      if (existingTrip != null) {
        fresh.trip.target = tripBox.get(existingTrip.objectBoxId);
      } else {
        final newTrip =
            TripModel()
              ..id = trip.id
              ..pocketbaseId = trip.pocketbaseId
              ..name = trip.name;
        final newId = tripBox.put(newTrip);
        fresh.trip.target = tripBox.get(newId);
      }

      // ---------------------------------------------------------
      // 4️⃣ Sync Customer (ToOne)
      // ---------------------------------------------------------
      if (ci.customer.target != null) {
        final cust = ci.customer.target!;
        final custQuery =
            customerBox
                .query(
                  CustomerDataModel_.pocketbaseId.equals(cust.pocketbaseId),
                )
                .build();
        final existingCust = custQuery.findFirst();
        custQuery.close();

        if (existingCust != null) {
          fresh.customer.target = customerBox.get(existingCust.objectBoxId);
        } else {
          final newCust =
              CustomerDataModel()
                ..id = cust.id
                ..pocketbaseId = cust.pocketbaseId
                ..name = cust.name
                ..province = cust.province
                ..municipality = cust.municipality
                ..barangay = cust.barangay;

          final newId = customerBox.put(newCust);
          fresh.customer.target = customerBox.get(newId);
        }
      } else {
        fresh.customer.target = null;
      }

      // ---------------------------------------------------------
      // 5️⃣ Sync Primary Invoice (ToOne)
      // ---------------------------------------------------------
      if (ci.invoice.target != null) {
        final inv = ci.invoice.target!;
        final invQuery =
            invoiceBox
                .query(InvoiceDataModel_.pocketbaseId.equals(inv.pocketbaseId))
                .build();
        final existingInv = invQuery.findFirst();
        invQuery.close();

        if (existingInv != null) {
          fresh.invoice.target = invoiceBox.get(existingInv.objectBoxId);
        } else {
          final newInv =
              InvoiceDataModel()
                ..id = inv.id
                ..pocketbaseId = inv.pocketbaseId
                ..name = inv.name
                ..totalAmount = inv.totalAmount;

          final newId = invoiceBox.put(newInv);
          fresh.invoice.target = invoiceBox.get(newId);
        }
      } else {
        fresh.invoice.target = null;
      }

      // ---------------------------------------------------------
      // 6️⃣ Sync Invoices (ToMany)
      // ---------------------------------------------------------
      final invoiceList = <InvoiceDataModel>[];

      for (final inv in ci.invoices) {
        final invQuery =
            invoiceBox
                .query(InvoiceDataModel_.pocketbaseId.equals(inv.pocketbaseId))
                .build();
        final existingInv = invQuery.findFirst();
        invQuery.close();

        if (existingInv != null) {
          invoiceList.add(invoiceBox.get(existingInv.objectBoxId)!);
        } else {
          final newInv =
              InvoiceDataModel()
                ..id = inv.id
                ..pocketbaseId = inv.pocketbaseId
                ..name = inv.name
                ..totalAmount = inv.totalAmount;

          final newId = invoiceBox.put(newInv);
          invoiceList.add(invoiceBox.get(newId)!);
        }
      }

      fresh.invoices
        ..clear()
        ..addAll(invoiceList);

      // ---------------------------------------------------------
      // 7️⃣ Save CancelledInvoice
      // ---------------------------------------------------------
      final obxId = cancelledInvoiceBox.put(fresh);
      uniqueCancelled[fresh.id ?? ''] = cancelledInvoiceBox.get(obxId)!;

      debugPrint(
        '✅ CancelledInvoice synced → OBX:$obxId reason=${fresh.reason}, id =${fresh.pocketbaseId}',
      );
    }

    // ---------------------------------------------------------
    // 8️⃣ Attach to Trip & Save
    // ---------------------------------------------------------
    trip.cancelledInvoices
      ..clear()
      ..addAll(uniqueCancelled.values);

    tripBox.put(trip);

    debugPrint(
      '🟦 Trip updated → ${trip.name} with ${trip.cancelledInvoices.length} cancelled invoices',
    );
  }

  // / 🧹 Clean Personnel table:
  // /    1. Remove items with NULL/EMPTY pocketbaseId
  // /    2. Remove duplicates using pocketbaseId
  Future<void> _cleanPersonnel() async {
    try {
      final allPersonnel = personnelBox.getAll();

      final seen = <String, PersonelModel>{};

      for (var p in allPersonnel) {
        final pbId = p.pocketbaseId.trim();

        // 🔴 Step 1 — Remove personnel with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL Personnel → '
            'Name: ${p.name}, OBX: ${p.objectBoxId}',
          );
          personnelBox.remove(p.objectBoxId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate personnel
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate Personnel → Removing ${p.name} '
            '(PB: $pbId, OBX: ${p.objectBoxId})',
          );
          personnelBox.remove(p.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = p;
      }

      debugPrint(
        '🟢 Personnel cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e) {
      debugPrint('❌ _cleanPersonnel error: $e');
    }
  }

  /// 🧹 Clean CancelledInvoice table:
  /// 1️⃣ Remove items with NULL / EMPTY PocketBase ID (id)
  /// 2️⃣ Remove duplicates using PocketBase ID
  Future<void> _cleanCancelledInvoices() async {
    try {
      debugPrint('🧹 Starting CancelledInvoice cleanup');

      final allCancelled = cancelledInvoiceBox.getAll();

      final seen = <String, CancelledInvoiceModel>{};

      for (final ci in allCancelled) {
        final pbId = (ci.id ?? '').trim();

        // -------------------------------------------------
        // 🔴 Step 1 — Remove invalid (no PB ID)
        // -------------------------------------------------
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing INVALID CancelledInvoice → '
            'Reason: ${ci.reason}, OBX: ${ci.objectBoxId}',
          );
          cancelledInvoiceBox.remove(ci.objectBoxId);
          continue;
        }

        // -------------------------------------------------
        // 🔁 Step 2 — Remove duplicates
        // -------------------------------------------------
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate CancelledInvoice → Removing '
            'PB: $pbId (OBX: ${ci.objectBoxId})',
          );
          cancelledInvoiceBox.remove(ci.objectBoxId);
          continue;
        }

        // -------------------------------------------------
        // ✅ First valid occurrence
        // -------------------------------------------------
        seen[pbId] = ci;
      }

      debugPrint(
        '🟢 CancelledInvoice cleanup complete — '
        '${allCancelled.length - seen.length} invalid/duplicate records removed.',
      );
    } catch (e, st) {
      debugPrint('❌ _cleanCancelledInvoices error: $e\n$st');
    }
  }

  /// 🧹 Clean TripUpdate table:
  /// 1️⃣ Remove items with NULL/EMPTY pocketbaseId
  /// 2️⃣ Remove duplicates using pocketbaseId
  Future<void> _cleanTripUpdates() async {
    try {
      final allUpdates = tripUpdateBox.getAll();

      final seen = <String, TripUpdateModel>{};

      for (var u in allUpdates) {
        final pbId = u.pocketbaseId.trim();

        // 🔴 Step 1 — Remove TripUpdate with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL TripUpdate → '
            'Status: ${u.status}, OBX: ${u.objectBoxId}',
          );
          tripUpdateBox.remove(u.objectBoxId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate TripUpdates
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate TripUpdate → Removing PB: $pbId '
            '(OBX: ${u.objectBoxId})',
          );
          tripUpdateBox.remove(u.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = u;
      }

      debugPrint(
        '🟢 TripUpdate cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e) {
      debugPrint('❌ _cleanTripUpdates error: $e');
    }
  }

  /// 🧹 Clean DeliveryTeam table:
  ///    1. Remove items with NULL/EMPTY pocketbaseId
  ///    2. Remove duplicates using pocketbaseId
  Future<void> _cleanDeliveryTeam() async {
    try {
      final allTeams = deliveryTeamBox.getAll();

      final seen = <String, DeliveryTeamModel>{};

      for (var team in allTeams) {
        final pbId = team.pocketbaseId.trim();

        // 🔴 Step 1 — Remove team with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL DeliveryTeam → '
            'Name: ${team.id}, OBX: ${team.objectBoxId}',
          );
          deliveryTeamBox.remove(team.objectBoxId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate teams
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate DeliveryTeam → Removing ${team.id} '
            '(PB: $pbId, OBX: ${team.objectBoxId})',
          );
          deliveryTeamBox.remove(team.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = team;
      }

      debugPrint(
        '🟢 DeliveryTeam cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e) {
      debugPrint('❌ _cleanDeliveryTeam error: $e');
    }
  }

  /// 🧹 Clean InTransit OTP table:
  ///    1. Remove items with NULL/EMPTY PB ID
  ///    2. Remove duplicates using PB ID
  Future<void> _cleanInTransitOtp() async {
    try {
      final allOtps = otpBox.getAll();

      final seen = <String, OtpModel>{};

      for (final otp in allOtps) {
        final pbId = otp.id.trim();

        // 🔴 Step 1 — Remove OTP with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL InTransit OTP → '
            'OBX: ${otp.dbId}, Code: ${otp.otpCode}',
          );
          otpBox.remove(otp.dbId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate OTPs
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate InTransit OTP → Removing '
            '(PB: $pbId, OBX: ${otp.dbId})',
          );
          otpBox.remove(otp.dbId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = otp;
      }

      debugPrint(
        '🟢 InTransit OTP cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e, st) {
      debugPrint('❌ _cleanInTransitOtp ERROR: $e\n$st');
    }
  }

  /// 🧹 Clean EndTrip OTP table:
  ///    1. Remove items with NULL/EMPTY PB ID
  ///    2. Remove duplicates using PB ID
  Future<void> _cleanEndTripOtp() async {
    try {
      final allOtps = endTripOtpBox.getAll();

      final seen = <String, EndTripOtpModel>{};

      for (final otp in allOtps) {
        final pbId = otp.id.trim();

        // 🔴 Step 1 — Remove OTP with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL EndTrip OTP → '
            'OBX: ${otp.dbId}, Code: ${otp.otpCode}',
          );
          endTripOtpBox.remove(otp.dbId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate OTPs
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate EndTrip OTP → Removing '
            '(PB: $pbId, OBX: ${otp.dbId})',
          );
          endTripOtpBox.remove(otp.dbId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = otp;
      }

      debugPrint(
        '🟢 EndTrip OTP cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e, st) {
      debugPrint('❌ _cleanEndTripOtp ERROR: $e\n$st');
    }
  }

  Future<void> _cleanDeliveryData() async {
    try {
      final allData = deliveryDataBox.getAll();

      final seen = <String, DeliveryDataModel>{};

      for (var d in allData) {
        final pbId = d.pocketbaseId.trim();

        // 🔴 Step 1 — Remove Delivery Data with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL DeliveryData → '
            'OBX: ${d.objectBoxId}, Customer: ${d.ownerName}, ID: ${d.id} PB: ${d.pocketbaseId}',
          );
          deliveryDataBox.removeAll();
          continue;
        }

        // 🔁 Step 2 — Remove duplicate Delivery Data
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate DeliveryData → Removing OBX: ${d.objectBoxId} '
            '(PB: $pbId, Customer: ${d.ownerName})',
          );
          deliveryDataBox.removeAll();
          continue;
        }

        // First valid occurrence
        seen[pbId] = d;
      }

      debugPrint(
        '🟢 DeliveryData cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e) {
      debugPrint('❌ _cleanDeliveryData error: $e');
    }
  }

  Future<void> _cleanEndTripChecklist() async {
    try {
      final allChecklist = endTripChecklistBox.getAll();

      final seen = <String, EndTripChecklistModel>{};

      for (var e in allChecklist) {
        final pbId = e.pocketbaseId.trim();

        // 🔴 Step 1 — Remove checklist with no PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL EndTripChecklist → '
            'OBX: ${e.dbId}, Item: ${e.objectName}, ID: ${e.id}, PB: ${e.pocketbaseId}',
          );
          endTripChecklistBox.remove(e.dbId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate checklist by PB ID
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate EndTripChecklist → Removing OBX: ${e.dbId} '
            '(PB: $pbId, Item: ${e.objectName})',
          );
          endTripChecklistBox.remove(e.dbId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = e;
      }

      debugPrint(
        '🟢 EndTripChecklist cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e, st) {
      debugPrint('❌ _cleanEndTripChecklist error: $e\n$st');
    }
  }

  Future<void> _cleanDeliveryCollections() async {
    try {
      final allCollections = deliveryCollectonBox.getAll();

      debugPrint(
        '🧹 COLLECTION CLEANUP: Starting with ${allCollections.length} records',
      );

      final Map<String, CollectionModel> seen = {};
      final List<int> idsToRemove = [];

      for (final c in allCollections) {
        final pbId = c.pocketbaseId.trim();

        // ------------------------------------------------------------
        // STEP 1 — REMOVE COLLECTIONS WITH NO PB ID
        // ------------------------------------------------------------
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing Collection with EMPTY PB ID → '
            'OBX:${c.objectBoxId}, '
            'CollectionId:${c.collectionId}, '
            'Name:${c.collectionName}',
          );

          _detachCollectionRelations(c);
          idsToRemove.add(c.objectBoxId);
          continue;
        }

        // ------------------------------------------------------------
        // STEP 2 — REMOVE DUPLICATES (PB ID BASED)
        // ------------------------------------------------------------
        if (seen.containsKey(pbId)) {
          final kept = seen[pbId]!;

          debugPrint(
            '⚠️ Duplicate Collection detected → '
            'REMOVING OBX:${c.objectBoxId}, '
            'KEEPING OBX:${kept.objectBoxId}, '
            'PB:$pbId',
          );

          _detachCollectionRelations(c);
          idsToRemove.add(c.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = c;
      }

      // ------------------------------------------------------------
      // EXECUTE REMOVALS
      // ------------------------------------------------------------
      if (idsToRemove.isNotEmpty) {
        deliveryCollectonBox.removeMany(idsToRemove);
        debugPrint(
          '🗑️ COLLECTION CLEANUP: Removed ${idsToRemove.length} records',
        );
      } else {
        debugPrint('🟢 COLLECTION CLEANUP: No duplicates found');
      }

      debugPrint(
        '✅ COLLECTION CLEANUP COMPLETE — '
        'Remaining unique collections: ${seen.length}',
      );
    } catch (e, st) {
      debugPrint('❌ _cleanDeliveryCollections error: $e');
      debugPrint(st.toString());
    }
  }

  void _detachCollectionRelations(CollectionModel c) {
    try {
      c.customer.target = null;
      c.deliveryData.target = null;
      c.trip.target = null;
      c.deliveryReceipt.target = null;
      c.invoices.clear();
    } catch (e) {
      debugPrint(
        '⚠️ Failed to detach relations for Collection OBX:${c.objectBoxId} → $e',
      );
    }
  }

  Future<void> _cleanChecklistData() async {
    try {
      final allChecklist = checklistBox.getAll();

      final seen = <String, ChecklistModel>{};

      for (final c in allChecklist) {
        final pbId = c.pocketbaseId.trim();

        // 🔴 Step 1 — Remove checklist with NULL / empty PB ID
        if (pbId.isEmpty) {
          debugPrint(
            '🗑️ Removing NULL Checklist → '
            'OBX: ${c.objectBoxId}, Name: ${c.objectName}',
          );
          checklistBox.remove(c.objectBoxId);
          continue;
        }

        // 🔁 Step 2 — Remove duplicate checklist (same PB ID)
        if (seen.containsKey(pbId)) {
          debugPrint(
            '⚠️ Duplicate Checklist → Removing OBX: ${c.objectBoxId} '
            '(PB: $pbId, Name: ${c.objectName})',
          );
          checklistBox.remove(c.objectBoxId);
          continue;
        }

        // First valid occurrence
        seen[pbId] = c;
      }

      debugPrint(
        '🟢 Checklist cleanup complete — duplicates & null PB IDs removed.',
      );
    } catch (e) {
      debugPrint('❌ _cleanChecklistData error: $e');
    }
  }
}
