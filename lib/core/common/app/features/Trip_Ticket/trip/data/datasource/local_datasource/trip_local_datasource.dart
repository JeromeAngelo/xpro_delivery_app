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

      _tripBox.removeAll();

      final tripToSave = TripModel(
          id: trip.id,
          collectionId: trip.collectionId,
          collectionName: trip.collectionName,
          tripNumberId: trip.tripNumberId,
          customersList: trip.customers.map((c) => c).toList(),
          personelsList: trip.personels.map((p) => p).toList(),
          checklistItems: trip.checklist.map((c) => c).toList(),
          vehicleList: trip.vehicle.map((v) => v).toList(),
          created: trip.created,
          updated: trip.updated,
          isAccepted: trip.isAccepted,
          objectBoxId: 1);

      _tripBox.put(tripToSave);
      debugPrint('✅ Trip auto-saved with relationships');

      // Verify relationships
      debugPrint('📊 Relationship counts:');
      debugPrint('Customers: ${tripToSave.customers.length}');
      debugPrint('Personnel: ${tripToSave.personels.length}');
      debugPrint('Vehicles: ${tripToSave.vehicle.length}');
      debugPrint('Checklist items: ${tripToSave.checklist.length}');
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
      // Update user's trip assignment in ObjectBox
      final userData = jsonDecode(storedUserData);
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
      
      // Update user data in SharedPreferences without trip
      final updatedUserData = {
        'id': userData['id'],
        'collectionId': userData['collectionId'],
        'collectionName': userData['collectionName'],
        'email': userData['email'],
        'name': userData['name'],
        'tripNumberId': null,
        'trip': null,
        'tokenKey': userData['tokenKey']
      };
      
      await prefs.setString('user_data', jsonEncode(updatedUserData));
      debugPrint('✅ Updated user data in SharedPreferences - removed trip assignment');
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

    // Clear cached states
    _cachedTrip = null;
    _trackingId = null;

    // Clear other SharedPreferences data
    await prefs.remove('user_trip_data');
    await prefs.remove('trip_cache');
    await prefs.remove('delivery_status_cache');
    await prefs.remove('customer_cache');

    debugPrint('✅ All data and caches cleared successfully');
  } catch (e) {
    debugPrint('❌ Error clearing data: $e');
    throw CacheException(message: e.toString());
  }
}


}
