import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/presentation/bloc/end_trip_checklist_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart'
    show DeliveryDataEntity;
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';

import 'package:x_pro_delivery_app/core/services/injection_container.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

import '../common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart';
import '../common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_event.dart';
import '../common/app/features/Trip_Ticket/collection/presentation/bloc/collections_bloc.dart';
import '../common/app/features/Trip_Ticket/collection/presentation/bloc/collections_event.dart';
import '../common/app/features/Trip_Ticket/customer_data/presentation/bloc/customer_data_bloc.dart';
import '../common/app/features/Trip_Ticket/customer_data/presentation/bloc/customer_data_event.dart';
import '../common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import '../common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';
import '../common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_event.dart';
import '../common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_bloc.dart';
import '../common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_event.dart';
import '../common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_state.dart';
import '../common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_bloc.dart';
import '../common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_event.dart';
import '../common/app/features/user_performance/presentation/bloc/user_performance_bloc.dart';
import '../common/app/features/user_performance/presentation/bloc/user_performance_event.dart';

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


// Add these constants
static const String _pendingOperationsKey = 'pending_sync_operations';
static const String _lastSyncKey = 'last_sync_time';

// Add these properties
bool _isSyncing = false;
bool get isSyncing => _isSyncing;

DateTime? _lastSyncTime;
DateTime? get lastSyncTime => _lastSyncTime;

final List<String> _pendingSyncOperations = [];
List<String> get pendingSyncOperations => List.unmodifiable(_pendingSyncOperations);

  Stream<double> get progressStream {
    _progressController ??= StreamController<double>.broadcast();
    return _progressController!.stream;
  }

  // Queue an operation for sync when online
Future<void> queueOperation({
  required String operationType,
  required String entityType,
  required String entityId,
  required Map<String, dynamic> data,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final existingOperations = prefs.getStringList(_pendingOperationsKey) ?? [];
    
    final operation = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': operationType, // 'create', 'update', 'delete'
      'entityType': entityType, // 'trip', 'user', 'delivery_data', etc.
      'entityId': entityId,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    existingOperations.add(jsonEncode(operation));
    await prefs.setStringList(_pendingOperationsKey, existingOperations);
    
addPendingSyncOperation(operation['id']! as String);    
    debugPrint('📝 Queued sync operation: $operationType $entityType $entityId');
    
    // Try to sync immediately if online
    if (_pocketBaseClient.authStore.isValid) {
      await processPendingOperations();
    }
  } catch (e) {
    debugPrint('❌ Failed to queue operation: $e');
  }
}

void addPendingSyncOperation(String operation) {
  if (!_pendingSyncOperations.contains(operation)) {
    _pendingSyncOperations.add(operation);
    debugPrint('📝 Added pending sync operation: $operation');
  }
}

void removePendingSyncOperation(String operation) {
  _pendingSyncOperations.remove(operation);
  debugPrint('✅ Completed sync operation: $operation');
}

// Process all pending operations when online
Future<void> processPendingOperations() async {
  if (!_pocketBaseClient.authStore.isValid) {
    debugPrint('⚠️ Cannot sync - not authenticated');
    return;
  }

  try {
    _isSyncing = true;
    
    final prefs = await SharedPreferences.getInstance();
    final pendingOperations = prefs.getStringList(_pendingOperationsKey) ?? [];
    
    if (pendingOperations.isEmpty) {
      debugPrint('✅ No pending operations to sync');
      _isSyncing = false;
      return;
    }

    debugPrint('🔄 Processing ${pendingOperations.length} pending operations');
    
    final List<String> failedOperations = [];
    
    for (final operationJson in pendingOperations) {
      try {
        final operation = jsonDecode(operationJson) as Map<String, dynamic>;
        
        // Process the operation based on type
        final success = await _processOperation(operation);
        
        if (success) {
          removePendingSyncOperation(operation['id']);
          debugPrint('✅ Synced operation: ${operation['type']} ${operation['entityType']}');
        } else {
          failedOperations.add(operationJson);
          debugPrint('❌ Failed to sync operation: ${operation['type']} ${operation['entityType']}');
        }
      } catch (e) {
        debugPrint('❌ Error processing operation: $e');
        failedOperations.add(operationJson);
      }
    }
    
    // Update pending operations with only the failed ones
    await prefs.setStringList(_pendingOperationsKey, failedOperations);
    
    // Update last sync time
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    _lastSyncTime = DateTime.now();
    
    debugPrint('✅ Sync completed. ${failedOperations.length} operations failed');
    
  } catch (e) {
    debugPrint('❌ Sync process failed: $e');
  } finally {
    _isSyncing = false;
  }
}

Future<bool> _processOperation(Map<String, dynamic> operation) async {
  try {
    final operationType = operation['type'] as String;
    final entityType = operation['entityType'] as String;
    final entityId = operation['entityId'] as String;
    final data = operation['data'] as Map<String, dynamic>;
    
    debugPrint('🔄 Processing $operationType $entityType $entityId');
    
    // Process based on entity type
    switch (entityType) {
      case 'trip':
        return await _syncTripOperation(operationType, entityId, data);
      case 'user':
        return await _syncUserOperation(operationType, entityId, data);
      case 'delivery_data':
        return await _syncDeliveryDataOperation(operationType, entityId, data);
      case 'delivery_update':
        return await _syncDeliveryUpdateOperation(operationType, entityId, data);
      default:
        debugPrint('⚠️ Unknown entity type: $entityType');
        return false;
    }
  } catch (e) {
    debugPrint('❌ Failed to process operation: $e');
    return false;
  }
}

Future<bool> _syncTripOperation(String operationType, String entityId, Map<String, dynamic> data) async {
  try {
    switch (operationType) {
      case 'update':
        await _pocketBaseClient.collection('tripticket').update(entityId, body: data);
        break;
      case 'create':
        await _pocketBaseClient.collection('tripticket').create(body: data);
        break;
      default:
        return false;
    }
    return true;
  } catch (e) {
    debugPrint('❌ Trip sync failed: $e');
    return false;
  }
}

Future<bool> _syncUserOperation(String operationType, String entityId, Map<String, dynamic> data) async {
  try {
    switch (operationType) {
      case 'update':
        await _pocketBaseClient.collection('users').update(entityId, body: data);
        break;
      default:
        return false;
    }
    return true;
  } catch (e) {
    debugPrint('❌ User sync failed: $e');
    return false;
  }
}

Future<bool> _syncDeliveryDataOperation(String operationType, String entityId, Map<String, dynamic> data) async {
  try {
    switch (operationType) {
      case 'update':
        await _pocketBaseClient.collection('deliveryData').update(entityId, body: data);
        break;
      case 'create':
        await _pocketBaseClient.collection('deliveryData').create(body: data);
        break;
      default:
        return false;
    }
    return true;
  } catch (e) {
    debugPrint('❌ Delivery data sync failed: $e');
    return false;
  }
}

Future<bool> _syncDeliveryUpdateOperation(String operationType, String entityId, Map<String, dynamic> data) async {
  try {
    switch (operationType) {
      case 'update':
        await _pocketBaseClient.collection('delivery_update').update(entityId, body: data);
        break;
      case 'create':
        await _pocketBaseClient.collection('delivery_update').create(body: data);
        break;
      default:
        return false;
    }
    return true;
  } catch (e) {
    debugPrint('❌ Delivery update sync failed: $e');
    return false;
  }
}

Future<DateTime?> getLastSyncTime() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    if (lastSyncString != null) {
      _lastSyncTime = DateTime.parse(lastSyncString);
      return _lastSyncTime;
    }
  } catch (e) {
    debugPrint('❌ Failed to get last sync time: $e');
  }
  return null;
}

// Call this method when internet connection is restored
Future<void> onConnectionRestored() async {
  debugPrint('🌐 Connection restored - starting auto sync');
  await processPendingOperations();
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
        } else if (state is UserDataSynced) {
          debugPrint('✅ User data synced to local storage');
          authBloc.add(const LoadLocalUserDataEvent());
        } else if (state is UserTripLoaded) {
          // Check if the trip is actually valid
          if (state.trip.id != null &&
              state.trip.isAccepted == true &&
              state.trip.isEndTrip != true) {
            debugPrint('✅ Active trip found: ${state.trip.id}');
            completer.complete(true);
          } else {
            debugPrint('⚠️ Found trip is not active or valid');
            completer.complete(false);
          }
          subscription?.cancel();
        } else if (state is AuthError) {
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
      final Map<String, dynamic> userData = Map<String, dynamic>.from(
        jsonDecode(storedData),
      );
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
      } else if (state is RemoteUserDataLoaded) {
        debugPrint('✅ Remote user data synced');
        // Get the latest trip status from the server
        authBloc.add(GetUserTripEvent(userId!));
      } else if (state is UserTripLoaded) {
        // Verify the trip is actually valid and active
        if (state.trip.id != null &&
            state.trip.isAccepted == true &&
            state.trip.isEndTrip != true) {
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
      } else if (state is AuthError) {
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

  Future<bool> syncAllData(BuildContext context) async {
    try {
      debugPrint('🔄 Starting data sync...');
      _progressController ??= StreamController<double>.broadcast();

      // Clear existing data
      debugPrint('🧹 Clearing old data for fresh sync...');
      store.deliveryDataBox.removeAll();
      store.deliveryTeamBox.removeAll();
      store.deliveryUpdateBox.removeAll();
      store.endTripChecklistBox.removeAll();
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
            final Map<String, dynamic> userData = Map<String, dynamic>.from(
              jsonDecode(storedData),
            );
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

      // === PHASE 0: USER TRIP DATA SYNC (0-15%) ===
      debugPrint('🎫 Starting user trip data sync...');
      _updateProgress(0.05);

      // Sync user trip data first
      bool tripSyncCompleted = false;
      StreamSubscription? tripSyncSubscription;

      tripSyncSubscription = authBloc.stream.listen((state) {
        if (state is TripDataSynced) {
          debugPrint('✅ User trip data synced successfully');
          tripSyncCompleted = true;
          tripSyncSubscription?.cancel();
          _updateProgress(0.15);
        } else if (state is AuthError && !tripSyncCompleted) {
          debugPrint(
            '⚠️ Trip sync failed, continuing with other data: ${state.message}',
          );
          tripSyncCompleted = true;
          tripSyncSubscription?.cancel();
          _updateProgress(0.15);
        }
      });

      // Trigger trip data sync
      authBloc.add(SyncUserTripDataEvent(userId));

      // Wait for trip sync to complete or timeout
      int waitCount = 0;
      while (!tripSyncCompleted && waitCount < 30) {
        // 3 second timeout
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }

      if (!tripSyncCompleted) {
        debugPrint('⚠️ Trip sync timeout, continuing with other data');
        tripSyncSubscription.cancel();
        _updateProgress(0.15);
      }



      // Load user data and get trip
      authBloc
        ..add(LoadLocalUserByIdEvent(userId))
        ..add(GetUserTripEvent(userId));

        // User Performance (15%)
final userPerformanceBloc = context.read<UserPerformanceBloc>();
userPerformanceBloc
  ..add(LoadUserPerformanceByUserIdEvent(userId))
  ..add(LoadLocalUserPerformanceByUserIdEvent(userId));
_updateProgress(0.15);

      StreamSubscription? subscription;
      subscription = authBloc.stream.listen((state) {
        if (state is UserTripLoaded && state.trip.id != null) {
          final tripId = state.trip.id!;
          debugPrint('🚚 Starting sync for trip: ${state.trip.tripNumberId}');

          // === PHASE 1: TRIP-LEVEL DATA (15-40%) ===

          // Delivery Team (20%)
          final deliveryTeamBloc = context.read<DeliveryTeamBloc>();
          deliveryTeamBloc
            ..add(LoadDeliveryTeamEvent(tripId))
            ..add(LoadLocalDeliveryTeamEvent(tripId))
            ..add(LoadDeliveryTeamByIdEvent(tripId));
          _updateProgress(0.20);

          // Delivery Data (25%) - UPDATED to use sync instead of load
          final deliveryDataBloc = context.read<DeliveryDataBloc>();
          deliveryDataBloc.add(
            SyncDeliveryDataByTripIdEvent(tripId),
          ); // CHANGED: Use sync event
          _updateProgress(0.25);

          // Collections (30%)
          final collectionsBloc = context.read<CollectionsBloc>();
          collectionsBloc
            ..add(GetCollectionsByTripIdEvent(tripId))
            ..add(GetLocalCollectionsByTripIdEvent(tripId));
          _updateProgress(0.30);

          // Cancelled Invoices (35%)
          final cancelledInvoiceBloc = context.read<CancelledInvoiceBloc>();
          cancelledInvoiceBloc
            ..add(LoadCancelledInvoicesByTripIdEvent(tripId))
            ..add(LoadLocalCancelledInvoicesByTripIdEvent(tripId));
          _updateProgress(0.35);

          // Delivery Vehicle Data (40%)
          final deliveryVehicleBloc = context.read<DeliveryVehicleBloc>();
          deliveryVehicleBloc.add(LoadDeliveryVehiclesByTripIdEvent(tripId));
          _updateProgress(0.40);

          // End Trip Checklist (40%)
          final endTripChecklistBloc = context.read<EndTripChecklistBloc>();
          endTripChecklistBloc
            ..add(LoadEndTripChecklistEvent(tripId))
            ..add(LoadLocalEndTripChecklistEvent(tripId));
          _updateProgress(0.40);

          // === PHASE 2: DELIVERY DATA DEPENDENT (45-85%) ===

          // Update the delivery data listener section:
          // Wait for delivery data to sync, then sync dependent data
          bool deliveryDataSynced =
              false; // CHANGED: renamed from deliveryDataLoaded
          List<String> deliveryDataIds = [];
          StreamSubscription? deliveryDataSubscription;

          deliveryDataSubscription = deliveryDataBloc.stream.listen((state) {
            // UPDATED: Listen for both sync and load states
            if (state is DeliveryDataSyncedByTrip ||
                state is DeliveryDataByTripLoaded) {
              List<DeliveryDataEntity> deliveryData;

              if (state is DeliveryDataSyncedByTrip) {
                debugPrint(
                  '✅ Synced ${state.deliveryData.length} delivery data records for trip: $tripId',
                );
                deliveryData = state.deliveryData;
              } else if (state is DeliveryDataByTripLoaded) {
                debugPrint(
                  '✅ Loaded ${state.deliveryData.length} delivery data records for trip: $tripId',
                );
                deliveryData = state.deliveryData;
              } else {
                deliveryData = [];
              }

              // Extract delivery data IDs
              deliveryDataIds =
                  deliveryData
                      .where(
                        (deliveryData) =>
                            deliveryData.id != null &&
                            deliveryData.id!.isNotEmpty,
                      )
                      .map((deliveryData) => deliveryData.id!)
                      .toList();

              deliveryDataSynced = true; // CHANGED: renamed variable
              deliveryDataSubscription?.cancel();

              debugPrint(
                '🔄 Loading delivery-dependent data for ${deliveryDataIds.length} delivery records',
              );

              // Continue with existing dependent data loading logic...
              double baseProgress = 0.45;
              double progressStep =
                  deliveryDataIds.isEmpty
                      ? 0.40
                      : 0.40 / (deliveryDataIds.length * 3);

              for (int i = 0; i < deliveryDataIds.length; i++) {
                final deliveryDataId = deliveryDataIds[i];
                debugPrint(
                  '🔄 Loading data for delivery: $deliveryDataId (${i + 1}/${deliveryDataIds.length})',
                );

                // Customer Data (45-60%)
                final customerDataBloc = context.read<CustomerDataBloc>();
                customerDataBloc.add(
                  GetCustomersByDeliveryIdEvent(deliveryDataId),
                );
                _updateProgress(baseProgress + (i * 3 + 1) * progressStep);

                // Invoice Data (60-75%)
                final invoiceDataBloc = context.read<InvoiceDataBloc>();
                invoiceDataBloc.add(
                  GetInvoiceDataByDeliveryIdEvent(deliveryDataId),
                );
                _updateProgress(baseProgress + (i * 3 + 2) * progressStep);

                // Wait for invoice data to load invoice items
                StreamSubscription? invoiceDataSubscription;
                invoiceDataSubscription = invoiceDataBloc.stream.listen((
                  invoiceState,
                ) {
                  if (invoiceState is InvoiceDataByDeliveryLoaded) {
                    debugPrint(
                      '✅ Loaded ${invoiceState.invoiceData.length} invoices for delivery: $deliveryDataId',
                    );

                    // Load invoice items for each invoice
                    final invoiceItemsBloc = context.read<InvoiceItemsBloc>();
                    for (var invoiceData in invoiceState.invoiceData) {
                      if (invoiceData.id != null) {
                        debugPrint(
                          '🔄 Loading invoice items for invoice: ${invoiceData.id}',
                        );
                        invoiceItemsBloc.add(
                          GetInvoiceItemsByInvoiceDataIdEvent(invoiceData.id!),
                        );
                        invoiceItemsBloc.add(
                          GetLocalInvoiceItemsByInvoiceDataIdEvent(
                            invoiceData.id!,
                          ),
                        );
                      }
                    }

                    invoiceDataSubscription?.cancel();
                  }
                });

                _updateProgress(baseProgress + (i * 3 + 3) * progressStep);
              }

              // If no delivery data, still update progress
              if (deliveryDataIds.isEmpty) {
                _updateProgress(0.85);
              }
            }
          });

          // Add a timeout to ensure we don't get stuck waiting for delivery data
          Future.delayed(const Duration(seconds: 10), () {
            if (!deliveryDataSynced) {
              // CHANGED: use renamed variable
              debugPrint('⚠️ Timeout waiting for delivery data to sync');
              deliveryDataSubscription?.cancel();
              _updateProgress(0.85); // Move to completion anyway
            }
          });

          // === PHASE 3: COMPLETION (90-100%) ===

          // Complete the sync after a delay to ensure all data is loaded
          Future.delayed(const Duration(seconds: 3), () {
            _updateProgress(0.95);

            // Final completion
            Future.delayed(const Duration(seconds: 1), () {
              debugPrint(
                '✅ Sync complete for trip: ${state.trip.tripNumberId}',
              );
              _updateProgress(1.0);
              completer.complete(true);
              subscription?.cancel();
            });
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

    // Get new entity BLoCs
    final deliveryTeamBloc = context.read<DeliveryTeamBloc>();
    final deliveryDataBloc = context.read<DeliveryDataBloc>();
    final collectionsBloc = context.read<CollectionsBloc>();
    final cancelledInvoiceBloc = context.read<CancelledInvoiceBloc>();
    final deliveryVehicleBloc = context.read<DeliveryVehicleBloc>();
    final endTripChecklistBloc = context.read<EndTripChecklistBloc>();
    final customerDataBloc = context.read<CustomerDataBloc>();
    final invoiceDataBloc = context.read<InvoiceDataBloc>();
    final invoiceItemsBloc = context.read<InvoiceItemsBloc>();
    // Add this in the refreshScreen method after the existing BLoC refreshes
// User Performance refresh


    // Refresh trip data first
    tripBloc.add(const GetTripEvent());

    if (tripState is TripLoaded && tripState.trip.id != null) {
      final tripId = tripState.trip.id!;
      debugPrint('🔄 Refreshing data for trip: $tripId');

      // === PHASE 1: TRIP-LEVEL DATA REFRESH ===

      // Delivery Team
      deliveryTeamBloc.add(LoadDeliveryTeamEvent(tripId));

      // Delivery Data (Core data needed for dependencies)
      deliveryDataBloc
        ..add(GetDeliveryDataByTripIdEvent(tripId))
        ..add(GetLocalDeliveryDataByTripIdEvent(tripId));

      // Collections
      collectionsBloc
        ..add(GetCollectionsByTripIdEvent(tripId))
        ..add(GetLocalCollectionsByTripIdEvent(tripId));

      // Cancelled Invoices
      cancelledInvoiceBloc
        ..add(LoadCancelledInvoicesByTripIdEvent(tripId))
        ..add(LoadLocalCancelledInvoicesByTripIdEvent(tripId));

      // Delivery Vehicle Data
      deliveryVehicleBloc.add(LoadDeliveryVehiclesByTripIdEvent(tripId));

      // End Trip Checklist
      endTripChecklistBloc
        ..add(LoadEndTripChecklistEvent(tripId))
        ..add(LoadLocalEndTripChecklistEvent(tripId));

      // === PHASE 2: DELIVERY DATA DEPENDENT REFRESH ===

      // Listen for delivery data to load dependent data
      StreamSubscription? deliveryDataSubscription;
      deliveryDataSubscription = deliveryDataBloc.stream.listen((state) {
        if (state is DeliveryDataByTripLoaded) {
          debugPrint(
            '🔄 Refreshing delivery-dependent data for ${state.deliveryData.length} deliveries',
          );

          // Extract delivery data IDs
          final deliveryDataIds =
              state.deliveryData
                  .where(
                    (deliveryData) =>
                        deliveryData.id != null && deliveryData.id!.isNotEmpty,
                  )
                  .map((deliveryData) => deliveryData.id!)
                  .toList();

          // Refresh data for each delivery
          for (final deliveryDataId in deliveryDataIds) {
            debugPrint('🔄 Refreshing data for delivery: $deliveryDataId');

            // Customer Data
            customerDataBloc.add(GetCustomersByDeliveryIdEvent(deliveryDataId));

            // Invoice Data
            invoiceDataBloc.add(
              GetInvoiceDataByDeliveryIdEvent(deliveryDataId),
            );
          }

          deliveryDataSubscription?.cancel();
        }
      });

      // === PHASE 3: INVOICE ITEMS DEPENDENT REFRESH ===

      // Listen for invoice data to load invoice items
      StreamSubscription? invoiceDataSubscription;
      invoiceDataSubscription = invoiceDataBloc.stream.listen((state) {
        if (state is InvoiceDataByDeliveryLoaded) {
          debugPrint(
            '🔄 Refreshing invoice items for ${state.invoiceData.length} invoices',
          );

          // Load invoice items for each invoice
          for (var invoiceData in state.invoiceData) {
            if (invoiceData.id != null) {
              debugPrint(
                '🔄 Refreshing invoice items for invoice: ${invoiceData.id}',
              );
              invoiceItemsBloc
                ..add(GetInvoiceItemsByInvoiceDataIdEvent(invoiceData.id!))
                ..add(
                  GetLocalInvoiceItemsByInvoiceDataIdEvent(invoiceData.id!),
                );
            }
          }

          invoiceDataSubscription?.cancel();
        }
      });

      // Add timeout to prevent hanging subscriptions
      Future.delayed(const Duration(seconds: 5), () {
        deliveryDataSubscription?.cancel();
        invoiceDataSubscription?.cancel();
      });
    } else {
      debugPrint('⚠️ No trip loaded or trip ID is null');
    }

    debugPrint('✅ Screen refresh initiated');
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
