import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/vehicle/presentation/bloc/vehicle_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/presentation/bloc/completed_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_event.dart';

import 'package:x_pro_delivery_app/core/services/injection_container.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

class SyncService {
  final store = sl<ObjectBoxStore>();
  final _pocketBaseClient = sl<PocketBase>();
  StreamController<double>? _progressController;
  StreamSubscription? customerSubscription;
  StreamSubscription? completedSubscription;
  StreamSubscription? tripSubscription;
  StreamSubscription? deliverySubscription;
  StreamSubscription? undeliverableSubscription;
  StreamSubscription? returnSubscription;

  Stream<double> get progressStream {
    _progressController ??= StreamController<double>.broadcast();
    return _progressController!.stream;
  }

  void _updateProgress(double progress) {
    debugPrint('📈 Updating sync progress: ${(progress * 100).toInt()}%');
    _progressController?.add(progress);
  }
  // Update the checkUserHasTrip method to return the trip ID if available
Future<bool> checkUserHasTrip(BuildContext context) async {
  debugPrint('🔄 Starting user data sync process');
  
  final prefs = await SharedPreferences.getInstance();
  final storedData = prefs.getString('user_data');
  final authBloc = context.read<AuthBloc>();
  
  if (storedData == null) {
    debugPrint('⚠️ No stored user data found, initiating sync');
    
    final completer = Completer<bool>();
    StreamSubscription? subscription;

    subscription = authBloc.stream.listen((state) {
      debugPrint('🔄 Auth State: $state');
      
      if (state is RemoteUserDataLoaded) {
        debugPrint('✅ Remote user data fetched');
        authBloc.add(GetUserTripEvent(state.user.id!));
      } 
      else if (state is UserDataSynced) {
        debugPrint('✅ User data synced to local storage');
        authBloc.add(const LoadLocalUserDataEvent());
      }
      else if (state is UserTripLoaded) {
        // Check if the trip is actually valid
        if (state.trip.id != null && state.trip.isAccepted == true && state.trip.isEndTrip != true) {
          debugPrint('✅ Active trip found: ${state.trip.id}');
          completer.complete(true);
        } else {
          debugPrint('⚠️ Found trip is not active or valid');
          completer.complete(false);
        }
        subscription?.cancel();
      }
      else if (state is AuthError) {
        debugPrint('❌ Error during sync: ${state.message}');
        completer.complete(false);
        subscription?.cancel();
      }
    });

    authBloc.add(const LoadRemoteUserDataEvent());
    return completer.future;
  }

  // Parse stored user data
  String? userId;
  String? tripId;
 bool hasValidTrip = false;
  
  try {
    final Map<String, dynamic> userData = Map<String, dynamic>.from(jsonDecode(storedData));
    userId = userData['id']?.toString();
    
    // Check if there's a trip in the user data and if it's valid
    if (userData.containsKey('trip') && userData['trip'] != null) {
      final tripData = userData['trip'];
      if (tripData is Map && tripData.containsKey('id')) {
        tripId = tripData['id']?.toString();
        // Don't assume the trip is valid just because it exists in preferences
        hasValidTrip; // We'll verify this with the server
      }
    }
    
    debugPrint('👤 Found user ID: $userId');
    debugPrint('🎫 Found trip ID in preferences: $tripId');
  } catch (e) {
    debugPrint('⚠️ Failed to parse user data: $e');
    return false;
  }

  if (userId == null) {
    debugPrint('⚠️ No valid user ID found in stored data');
    return false;
  }

  final completer = Completer<bool>();
  StreamSubscription? subscription;

  subscription = authBloc.stream.listen((state) {
    debugPrint('🔄 Auth State: $state');
    
    if (state is LocalUserDataLoaded) {
      debugPrint('✅ User data loaded from local storage');
      // Always verify with remote data
      authBloc.add(const LoadRemoteUserDataEvent());
    } 
    else if (state is RemoteUserDataLoaded) {
      debugPrint('✅ Remote user data synced');
      // Get the latest trip status from the server
      authBloc.add(GetUserTripEvent(userId!));
    }
    else if (state is UserTripLoaded) {
      // Verify the trip is actually valid and active
      if (state.trip.id != null && state.trip.isAccepted == true && state.trip.isEndTrip != true) {
        debugPrint('✅ Active trip confirmed from server: ${state.trip.id}');
        completer.complete(true);
      } else {
        debugPrint('⚠️ Server indicates no active trip for this user');
        // If the server says there's no active trip but we had one in preferences,
        // we should clear that invalid trip data
        if (tripId != null) {
          _clearInvalidTripData();
        }
        completer.complete(false);
      }
      subscription?.cancel();
    } 
    else if (state is AuthError) {
      debugPrint('❌ No active trip found: ${state.message}');
      // If we get an error but had a trip in preferences, clear it as it's likely invalid
      if (tripId != null) {
        _clearInvalidTripData();
      }
      completer.complete(false);
      subscription?.cancel();
    }
  });

  // Start the sync chain
  debugPrint('🔄 Starting user data sync chain');
  authBloc.add(const LoadLocalUserDataEvent());

  return completer.future;
}

// Helper method to clear invalid trip data
Future<void> _clearInvalidTripData() async {
  debugPrint('🧹 Clearing invalid trip data from preferences');
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');
    
    if (storedData != null) {
      final userData = jsonDecode(storedData);
      userData['tripNumberId'] = null;
      userData['trip'] = null;
      
      await prefs.setString('user_data', jsonEncode(userData));
      
      // Also remove any other trip-related keys
      await prefs.remove('user_trip_data');
      await prefs.remove('trip_cache');
      await prefs.remove('active_trip');
      await prefs.remove('last_trip_id');
      await prefs.remove('last_trip_number');
      
      debugPrint('✅ Successfully cleared invalid trip data from preferences');
    }
  } catch (e) {
    debugPrint('❌ Error clearing invalid trip data: $e');
  }
}


// Update the syncAllData method to return a Future<bool> indicating completion
Future<bool> syncAllData(BuildContext context) async {
  try {
    debugPrint('🔄 Starting data sync...');
    _progressController ??= StreamController<double>.broadcast();

    // Clear existing data
    debugPrint('🧹 Clearing old data for fresh sync...');
    store.deliveryTeamBox.removeAll();
    store.customerBox.removeAll();
    store.invoiceBox.removeAll();
    store.productBox.removeAll();
    store.deliveryUpdateBox.removeAll();
    store.completedCustomerBox.removeAll();
    store.returnBox.removeAll();
    store.transactionBox.removeAll();
    store.endTripChecklistBox.removeAll();
    store.undeliverableCustomerBox.removeAll();
    store.tripUpdatesBox.removeAll();
    store.vehicleBox.removeAll();
    store.personelBox.removeAll();

    // Check authentication sources
    final currentUser = _pocketBaseClient.authStore.model;
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (currentUser?.id == null && storedData == null) {
      debugPrint('⚠️ No authentication found');
      return false;
    }

    String? userId;
    
    if (storedData != null) {
      try {
        // Handle stored data as a Map
        if (storedData.startsWith('{')) {
          final Map<String, dynamic> userData = Map<String, dynamic>.from(jsonDecode(storedData));
          userId = userData['id']?.toString();
        } 
        // Handle stored data as a String
        else {
          userId = storedData;
        }
      } catch (e) {
        debugPrint('⚠️ Failed to parse stored data, using raw value');
        userId = storedData;
      }
    } else if (currentUser?.id != null) {
      userId = currentUser!.id;
    }

    if (userId == null) {
      debugPrint('⚠️ No valid user ID found');
      return false;
    }

    final completer = Completer<bool>();
    
    debugPrint('👤 Using user ID: $userId');
    final authBloc = context.read<AuthBloc>();
    authBloc
      ..add(LoadLocalUserByIdEvent(userId))
      ..add(GetUserTripEvent(userId));

    StreamSubscription? subscription;
    subscription = authBloc.stream.listen((state) {
      if (state is UserTripLoaded && state.trip.id != null) {
        final tripId = state.trip.id!;
        debugPrint('🚚 Starting sync for trip: ${state.trip.tripNumberId}');

        // Delivery Team (10%)
        final deliveryTeamBloc = context.read<DeliveryTeamBloc>();
        deliveryTeamBloc
          ..add(LoadDeliveryTeamEvent(tripId))
          ..add(LoadLocalDeliveryTeamEvent(tripId))
          ..add(LoadDeliveryTeamByIdEvent(tripId));
        _updateProgress(0.10);

        // Vehicle (20%)
        final vehicleBloc = context.read<VehicleBloc>();
        vehicleBloc
          ..add(LoadVehicleByTripIdEvent(tripId))
          ..add(LoadLocalVehicleByTripIdEvent(tripId));
        _updateProgress(0.20);

        // Customer (30%)
        final customerBloc = context.read<CustomerBloc>();
        customerBloc.add(GetCustomerEvent(tripId));
        _updateProgress(0.30);

      // Invoice and Products (40-60%)
final invoiceBloc = context.read<InvoiceBloc>();
final productsBloc = context.read<ProductsBloc>();

// First, load all invoices for the trip
invoiceBloc
  ..add(GetInvoicesByTripEvent(tripId))
  ..add(LoadLocalInvoicesByTripEvent(tripId));
_updateProgress(0.40);

// Wait for invoices to load
bool invoicesLoaded = false;
List<String> invoiceIds = [];
StreamSubscription? invoiceSubscription;

invoiceSubscription = invoiceBloc.stream.listen((state) {
  if (state is TripInvoicesLoaded) {
    debugPrint('✅ Loaded ${state.invoices.length} invoices for trip: $tripId');
    
    // Extract invoice IDs
    invoiceIds = state.invoices
        .where((invoice) => invoice.id != null && invoice.id!.isNotEmpty)
        .map((invoice) => invoice.id!)
        .toList();
    
    invoicesLoaded = true;
    invoiceSubscription?.cancel();
    
    // Now load products for each invoice
    debugPrint('🔄 Loading products for ${invoiceIds.length} invoices');
    
    // Track progress for products loading
    double baseProgress = 0.45;
    double progressStep = invoiceIds.isEmpty ? 0.15 : 0.15 / invoiceIds.length;
    
    for (int i = 0; i < invoiceIds.length; i++) {
      final invoiceId = invoiceIds[i];
      debugPrint('🔄 Loading products for invoice: $invoiceId (${i+1}/${invoiceIds.length})');
      
      // Load products for this invoice
      productsBloc.add(GetProductsByInvoiceIdEvent(invoiceId));
      productsBloc.add(LoadLocalProductsByInvoiceIdEvent(invoiceId));
      
      // Update progress for each invoice processed
      _updateProgress(baseProgress + (i + 1) * progressStep);
    }
    
    // If no invoices, still update progress
    if (invoiceIds.isEmpty) {
      _updateProgress(0.60);
    }
  }
});

// Add a timeout to ensure we don't get stuck waiting for invoices
Future.delayed(const Duration(seconds: 5), () {
  if (!invoicesLoaded) {
    debugPrint('⚠️ Timeout waiting for invoices to load');
    invoiceSubscription?.cancel();
    _updateProgress(0.60); // Move to next step anyway
  }
});


        // Delivery Updates (60%)
        final deliveryUpdateBloc = context.read<DeliveryUpdateBloc>();
        deliveryUpdateBloc.add(CheckEndDeliveryStatusEvent(tripId));
        _updateProgress(0.60);

        // Completed Customers (70%)
        final completedCustomerBloc = context.read<CompletedCustomerBloc>();
        completedCustomerBloc
          ..add(LoadLocalCompletedCustomerEvent(tripId))
          ..add(GetCompletedCustomerEvent(tripId));
        _updateProgress(0.70);

        // Trip Updates (75%)
        final tripUpdatesBloc = context.read<TripUpdatesBloc>();
        tripUpdatesBloc
          ..add(LoadLocalTripUpdatesEvent(tripId))
          ..add(GetTripUpdatesEvent(tripId));
        _updateProgress(0.75);

        // Returns (80%)
        final returnBloc = context.read<ReturnBloc>();
        returnBloc
          ..add(GetReturnsEvent(tripId))
          ..add(LoadLocalReturnsEvent(tripId));
        _updateProgress(0.80);

        // Undeliverable Customers (85%)
        final undeliverableCustomerBloc = context.read<UndeliverableCustomerBloc>();
        undeliverableCustomerBloc
          ..add(GetUndeliverableCustomersEvent(tripId))
          ..add(LoadLocalUndeliverableCustomersEvent(tripId));
        _updateProgress(0.85);

        // End Trip Checklist (90%)
        final endTripChecklistBloc = context.read<EndTripChecklistBloc>();
        endTripChecklistBloc
          ..add(LoadEndTripChecklistEvent(tripId))
          ..add(LoadLocalEndTripChecklistEvent(tripId));
        _updateProgress(1);

        // Complete the sync after a short delay to ensure all data is loaded
        Future.delayed(const Duration(seconds: 2), () {
          debugPrint('✅ Sync complete for trip: ${state.trip.tripNumberId}');
          completer.complete(true);
          subscription?.cancel();
        });
      } else if (state is AuthError) {
        debugPrint('❌ Error during sync: ${state.message}');
        completer.complete(false);
        subscription?.cancel();
      }
    });

    return completer.future;
  } catch (e) {
    debugPrint('❌ Error during sync: $e');
    return false;
  }
}


  Future<void> refreshScreen(BuildContext context) async {
    debugPrint('🔄 Refreshing screen data...');

    final tripBloc = context.read<TripBloc>();
    final tripState = tripBloc.state;
    final deliveryTeamBloc = context.read<DeliveryTeamBloc>();
    final customerBloc = context.read<CustomerBloc>();
    final completedCustomerBloc = context.read<CompletedCustomerBloc>();
    final invoiceBloc = context.read<InvoiceBloc>();
    final productsBloc = context.read<ProductsBloc>();
    final returnBloc = context.read<ReturnBloc>();
    final undeliverableCustomerBloc = context.read<UndeliverableCustomerBloc>();
    context.read<TransactionBloc>();
    final endTripChecklistBloc = context.read<EndTripChecklistBloc>();
    final tripUpdatesBloc = context.read<TripUpdatesBloc>();

    tripBloc.add(const GetTripEvent());

    if (tripState is TripLoaded && tripState.trip.id != null) {
      deliveryTeamBloc.add(LoadDeliveryTeamEvent(tripState.trip.id!));
      customerBloc.add(GetCustomerEvent(tripState.trip.id!));
      completedCustomerBloc.add(GetCompletedCustomerEvent(tripState.trip.id!));

      // Enhanced invoice refresh
      invoiceBloc.add(const GetInvoiceEvent());
      invoiceBloc.add(GetInvoicesByTripEvent(tripState.trip.id!));
      for (final customer in tripState.trip.customers) {
        if (customer.id?.isNotEmpty ?? false) {
          invoiceBloc.add(GetInvoicesByCustomerEvent(customer.id!));
        }
      }

      returnBloc.add(GetReturnsEvent(tripState.trip.id!));
      undeliverableCustomerBloc
          .add(GetUndeliverableCustomersEvent(tripState.trip.id!));
      endTripChecklistBloc.add(LoadEndTripChecklistEvent(tripState.trip.id!));
  
      tripUpdatesBloc.add(GetTripUpdatesEvent(tripState.trip.id!));
    }

    invoiceBloc.add(const GetInvoiceEvent());
    productsBloc.add(const GetProductsEvent());

    debugPrint('✅ Screen refresh complete');
  }

  void dispose() {
    _progressController?.close();
    _progressController = null;
    customerSubscription?.cancel();
    completedSubscription?.cancel();
    tripSubscription?.cancel();
    deliverySubscription?.cancel();
    undeliverableSubscription?.cancel();
    returnSubscription?.cancel();
  }
}