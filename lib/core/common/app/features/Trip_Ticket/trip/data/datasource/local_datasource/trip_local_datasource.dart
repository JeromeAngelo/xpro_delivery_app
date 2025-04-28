import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/data/model/vehicle_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/data/model/trip_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_otp/data/model/end_trip_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/otp/data/models/otp_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/src/auth/data/models/auth_models.dart';

import '../../../../../end_trip_checklist/data/model/end_trip_checklist_model.dart';
import '../../../../completed_customer/data/models/completed_customer_model.dart';
import '../../../../return_product/data/model/return_model.dart';
import '../../../../transaction/data/model/transaction_model.dart';
import '../../../../undeliverable_customer/data/model/undeliverable_customer_model.dart';

abstract class TripLocalDatasource {
  Future<TripModel> loadTrip();
  Future<TripModel> searchTripByNumber(String tripNumberId);
  Future<(TripModel, String)> acceptTrip(String tripId);
  Future<void> saveTrip(TripModel trip);
  Future<void> autoSaveTrip(TripModel trip);
  Future<void> saveCustomers(List<CustomerModel> customers);
  Future<void> saveDeliveryTeam(DeliveryTeamModel deliveryTeam);
  Future<void> savePersonnel(List<PersonelModel> personnel);
  Future<void> saveVehicles(List<VehicleModel> vehicles);
  Future<String> calculateTotalTripDistance(String tripId);
  Future<void> saveChecklist(List<ChecklistModel> checklist);
  Future<String?> getTrackingId();
  Future<bool> checkEndTripOtpStatus(String tripId);
  Future<TripModel> getTripById(String id);
  Future<void> endTrip();
}

class TripLocalDatasourceImpl implements TripLocalDatasource {
  final Store _store;
  final Box<TripModel> _tripBox;
  final PocketBase _pocketBaseClient;
  TripModel? _cachedTrip;
  String? _trackingId;

  TripLocalDatasourceImpl(
    this._store,
    this._tripBox,
    this._pocketBaseClient,
  );

  @override
  Future<TripModel> loadTrip() async {
    debugPrint('📱 Attempting to load trip from local storage');

    if (_cachedTrip != null) {
      debugPrint('📦 Returning cached trip: ${_cachedTrip!.tripNumberId}');
      return _cachedTrip!;
    }

    final trips = _tripBox.getAll();
    debugPrint('📊 Found ${trips.length} trips in local storage');

    if (trips.isEmpty) {
      throw const CacheException(message: 'No trips found in local storage');
    }

    _cachedTrip = trips.first;
    debugPrint('💾 Loaded trip: ${_cachedTrip!.tripNumberId}');
    return _cachedTrip!;
  }

  @override
  Future<TripModel> searchTripByNumber(String tripNumberId) async {
    debugPrint('🔍 Searching for trip: $tripNumberId');

    final trips =
        _tripBox.getAll().where((trip) => trip.tripNumberId == tripNumberId);

    if (trips.isEmpty) {
      debugPrint('❌ Trip not found: $tripNumberId');
      throw const CacheException(message: 'Trip not found in local storage');
    }

    debugPrint('✅ Found trip: ${trips.first.tripNumberId}');
    return trips.first;
  }

@override
Future<(TripModel, String)> acceptTrip(String inputTripId) async {
  debugPrint('🔄 Processing trip acceptance locally');

  // Get current user from local storage
  final prefs = await SharedPreferences.getInstance();
  final storedUserData = prefs.getString('user_data');

  if (storedUserData == null) {
    throw const CacheException(message: 'No stored user data found');
  }

  final userData = jsonDecode(storedUserData);
  final currentUser = LocalUsersModel.fromJson(userData);

  debugPrint('👤 Current user: ${currentUser.name}');

  // Generate checklist items
  final checklistItems = [
    ChecklistModel(
      objectName: 'Invoices',
      isChecked: false,
      status: 'pending',
      tripId: inputTripId,
    ),
    ChecklistModel(
      objectName: 'Pushcarts',
      isChecked: false,
      status: 'pending',
      tripId: inputTripId,
    ),
    ChecklistModel(
      objectName: 'Delivery Items',
      isChecked: false,
      status: 'pending',
      tripId: inputTripId,
    ),
  ];

  debugPrint('📝 Generating local checklist items');
  final checklistBox = _store.box<ChecklistModel>();
  final checklistIds = checklistBox.putMany(checklistItems);
  debugPrint('✅ Created ${checklistIds.length} checklist items locally');

  // Create accepted trip model with checklist
  final acceptedTrip = TripModel(
    id: inputTripId,
    collectionId: 'trips',
    collectionName: 'trips',
    customersList: const [],
    personelsList: const [],
    checklistItems: checklistItems,
    vehicleList: const [],
    created: DateTime.now(),
    updated: DateTime.now(),
    isAccepted: true,
    timeAccepted: DateTime.now(),
    objectBoxId: 1
  );

  // Store in local database
  final savedTripId = _tripBox.put(acceptedTrip);
  debugPrint('✅ Trip saved with ObjectBox ID: $savedTripId');

  // Link trip to current user
  final userBox = _store.box<LocalUsersModel>();
  currentUser.trip.target = acceptedTrip;
  currentUser.tripId = inputTripId;
  userBox.put(currentUser);

  // Update SharedPreferences
  final updatedUserData = {
    'id': currentUser.id,
    'collectionId': currentUser.collectionId,
    'collectionName': currentUser.collectionName,
    'email': currentUser.email,
    'name': currentUser.name,
    'tripNumberId': acceptedTrip.tripNumberId,
    'trip': {
      'id': acceptedTrip.id,
      'tripNumberId': acceptedTrip.tripNumberId
    },
    'tokenKey': currentUser.token
  };

  await prefs.setString('user_data', jsonEncode(updatedUserData));
  debugPrint('✅ Updated user data in SharedPreferences with new trip');

  _cachedTrip = acceptedTrip;
  return (acceptedTrip, _trackingId ?? '');
}


  @override
  Future<TripModel> getTripById(String id) async {
    debugPrint('📱 Loading trip from local storage by ID: $id');

    final trip =
        _tripBox.query(TripModel_.pocketbaseId.equals(id)).build().findFirst();

    if (trip == null) {
      debugPrint('❌ Trip not found in local storage: $id');
      throw const CacheException(message: 'Trip not found in local storage');
    }

    debugPrint('✅ Loaded trip: ${trip.tripNumberId}');
    return trip;
  }

  @override
  Future<void> saveTrip(TripModel trip) async {
    try {
      debugPrint('💾 LOCAL: Starting trip save');

      if (trip.deliveryTeam.target != null) {
        final deliveryTeamBox = _store.box<DeliveryTeamModel>();
        final deliveryTeam = trip.deliveryTeam.target!;
        deliveryTeam.tripId = trip.id;

        final deliveryTeamId = deliveryTeamBox.put(deliveryTeam);
        debugPrint('✅ LOCAL: Stored delivery team with ID: ${deliveryTeam.id}');
        debugPrint('📦 LOCAL: ObjectBox ID: $deliveryTeamId');
      }

      final tripId = _tripBox.put(trip);
      debugPrint('✅ LOCAL: Stored trip with ID: ${trip.id}');
      debugPrint('📦 LOCAL: ObjectBox ID: $tripId');

      // Verify storage
      final storedTrip = _tripBox.get(tripId);
      debugPrint('📊 LOCAL: Storage verification:');
      debugPrint('   🚛 Delivery Team: ${storedTrip?.deliveryTeam.target?.id}');
      debugPrint('   👥 Personnel: ${storedTrip?.personels.length}');
      debugPrint('   🏪 Customers: ${storedTrip?.customers.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Save failed - $e');
      throw CacheException(message: e.toString());
    }
  }

@override
Future<void> autoSaveTrip(TripModel trip) async {
  try {
    debugPrint('🔄 Auto-saving trip data: ${trip.tripNumberId}');

    // Clear existing trips
    _tripBox.removeAll();

    // First, save related entities if they exist
    if (trip.deliveryTeam.target != null) {
      final deliveryTeamBox = _store.box<DeliveryTeamModel>();
      final deliveryTeam = trip.deliveryTeam.target!;
      deliveryTeam.tripId = trip.id;
      deliveryTeamBox.put(deliveryTeam);
      debugPrint('✅ Saved delivery team: ${deliveryTeam.id}');
    }

    if (trip.otp.target != null) {
      final otpBox = _store.box<OtpModel>();
      final otp = trip.otp.target!;
      otp.tripId = trip.id;
      otpBox.put(otp);
      debugPrint('✅ Saved OTP: ${otp.id}');
    }

    if (trip.endTripOtp.target != null) {
      final endTripOtpBox = _store.box<EndTripOtpModel>();
      final endTripOtp = trip.endTripOtp.target!;
      endTripOtp.tripId = trip.id;
      endTripOtpBox.put(endTripOtp);
      debugPrint('✅ Saved End Trip OTP: ${endTripOtp.id}');
    }

    // Save personnel
    if (trip.personels.isNotEmpty) {
      final personnelBox = _store.box<PersonelModel>();
      for (final personnel in trip.personels) {
        personnel.tripId = trip.id;
        personnelBox.put(personnel);
      }
      debugPrint('✅ Saved ${trip.personels.length} personnel');
    }

    // Save vehicles
    if (trip.vehicle.isNotEmpty) {
      final vehicleBox = _store.box<VehicleModel>();
      for (final vehicle in trip.vehicle) {
        vehicle.tripId = trip.id;
        vehicleBox.put(vehicle);
      }
      debugPrint('✅ Saved ${trip.vehicle.length} vehicles');
    }

    // Save checklist items
    if (trip.checklist.isNotEmpty) {
      final checklistBox = _store.box<ChecklistModel>();
      for (final item in trip.checklist) {
        item.tripId = trip.id;
        checklistBox.put(item);
      }
      debugPrint('✅ Saved ${trip.checklist.length} checklist items');
    }

    // Save customers
    if (trip.customers.isNotEmpty) {
      final customerBox = _store.box<CustomerModel>();
      for (final customer in trip.customers) {
        customer.tripId = trip.id;
        customerBox.put(customer);
      }
      debugPrint('✅ Saved ${trip.customers.length} customers');
    }

    // Create a complete trip model with all fields
    final tripToSave = TripModel(
      id: trip.id,
   //pocketbaseId: trip.id, // Important for queries by ID
      collectionId: trip.collectionId,
      collectionName: trip.collectionName,
      tripNumberId: trip.tripNumberId,
      totalTripDistance: trip.totalTripDistance,
      qrCode: trip.qrCode,
      created: trip.created,
      updated: trip.updated,
      isAccepted: true,
      timeAccepted: trip.timeAccepted ?? DateTime.now(),
      isEndTrip: trip.isEndTrip,
      timeEndTrip: trip.timeEndTrip,
      objectBoxId: 1
    );

    // Save the trip
    final tripId = _tripBox.put(tripToSave);
    debugPrint('✅ Trip saved with ID: $tripId');

    // Update the cached trip
    _cachedTrip = tripToSave;

    // Verify the saved trip
    final savedTrip = _tripBox.get(tripId);
    if (savedTrip != null) {
      debugPrint('✅ Trip verification successful');
      debugPrint('   🎫 Trip Number: ${savedTrip.tripNumberId}');
      debugPrint('   🔢 Trip ID: ${savedTrip.id}');
      debugPrint('   ✓ Is Accepted: ${savedTrip.isAccepted}');
    } else {
      debugPrint('❌ Trip verification failed - trip not found after save');
    }

    // Update user data in SharedPreferences to include trip
    final prefs = await SharedPreferences.getInstance();
    final storedUserData = prefs.getString('user_data');
    
    if (storedUserData != null) {
      try {
        final userData = jsonDecode(storedUserData);
        userData['tripNumberId'] = trip.tripNumberId;
        userData['trip'] = {
          'id': trip.id,
          'tripNumberId': trip.tripNumberId
        };
        
        await prefs.setString('user_data', jsonEncode(userData));
        debugPrint('✅ Updated user data in SharedPreferences with trip info');
      } catch (e) {
        debugPrint('❌ Failed to update user data in SharedPreferences: $e');
      }
    }
  } catch (e) {
    debugPrint('❌ Auto-save failed: $e');
    throw CacheException(message: e.toString());
  }
}


  @override
  Future<String?> getTrackingId() async {
    debugPrint('🔍 Retrieving tracking ID');
    return _trackingId;
  }

  @override
  Future<bool> checkEndTripOtpStatus(String tripId) async {
    try {
      debugPrint('🔍 Checking end trip OTP status for: $tripId');

      final trips = _tripBox.getAll().where((trip) => trip.id == tripId);
      if (trips.isEmpty) {
        throw const CacheException(message: 'Trip not found in local storage');
      }

      final trip = trips.first;
      final hasEndTripOtp = trip.endTripOtp.target != null;
      final isEndTrip = trip.isEndTrip;

      debugPrint('📊 End Trip Status Check:');
      debugPrint('Has End Trip OTP: $hasEndTripOtp');
      debugPrint('Is End Trip: $isEndTrip');

      return hasEndTripOtp && isEndTrip!;
    } catch (e) {
      debugPrint('❌ End trip status check failed: $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> saveChecklist(List<ChecklistModel> checklist) async {
    debugPrint(
        '💾 Saving ${checklist.length} checklist items to local storage');
    final checklistBox = _store.box<ChecklistModel>();
    checklistBox.putMany(checklist);
  }

  @override
  Future<void> saveCustomers(List<CustomerModel> customers) async {
    debugPrint('💾 Saving ${customers.length} customers to local storage');
    final customerBox = _store.box<CustomerModel>();
    customerBox.putMany(customers);
  }

  @override
  Future<void> saveDeliveryTeam(DeliveryTeamModel deliveryTeam) async {
    debugPrint('💾 LOCAL: Saving delivery team');
    final deliveryTeamBox = _store.box<DeliveryTeamModel>();
    final id = deliveryTeamBox.put(deliveryTeam);
    debugPrint('✅ LOCAL: Delivery team saved with ID: $id');
  }

  @override
  Future<void> savePersonnel(List<PersonelModel> personnel) async {
    debugPrint('💾 Saving ${personnel.length} personnel to local storage');
    final personnelBox = _store.box<PersonelModel>();
    personnelBox.putMany(personnel);
  }

  @override
  Future<void> saveVehicles(List<VehicleModel> vehicles) async {
    debugPrint('💾 Saving ${vehicles.length} vehicles to local storage');
    final vehicleBox = _store.box<VehicleModel>();
    vehicleBox.putMany(vehicles);
  }

  @override
  Future<String> calculateTotalTripDistance(String tripId) async {
    try {
      debugPrint('📊 LOCAL: Calculating total trip distance');
      final trip = _tripBox
          .query(TripModel_.pocketbaseId.equals(tripId))
          .build()
          .findFirst();

      if (trip != null) {
        final startOdometer = trip.otp.target?.intransitOdometer ?? '0';
        final endOdometer = trip.endTripOtp.target?.endTripOdometer ?? '0';

        final totalDistance =
            (int.parse(endOdometer) - int.parse(startOdometer)).toString();
        trip.totalTripDistance = totalDistance;

        _tripBox.put(trip);
        debugPrint(
            '✅ LOCAL: Total trip distance calculated: $totalDistance km');
        return totalDistance;
      } else {
        throw const CacheException(message: 'Trip not found in local storage');
      }
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to calculate trip distance: $e');
      throw CacheException(message: e.toString());
    }
  }
@override
Future<void> endTrip() async {
  try {
    debugPrint('🧹 Starting complete data cleanup');

    // Get current user before clearing data
    final prefs = await SharedPreferences.getInstance();
    final storedUserData = prefs.getString('user_data');
    
    if (storedUserData != null) {
      try {
        // Parse the stored user data
        final userData = jsonDecode(storedUserData);
        
        // Update user's trip assignment in ObjectBox
        final userBox = _store.box<LocalUsersModel>();
        
        // Find the current user
        final users = userBox.getAll();
        for (final user in users) {
          // Clear trip assignment
          user.trip.target = null;
          user.tripId = null;
          userBox.put(user);
          debugPrint('✅ Cleared trip assignment for user: ${user.id}');
        }
        
        // Create updated user data without trip information
        final updatedUserData = {
          'id': userData['id'],
          'collectionId': userData['collectionId'],
          'collectionName': userData['collectionName'],
          'email': userData['email'],
          'name': userData['name'],
          'tripNumberId': null,  // Explicitly set to null
          'trip': null,          // Explicitly set to null
          'tokenKey': userData['tokenKey']
        };
        
        // Save the updated user data to SharedPreferences
        await prefs.setString('user_data', jsonEncode(updatedUserData));
        debugPrint('✅ Updated user data in SharedPreferences - removed trip assignment');
        
        // Also remove any trip-related keys completely
        await prefs.remove('trip');
        await prefs.remove('tripNumberId');
        await prefs.remove('tripId');
        debugPrint('✅ Removed all trip-related keys from SharedPreferences');
      } catch (e) {
        debugPrint('⚠️ Error updating user data: $e');
        // Continue with cleanup even if user data update fails
      }
    }

    // Clear all ObjectBox data
    _store.box<TripModel>().removeAll();
    _store.box<CustomerModel>().removeAll();
    _store.box<DeliveryTeamModel>().removeAll();
    _store.box<PersonelModel>().removeAll();
    _store.box<VehicleModel>().removeAll();
    _store.box<ChecklistModel>().removeAll();
    _store.box<InvoiceModel>().removeAll();
    _store.box<ProductModel>().removeAll();
    _store.box<DeliveryUpdateModel>().removeAll();
    _store.box<CompletedCustomerModel>().removeAll();
    _store.box<ReturnModel>().removeAll();
    _store.box<TransactionModel>().removeAll();
    _store.box<EndTripChecklistModel>().removeAll();
    _store.box<UndeliverableCustomerModel>().removeAll();
    _store.box<TripUpdateModel>().removeAll();
    _store.box<OtpModel>().removeAll();      // Also clear OTP data
    _store.box<EndTripOtpModel>().removeAll(); // Also clear EndTripOtp data
    debugPrint('✅ Cleared all ObjectBox data');

    // Clear cached states
    _cachedTrip = null;
    _trackingId = null;

    // Clear other SharedPreferences data
    await prefs.remove('user_trip_data');
    await prefs.remove('trip_cache');
    await prefs.remove('delivery_status_cache');
    await prefs.remove('customer_cache');
    await prefs.remove('active_trip');
    await prefs.remove('last_trip_id');
    await prefs.remove('last_trip_number');
    
    // Verify the cleanup was successful
    final tripCount = _store.box<TripModel>().count();
    final userDataAfterCleanup = prefs.getString('user_data');
    if (userDataAfterCleanup != null) {
      final parsedData = jsonDecode(userDataAfterCleanup);
      debugPrint('✅ Verification - User data after cleanup:');
      debugPrint('   👤 Name: ${parsedData['name']}');
      debugPrint('   📧 Email: ${parsedData['email']}');
      debugPrint('   🎫 Trip Number: ${parsedData['tripNumberId']}');
      debugPrint('   🎫 Trip: ${parsedData['trip']}');
    }
    debugPrint('✅ Verification - Trip count after cleanup: $tripCount');

    debugPrint('✅ All data and caches cleared successfully');
  } catch (e) {
    debugPrint('❌ Error clearing data: $e');
    throw CacheException(message: e.toString());
  }
}



}
