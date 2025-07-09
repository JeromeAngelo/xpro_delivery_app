import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/collection/presentation/bloc/collections_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/presentation/bloc/invoice_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/presentation/bloc/invoice_items_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/presentation/bloc/delivery_team_event.dart';

import '../../../../../../src/auth/presentation/bloc/auth_bloc.dart';
import '../../../../../../src/auth/presentation/bloc/auth_event.dart';
import '../../../../../../src/auth/presentation/bloc/auth_state.dart';
import '../../../../../services/injection_container.dart';
import '../../../../../services/objectbox.dart';
import '../../Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart';
import '../../Trip_Ticket/collection/presentation/bloc/collections_bloc.dart';
import '../../Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import '../../Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import '../../Trip_Ticket/delivery_vehicle_data/presentation/bloc/delivery_vehicle_bloc.dart';
import '../../Trip_Ticket/invoice_data/presentation/bloc/invoice_data_bloc.dart';
import '../../Trip_Ticket/invoice_data/presentation/bloc/invoice_data_state.dart';
import '../../Trip_Ticket/invoice_items/presentation/bloc/invoice_items_bloc.dart';
import '../../Trip_Ticket/invoice_items/presentation/bloc/invoice_items_state.dart';
import '../../Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import '../../Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import '../../Trip_Ticket/trip/presentation/bloc/trip_state.dart';
import '../../delivery_team/delivery_team/presentation/bloc/delivery_team_bloc.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  SyncCubit() : super(const SyncInitial());

  final store = sl<ObjectBoxStore>();
  final _pocketBaseClient = sl<PocketBase>();
  
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

  StreamSubscription? _authSubscription;
  StreamSubscription? _deliveryDataSubscription;

  // Handle checking user trip
  Future<void> checkUserTrip(BuildContext context) async {
    try {
      emit(const CheckingTrip());
      debugPrint('🔄 SyncCubit: Starting user data sync process');

      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('user_data');
      final authBloc = context.read<AuthBloc>();

      if (storedData == null) {
        debugPrint('⚠️ SyncCubit: No stored user data found, initiating sync');
        emit(const SyncingAuthData());

        final completer = Completer<bool>();
        
        _authSubscription?.cancel();
        _authSubscription = authBloc.stream.listen((state) {
          debugPrint('🔄 SyncCubit: Auth State: $state');

          if (state is RemoteUserDataLoaded) {
            debugPrint('✅ SyncCubit: Remote user data fetched');
            authBloc.add(GetUserTripEvent(state.user.id!));
          } else if (state is UserDataSynced) {
            debugPrint('✅ SyncCubit: User data synced to local storage');
            emit(const AuthDataSynced());
            authBloc.add(const LoadLocalUserDataEvent());
          } else if (state is UserTripLoaded) {
            if (state.trip.id != null &&
                state.trip.isAccepted == true &&
                state.trip.isEndTrip != true) {
              debugPrint('✅ SyncCubit: Active trip found: ${state.trip.id}');
              emit(TripFound(
                tripId: state.trip.id!,
                tripNumber: state.trip.tripNumberId ?? 'Unknown',
              ));
              completer.complete(true);
            } else {
              debugPrint('⚠️ SyncCubit: Found trip is not active or valid');
              emit(const NoTripFound());
              completer.complete(false);
            }
            _authSubscription?.cancel();
          } else if (state is AuthError) {
            debugPrint('❌ SyncCubit: Error during sync: ${state.message}');
            emit(SyncError(message: state.message));
            completer.complete(false);
            _authSubscription?.cancel();
          }
        });

        authBloc.add(const LoadRemoteUserDataEvent());
        await completer.future;
        return;
      }

      // Parse stored user data
      String? userId;
      String? tripId;

      try {
        final Map<String, dynamic> userData = Map<String, dynamic>.from(
          jsonDecode(storedData),
        );
        userId = userData['id']?.toString();

        if (userData.containsKey('trip') && userData['trip'] != null) {
          final tripData = userData['trip'];
          if (tripData is Map && tripData.containsKey('id')) {
            tripId = tripData['id']?.toString();
          }
        }

        debugPrint('👤 SyncCubit: Found user ID: $userId');
        debugPrint('🎫 SyncCubit: Found trip ID in preferences: $tripId');
      } catch (e) {
        debugPrint('⚠️ SyncCubit: Failed to parse user data: $e');
        emit(const SyncError(message: 'Failed to parse user data'));
        return;
      }

      if (userId == null) {
        debugPrint('⚠️ SyncCubit: No valid user ID found in stored data');
        emit(const SyncError(message: 'No valid user ID found'));
        return;
      }

      final completer = Completer<bool>();
      
      _authSubscription?.cancel();
      _authSubscription = authBloc.stream.listen((state) async {
        debugPrint('🔄 SyncCubit: Auth State: $state');

        if (state is LocalUserDataLoaded) {
          debugPrint('✅ SyncCubit: User data loaded from local storage');
          emit(const AuthDataSynced());
          authBloc.add(const LoadRemoteUserDataEvent());
        } else if (state is RemoteUserDataLoaded) {
          debugPrint('✅ SyncCubit: Remote user data synced');
          authBloc.add(GetUserTripEvent(userId!));
        } else if (state is UserTripLoaded) {
          if (state.trip.id != null &&
              state.trip.isAccepted == true &&
              state.trip.isEndTrip != true) {
            debugPrint('✅ SyncCubit: Active trip confirmed from server: ${state.trip.id}');
            emit(TripFound(
              tripId: state.trip.id!,
              tripNumber: state.trip.tripNumberId ?? 'Unknown',
            ));
            completer.complete(true);
          } else {
            debugPrint('⚠️ SyncCubit: Server indicates no active trip for this user');
            if (tripId != null) {
              await _clearInvalidTripData();
            }
            emit(const NoTripFound());
            completer.complete(false);
          }
          _authSubscription?.cancel();
        } else if (state is AuthError) {
          debugPrint('❌ SyncCubit: No active trip found: ${state.message}');
          if (tripId != null) {
            await _clearInvalidTripData();
          }
          emit(const NoTripFound());
          completer.complete(false);
          _authSubscription?.cancel();
        }
      });

      debugPrint('🔄 SyncCubit: Starting user data sync chain');
      authBloc.add(const LoadLocalUserDataEvent());
      await completer.future;

    } catch (e) {
      debugPrint('❌ SyncCubit: Error checking user trip: $e');
      emit(SyncError(message: 'Error checking user trip: $e'));
    }
  }

  // Handle starting sync process
  Future<void> startSyncProcess(BuildContext context) async {
    if (_isSyncing) {
      debugPrint('⚠️ SyncCubit: Sync already in progress, skipping');
      return;
    }

    try {
      _isSyncing = true;
      emit(const SyncLoading());
      debugPrint('🔄 SyncCubit: Starting comprehensive sync process');

      // Get current trip data
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('user_data');
      
      if (storedData == null) {
        emit(const SyncError(message: 'No user data found'));
        return;
      }

      final userData = jsonDecode(storedData);
      final tripData = userData['trip'];
      
      if (tripData == null || tripData['id'] == null) {
        emit(const SyncError(message: 'No active trip found'));
        return;
      }

      final tripId = tripData['id'].toString();
      debugPrint('🎫 SyncCubit: Syncing data for trip: $tripId');

      // Step 1: Sync Trip Data
      await _syncTripData(context, tripId);

      // Step 2: Sync Delivery Data
      await _syncDeliveryData(context, tripId);

      // Step 3: Sync Dependent Data (based on delivery data)
      await _syncDependentData(context, tripId);

      // Step 4: Process pending operations
      await _processPendingOperations();

      // Update last sync time
      _lastSyncTime = DateTime.now();
      await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());

      emit(const SyncCompleted());
      debugPrint('✅ SyncCubit: Sync process completed successfully');

    } catch (e) {
      debugPrint('❌ SyncCubit: Sync process failed: $e');
      emit(SyncError(message: 'Sync failed: $e'));
    } finally {
      _isSyncing = false;
    }
  }

  // Sync trip data
  Future<void> _syncTripData(BuildContext context, String tripId) async {
    try {
      emit(const SyncingTripData(progress: 0.1, statusMessage: 'Loading trip data...'));
      
      final tripBloc = context.read<TripBloc>();
      final completer = Completer<void>();
      
      StreamSubscription? subscription;
      subscription = tripBloc.stream.listen((state) {
        if (state is TripLoaded) {
          debugPrint('✅ SyncCubit: Trip data synced');
          subscription?.cancel();
          completer.complete();
        } else if (state is TripError) {
          debugPrint('❌ SyncCubit: Trip sync failed: ${state.message}');
          subscription?.cancel();
          completer.completeError(state.message);
        }
      });

      tripBloc.add(GetTripByIdEvent(tripId));
      await completer.future;

      emit(const SyncingTripData(progress: 0.3, statusMessage: 'Loading delivery team...'));
      
      final deliveryTeamBloc = context.read<DeliveryTeamBloc>();
      deliveryTeamBloc.add(LoadDeliveryTeamByIdEvent(tripId));

      emit(const SyncingTripData(progress: 1.0, statusMessage: 'Trip data synchronized'));
      
    } catch (e) {
      throw Exception('Failed to sync trip data: $e');
    }
  }

  // Sync delivery data
  Future<void> _syncDeliveryData(BuildContext context, String tripId) async {
    try {
      emit(const SyncingDeliveryData(progress: 0.1, statusMessage: 'Loading delivery data...'));
      
      final deliveryDataBloc = context.read<DeliveryDataBloc>();
      final completer = Completer<void>();
      
      StreamSubscription? subscription;
      subscription = deliveryDataBloc.stream.listen((state) {
        if (state is DeliveryDataLoaded) {
          debugPrint('✅ SyncCubit: Delivery data synced (${state.deliveryData.id} items)');
          subscription?.cancel();
          completer.complete();
        } else if (state is DeliveryDataError) {
          debugPrint('❌ SyncCubit: Delivery data sync failed: ${state.message}');
          subscription?.cancel();
          completer.completeError(state.message);
        }
      });

      deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(tripId));
      await completer.future;

      emit(const SyncingDeliveryData(progress: 0.5, statusMessage: 'Processing delivery items...'));
      
      // Get delivery data for further processing
      final deliveryDataState = deliveryDataBloc.state;
      if (deliveryDataState is DeliveryDataByTripLoaded) {
        final deliveryData = deliveryDataState.deliveryData;
        debugPrint('📦 SyncCubit: Processing ${deliveryData.length} delivery items');
        
        // Process each delivery item
        for (int i = 0; i < deliveryData.length; i++) {
          final progress = 0.5 + (0.5 * (i + 1) / deliveryData.length);
          
          emit(SyncingDeliveryData(
            progress: progress,
            statusMessage: 'Processing delivery ${i + 1}/${deliveryData.length}...',
          ));
          
          // Small delay to show progress
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      emit(const SyncingDeliveryData(progress: 1.0, statusMessage: 'Delivery data synchronized'));
      
    } catch (e) {
      throw Exception('Failed to sync delivery data: $e');
    }
  }

  // Sync dependent data based on delivery data
  Future<void> _syncDependentData(BuildContext context, String tripId) async {
    try {
      emit(const SyncingDependentData(progress: 0.1, statusMessage: 'Loading delivery data for dependent sync...'));
      
      // First get delivery data to use their IDs for dependent data sync
      final deliveryDataBloc = context.read<DeliveryDataBloc>();
      final deliveryDataState = deliveryDataBloc.state;
      
      List<String> deliveryDataIds = [];
      
      if (deliveryDataState is DeliveryDataByTripLoaded) {
        deliveryDataIds = deliveryDataState.deliveryData
            .where((delivery) => delivery.id != null)
            .map((delivery) => delivery.id!)
            .toList();
        debugPrint('📦 SyncCubit: Found ${deliveryDataIds.length} delivery data IDs for dependent sync');
      } else {
        debugPrint('⚠️ SyncCubit: No delivery data loaded, syncing basic dependent data only');
      }

      // Sync invoice data by delivery IDs
      await _syncInvoiceDataByDeliveryIds(context, deliveryDataIds);
      
      // Sync invoice items based on invoice data
      await _syncInvoiceItemsByDeliveryIds(context, deliveryDataIds);
      
      // Sync other dependent data
      await _syncOtherDependentData(context, tripId);

      emit(const SyncingDependentData(progress: 1.0, statusMessage: 'All dependent data synchronized'));
      
    } catch (e) {
      throw Exception('Failed to sync dependent data: $e');
    }
  }

  // Sync invoice data by delivery IDs
  Future<void> _syncInvoiceDataByDeliveryIds(BuildContext context, List<String> deliveryDataIds) async {
    try {
      emit(const SyncingDependentData(progress: 0.2, statusMessage: 'Loading invoice data...'));
      
      final invoiceDataBloc = context.read<InvoiceDataBloc>();
      
      for (int i = 0; i < deliveryDataIds.length; i++) {
        final deliveryId = deliveryDataIds[i];
        final progress = 0.2 + (0.2 * (i + 1) / deliveryDataIds.length);
        
        emit(SyncingDependentData(
          progress: progress,
          statusMessage: 'Loading invoices for delivery ${i + 1}/${deliveryDataIds.length}...',
        ));
        
        debugPrint('📄 SyncCubit: Syncing invoice data for delivery ID: $deliveryId');
        
        final completer = Completer<void>();
        StreamSubscription? subscription;
        
        subscription = invoiceDataBloc.stream.listen((state) {
          if (state is InvoiceDataByDeliveryLoaded) {
            debugPrint('✅ SyncCubit: Invoice data synced for delivery $deliveryId (${state.invoiceData.length} invoices)');
            subscription?.cancel();
            completer.complete();
          } else if (state is InvoiceDataError) {
            debugPrint('❌ SyncCubit: Invoice data sync failed for delivery $deliveryId: ${state.message}');
            subscription?.cancel();
            completer.complete(); // Continue with other deliveries even if one fails
          }
        });

        invoiceDataBloc.add(GetInvoiceDataByDeliveryIdEvent(deliveryId));
        await completer.future;
        
        // Small delay between requests
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      debugPrint('✅ SyncCubit: All invoice data synced for ${deliveryDataIds.length} deliveries');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Error syncing invoice data by delivery IDs: $e');
      throw Exception('Failed to sync invoice data: $e');
    }
  }

  // Sync invoice items by delivery IDs
  Future<void> _syncInvoiceItemsByDeliveryIds(BuildContext context, List<String> deliveryDataIds) async {
    try {
      emit(const SyncingDependentData(progress: 0.4, statusMessage: 'Loading invoice items...'));
      
      final invoiceItemsBloc = context.read<InvoiceItemsBloc>();
      final invoiceDataBloc = context.read<InvoiceDataBloc>();
      
      // Get all invoice data IDs from the loaded invoice data
      final invoiceDataState = invoiceDataBloc.state;
      List<String> invoiceDataIds = [];
      
      if (invoiceDataState is InvoiceDataByDeliveryLoaded) {
        invoiceDataIds = invoiceDataState.invoiceData
            .where((invoice) => invoice.id != null)
            .map((invoice) => invoice.id!)
            .toList();
        debugPrint('📋 SyncCubit: Found ${invoiceDataIds.length} invoice data IDs for items sync');
      }
      
      for (int i = 0; i < invoiceDataIds.length; i++) {
        final invoiceDataId = invoiceDataIds[i];
        final progress = 0.4 + (0.2 * (i + 1) / invoiceDataIds.length);
        
        emit(SyncingDependentData(
          progress: progress,
          statusMessage: 'Loading items for invoice ${i + 1}/${invoiceDataIds.length}...',
        ));
        
        debugPrint('📦 SyncCubit: Syncing invoice items for invoice data ID: $invoiceDataId');
        
        final completer = Completer<void>();
        StreamSubscription? subscription;
        
        subscription = invoiceItemsBloc.stream.listen((state) {
          if (state is InvoiceItemsByInvoiceDataIdLoaded) {
            debugPrint('✅ SyncCubit: Invoice items synced for invoice $invoiceDataId (${state.invoiceItems.length} items)');
            subscription?.cancel();
            completer.complete();
          } else if (state is InvoiceItemsError) {
            debugPrint('❌ SyncCubit: Invoice items sync failed for invoice $invoiceDataId: ${state.message}');
            subscription?.cancel();
            completer.complete(); // Continue with other invoices even if one fails
          }
        });

        invoiceItemsBloc.add(GetInvoiceItemsByInvoiceDataIdEvent(invoiceDataId));
        await completer.future;
        
        // Small delay between requests
        await Future.delayed(const Duration(milliseconds: 150));
      }
      
      debugPrint('✅ SyncCubit: All invoice items synced for ${invoiceDataIds.length} invoices');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Error syncing invoice items: $e');
      throw Exception('Failed to sync invoice items: $e');
    }
  }

  // Sync other dependent data
  Future<void> _syncOtherDependentData(BuildContext context, String tripId) async {
    try {
      emit(const SyncingDependentData(progress: 0.6, statusMessage: 'Loading cancelled invoices...'));
      
      final cancelledInvoiceBloc = context.read<CancelledInvoiceBloc>();
      cancelledInvoiceBloc.add(LoadCancelledInvoicesByTripIdEvent(tripId));

      emit(const SyncingDependentData(progress: 0.7, statusMessage: 'Loading collections...'));
      
      final collectionsBloc = context.read<CollectionsBloc>();
      collectionsBloc.add(GetCollectionsByTripIdEvent(tripId));

     

      emit(const SyncingDependentData(progress: 0.9, statusMessage: 'Loading delivery vehicle data...'));
      
      final deliveryVehicleBloc = context.read<DeliveryVehicleBloc>();
      deliveryVehicleBloc.add(LoadDeliveryVehiclesByTripIdEvent(tripId));

    
     

      debugPrint('✅ SyncCubit: All other dependent data sync initiated');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Error syncing other dependent data: $e');
      throw Exception('Failed to sync other dependent data: $e');
    }
  }

  // Sync specific delivery data by ID
  Future<void> syncDeliveryDataById(BuildContext context, String deliveryDataId) async {
    try {
      debugPrint('🔄 SyncCubit: Syncing specific delivery data: $deliveryDataId');
      
      emit(const SyncingDeliveryData(progress: 0.1, statusMessage: 'Loading specific delivery data...'));
      
      // Sync invoice data for this specific delivery
      await _syncInvoiceDataByDeliveryIds(context, [deliveryDataId]);
      
      // Sync invoice items for this delivery
      await _syncInvoiceItemsByDeliveryIds(context, [deliveryDataId]);
      
      emit(const SyncingDeliveryData(progress: 1.0, statusMessage: 'Delivery data synchronized'));
      
      debugPrint('✅ SyncCubit: Specific delivery data synced: $deliveryDataId');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to sync delivery data by ID: $e');
      emit(SyncError(message: 'Failed to sync delivery data: $e'));
    }
  }

  // Sync multiple delivery data by IDs
  Future<void> syncMultipleDeliveryDataByIds(BuildContext context, List<String> deliveryDataIds) async {
    try {
      debugPrint('🔄 SyncCubit: Syncing multiple delivery data: ${deliveryDataIds.length} items');
      
      emit(const SyncingDeliveryData(progress: 0.1, statusMessage: 'Loading multiple delivery data...'));
      
      // Sync invoice data for these deliveries
      await _syncInvoiceDataByDeliveryIds(context, deliveryDataIds);
      
      // Sync invoice items for these deliveries
      await _syncInvoiceItemsByDeliveryIds(context, deliveryDataIds);
      
      emit(const SyncingDeliveryData(progress: 1.0, statusMessage: 'Multiple delivery data synchronized'));
      
      debugPrint('✅ SyncCubit: Multiple delivery data synced: ${deliveryDataIds.length} items');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to sync multiple delivery data: $e');
      emit(SyncError(message: 'Failed to sync multiple delivery data: $e'));
    }
  }

  // // Refresh delivery data and its dependencies
  // Future<void> refreshDeliveryData(BuildContext context, String deliveryDataId) async {
  //   try {
  //     debugPrint('🔄 SyncCubit: Refreshing delivery data: $deliveryDataId');
      
  //     emit(const SyncingDeliveryData(progress: 0.1, statusMessage: 'Refreshing delivery data...'));
      
  //     // First refresh the delivery data itself
  //     final deliveryDataBloc = context.read<DeliveryDataBloc>();
  //     deliveryDataBloc.add(RefreshDeli(deliveryDataId));
      
  //     // Then sync its dependencies
  //     await syncDeliveryDataById(context, deliveryDataId);
      
  //     debugPrint('✅ SyncCubit: Delivery data refreshed: $deliveryDataId');
      
  //   } catch (e) {
  //     debugPrint('❌ SyncCubit: Failed to refresh delivery data: $e');
  //     emit(SyncError(message: 'Failed to refresh delivery data: $e'));
  //   }
  // }

  // Process pending operations
  Future<void> _processPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOpsJson = prefs.getStringList(_pendingOperationsKey) ?? [];
      
      if (pendingOpsJson.isEmpty) {
        debugPrint('✅ SyncCubit: No pending operations to process');
        return;
      }

      debugPrint('🔄 SyncCubit: Processing ${pendingOpsJson.length} pending operations');
      
      emit(ProcessingPendingOperations(
        totalOperations: pendingOpsJson.length,
        completedOperations: 0,
      ));

      int completed = 0;
      int failed = 0;
      final List<String> remainingOps = [];

      for (int i = 0; i < pendingOpsJson.length; i++) {
        try {
          final opData = jsonDecode(pendingOpsJson[i]);
          await _processSingleOperation(opData);
          completed++;
          
          emit(ProcessingPendingOperations(
            totalOperations: pendingOpsJson.length,
            completedOperations: completed,
          ));
          
        } catch (e) {
          debugPrint('❌ SyncCubit: Failed to process operation: $e');
          failed++;
          remainingOps.add(pendingOpsJson[i]);
        }
      }

      // Update pending operations list
      await prefs.setStringList(_pendingOperationsKey, remainingOps);
           _pendingSyncOperations.clear();
      _pendingSyncOperations.addAll(remainingOps);

      emit(PendingOperationsCompleted(
        processedOperations: completed,
        failedOperations: failed,
      ));

      debugPrint('✅ SyncCubit: Processed $completed operations, $failed failed');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Error processing pending operations: $e');
      throw Exception('Failed to process pending operations: $e');
    }
  }

  // Process single operation
  Future<void> _processSingleOperation(Map<String, dynamic> opData) async {
    final operationType = opData['operation_type'] as String;
    final entityType = opData['entity_type'] as String;
    final entityId = opData['entity_id'] as String;
    final data = opData['data'] as Map<String, dynamic>;

    debugPrint('🔄 SyncCubit: Processing $operationType for $entityType:$entityId');

    switch (operationType) {
      case 'CREATE':
        await _processCreateOperation(entityType, data);
        break;
      case 'UPDATE':
        await _processUpdateOperation(entityType, entityId, data);
        break;
      case 'DELETE':
        await _processDeleteOperation(entityType, entityId);
        break;
      default:
        throw Exception('Unknown operation type: $operationType');
    }
  }

  // Process create operation
  Future<void> _processCreateOperation(String entityType, Map<String, dynamic> data) async {
    try {
      final record = await _pocketBaseClient.collection(entityType).create(body: data);
      debugPrint('✅ SyncCubit: Created $entityType record: ${record.id}');
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to create $entityType: $e');
      rethrow;
    }
  }

  // Process update operation
  Future<void> _processUpdateOperation(String entityType, String entityId, Map<String, dynamic> data) async {
    try {
      final record = await _pocketBaseClient.collection(entityType).update(entityId, body: data);
      debugPrint('✅ SyncCubit: Updated $entityType record: ${record.id}');
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to update $entityType:$entityId: $e');
      rethrow;
    }
  }

  // Process delete operation
  Future<void> _processDeleteOperation(String entityType, String entityId) async {
    try {
      await _pocketBaseClient.collection(entityType).delete(entityId);
      debugPrint('✅ SyncCubit: Deleted $entityType record: $entityId');
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to delete $entityType:$entityId: $e');
      rethrow;
    }
  }

  // Queue operation for later sync
  Future<void> queueOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final operation = {
        'operation_type': operationType,
        'entity_type': entityType,
        'entity_id': entityId,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();
      final pendingOps = prefs.getStringList(_pendingOperationsKey) ?? [];
      pendingOps.add(jsonEncode(operation));
      
      await prefs.setStringList(_pendingOperationsKey, pendingOps);
      _pendingSyncOperations.add(jsonEncode(operation));

      debugPrint('📝 SyncCubit: Queued $operationType operation for $entityType:$entityId');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to queue operation: $e');
      throw Exception('Failed to queue operation: $e');
    }
  }

  // Queue delivery data operation
  Future<void> queueDeliveryDataOperation({
    required String operationType,
    required String deliveryDataId,
    required Map<String, dynamic> data,
  }) async {
    await queueOperation(
      operationType: operationType,
      entityType: 'delivery_data',
      entityId: deliveryDataId,
      data: data,
    );
  }

  // Queue invoice data operation
  Future<void> queueInvoiceDataOperation({
    required String operationType,
    required String invoiceDataId,
    required Map<String, dynamic> data,
  }) async {
    await queueOperation(
      operationType: operationType,
      entityType: 'invoice_data',
      entityId: invoiceDataId,
      data: data,
    );
  }

  // Queue invoice items operation
  Future<void> queueInvoiceItemsOperation({
    required String operationType,
    required String invoiceItemId,
    required Map<String, dynamic> data,
  }) async {
    await queueOperation(
      operationType: operationType,
      entityType: 'invoice_items',
      entityId: invoiceItemId,
      data: data,
    );
  }

  // Sync delivery data with status update
  Future<void> syncDeliveryDataWithStatus(
    BuildContext context,
    String deliveryDataId,
    String status,
  ) async {
    try {
      debugPrint('🔄 SyncCubit: Syncing delivery data with status update: $deliveryDataId -> $status');
      
      emit(const SyncingDeliveryData(progress: 0.1, statusMessage: 'Updating delivery status...'));
      
      // Queue the status update operation
      await queueDeliveryDataOperation(
        operationType: 'UPDATE',
        deliveryDataId: deliveryDataId,
        data: {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      
      // Sync the delivery data and its dependencies
      await syncDeliveryDataById(context, deliveryDataId);
      
      debugPrint('✅ SyncCubit: Delivery data synced with status: $deliveryDataId -> $status');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to sync delivery data with status: $e');
      emit(SyncError(message: 'Failed to sync delivery data with status: $e'));
    }
  }

  // Batch sync delivery data
  Future<void> batchSyncDeliveryData(
    BuildContext context,
    List<Map<String, dynamic>> deliveryUpdates,
  ) async {
    try {
      debugPrint('🔄 SyncCubit: Batch syncing ${deliveryUpdates.length} delivery data updates');
      
      emit(const SyncingDeliveryData(progress: 0.1, statusMessage: 'Batch updating delivery data...'));
      
      final deliveryDataIds = <String>[];
      
      // Queue all operations
      for (int i = 0; i < deliveryUpdates.length; i++) {
        final update = deliveryUpdates[i];
        final deliveryDataId = update['id'] as String;
        final data = Map<String, dynamic>.from(update);
        data.remove('id'); // Remove ID from data
        
        deliveryDataIds.add(deliveryDataId);
        
        await queueDeliveryDataOperation(
          operationType: 'UPDATE',
          deliveryDataId: deliveryDataId,
          data: data,
        );
        
        final progress = 0.1 + (0.4 * (i + 1) / deliveryUpdates.length);
        emit(SyncingDeliveryData(
          progress: progress,
          statusMessage: 'Queued update ${i + 1}/${deliveryUpdates.length}...',
        ));
      }
      
      // Sync all affected delivery data
      await syncMultipleDeliveryDataByIds(context, deliveryDataIds);
      
      debugPrint('✅ SyncCubit: Batch sync completed for ${deliveryUpdates.length} delivery data');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Batch sync failed: $e');
      emit(SyncError(message: 'Batch sync failed: $e'));
    }
  }

  // Refresh data
  Future<void> refreshData(BuildContext context) async {
    try {
      debugPrint('🔄 SyncCubit: Refreshing data');
      await startSyncProcess(context);
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to refresh data: $e');
      emit(SyncError(message: 'Failed to refresh data: $e'));
    }
  }

  // Handle connection restored
  Future<void> onConnectionRestored() async {
    try {
      debugPrint('🌐 SyncCubit: Connection restored, processing pending operations');
      await _processPendingOperations();
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to process operations after connection restore: $e');
      emit(SyncError(message: 'Failed to sync after connection restore: $e'));
    }
  }

  // Clear invalid trip data
  Future<void> _clearInvalidTripData() async {
    try {
      debugPrint('🧹 SyncCubit: Clearing invalid trip data');
      
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('user_data');
      
      if (storedData != null) {
        final userData = Map<String, dynamic>.from(jsonDecode(storedData));
        userData.remove('trip');
        await prefs.setString('user_data', jsonEncode(userData));
        debugPrint('✅ SyncCubit: Invalid trip data cleared from preferences');
      }
      
      // Clear local trip-related data from ObjectBox
      await _clearLocalTripData();
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Error clearing invalid trip data: $e');
    }
  }

  // Clear local trip data from ObjectBox
  Future<void> _clearLocalTripData() async {
    try {
      // Clear all trip-related data from ObjectBox
      debugPrint('🧹 SyncCubit: Clearing local trip data from ObjectBox');
      
      // Example: Clear specific boxes
      // store.box<TripEntity>().removeAll();
      // store.box<DeliveryDataEntity>().removeAll();
      // Add other entities as needed
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Error clearing local trip data: $e');
    }
  }

  // Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'is_syncing': _isSyncing,
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'pending_operations_count': _pendingSyncOperations.length,
      'current_state': state.runtimeType.toString(),
    };
  }

  // Check if sync is needed
  bool isSyncNeeded() {
    if (_lastSyncTime == null) return true;
    
    final now = DateTime.now();
    final timeSinceLastSync = now.difference(_lastSyncTime!);
    
    // Sync if more than 30 minutes have passed
    return timeSinceLastSync.inMinutes > 30 || _pendingSyncOperations.isNotEmpty;
  }

  // Initialize sync service
  Future<void> initialize() async {
    try {
      debugPrint('🔄 SyncCubit: Initializing sync service');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Load last sync time
      final lastSyncString = prefs.getString(_lastSyncKey);
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncString);
      }
      
      // Load pending operations
      final pendingOps = prefs.getStringList(_pendingOperationsKey) ?? [];
      _pendingSyncOperations.clear();
      _pendingSyncOperations.addAll(pendingOps);
      
      debugPrint('✅ SyncCubit: Initialized with ${_pendingSyncOperations.length} pending operations');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to initialize sync service: $e');
    }
  }

  // Force sync
  Future<void> forceSync(BuildContext context) async {
    try {
      debugPrint('🔄 SyncCubit: Force sync requested');
      _lastSyncTime = null; // Reset last sync time to force sync
      await startSyncProcess(context);
    } catch (e) {
      debugPrint('❌ SyncCubit: Force sync failed: $e');
      emit(SyncError(message: 'Force sync failed: $e'));
    }
  }

  // Check network connectivity and sync if needed
  Future<void> checkAndSync(BuildContext context) async {
    try {
      if (!_pocketBaseClient.authStore.isValid) {
        debugPrint('⚠️ SyncCubit: No valid auth token, skipping sync');
        return;
      }

      if (isSyncNeeded()) {
        debugPrint('🔄 SyncCubit: Sync needed, starting sync process');
        await startSyncProcess(context);
      } else {
        debugPrint('✅ SyncCubit: Sync not needed at this time');
      }
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Check and sync failed: $e');
      emit(SyncError(message: 'Sync check failed: $e'));
    }
  }

  // Get pending operations count
  int getPendingOperationsCount() {
    return _pendingSyncOperations.length;
  }

  // Clear all pending operations (use with caution)
  Future<void> clearPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingOperationsKey);
      _pendingSyncOperations.clear();
      debugPrint('🧹 SyncCubit: All pending operations cleared');
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to clear pending operations: $e');
    }
  }

  // Reset sync state
  void resetState() {
    emit(const SyncInitial());
  }

  // Get delivery data sync status
  Map<String, dynamic> getDeliveryDataSyncStatus(String deliveryDataId) {
    final pendingOps = _pendingSyncOperations
        .where((op) {
          try {
            final opData = jsonDecode(op);
            return opData['entity_type'] == 'delivery_data' && 
                   opData['entity_id'] == deliveryDataId;
          } catch (e) {
            return false;
          }
        })
        .toList();

    return {
      'delivery_data_id': deliveryDataId,
      'has_pending_operations': pendingOps.isNotEmpty,
      'pending_operations_count': pendingOps.length,
      'last_sync_time': _lastSyncTime?.toIso8601String(),
    };
  }

   // Get multiple delivery data sync status
  Map<String, dynamic> getMultipleDeliveryDataSyncStatus(List<String> deliveryDataIds) {
    final statusMap = <String, Map<String, dynamic>>{};
    int totalPendingOps = 0;
    
    for (final deliveryDataId in deliveryDataIds) {
      final status = getDeliveryDataSyncStatus(deliveryDataId);
      statusMap[deliveryDataId] = status;
      totalPendingOps += status['pending_operations_count'] as int;
    }

    return {
      'delivery_data_ids': deliveryDataIds,
      'individual_status': statusMap,
      'total_pending_operations': totalPendingOps,
      'all_synced': totalPendingOps == 0,
      'last_sync_time': _lastSyncTime?.toIso8601String(),
    };
  }

  // Sync delivery data with custom callback
  Future<void> syncDeliveryDataWithCallback(
    BuildContext context,
    String deliveryDataId,
    Function(String status, double progress)? onProgress,
    Function(String deliveryDataId)? onComplete,
    Function(String error)? onError,
  ) async {
    try {
      debugPrint('🔄 SyncCubit: Syncing delivery data with callback: $deliveryDataId');
      
      onProgress?.call('Starting sync...', 0.1);
      
      // Sync invoice data
      onProgress?.call('Loading invoice data...', 0.3);
      await _syncInvoiceDataByDeliveryIds(context, [deliveryDataId]);
      
      // Sync invoice items
      onProgress?.call('Loading invoice items...', 0.7);
      await _syncInvoiceItemsByDeliveryIds(context, [deliveryDataId]);
      
      onProgress?.call('Sync completed', 1.0);
      onComplete?.call(deliveryDataId);
      
      debugPrint('✅ SyncCubit: Delivery data synced with callback: $deliveryDataId');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to sync delivery data with callback: $e');
      onError?.call(e.toString());
    }
  }

  // Sync delivery data with retry mechanism
  Future<void> syncDeliveryDataWithRetry(
    BuildContext context,
    String deliveryDataId, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        attempts++;
        debugPrint('🔄 SyncCubit: Sync attempt $attempts/$maxRetries for delivery: $deliveryDataId');
        
        await syncDeliveryDataById(context, deliveryDataId);
        
        debugPrint('✅ SyncCubit: Delivery data synced successfully on attempt $attempts');
        return;
        
      } catch (e) {
        debugPrint('❌ SyncCubit: Sync attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          debugPrint('❌ SyncCubit: All sync attempts failed for delivery: $deliveryDataId');
          emit(SyncError(message: 'Failed to sync delivery data after $maxRetries attempts: $e'));
          rethrow;
        }
        
        if (attempts < maxRetries) {
          debugPrint('⏳ SyncCubit: Waiting ${retryDelay.inSeconds}s before retry...');
          await Future.delayed(retryDelay);
        }
      }
    }
  }

  // Validate delivery data before sync
  Future<bool> validateDeliveryDataBeforeSync(String deliveryDataId) async {
    try {
      debugPrint('🔍 SyncCubit: Validating delivery data before sync: $deliveryDataId');
      
      // Check if delivery data exists in PocketBase
      final record = await _pocketBaseClient.collection('delivery_data').getOne(deliveryDataId);
      
      if (record.id.isEmpty) {
        debugPrint('❌ SyncCubit: Delivery data not found in server: $deliveryDataId');
        return false;
      }
      
      debugPrint('✅ SyncCubit: Delivery data validation passed: $deliveryDataId');
      return true;
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Delivery data validation failed: $e');
      return false;
    }
  }

  // Sync delivery data with validation
  Future<void> syncDeliveryDataWithValidation(
    BuildContext context,
    String deliveryDataId,
  ) async {
    try {
      debugPrint('🔄 SyncCubit: Syncing delivery data with validation: $deliveryDataId');
      
      emit(const SyncingDeliveryData(progress: 0.1, statusMessage: 'Validating delivery data...'));
      
      final isValid = await validateDeliveryDataBeforeSync(deliveryDataId);
      
      if (!isValid) {
        emit(const SyncError(message: 'Delivery data validation failed'));
        return;
      }
      
      await syncDeliveryDataById(context, deliveryDataId);
      
      debugPrint('✅ SyncCubit: Delivery data synced with validation: $deliveryDataId');
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to sync delivery data with validation: $e');
      emit(SyncError(message: 'Failed to sync delivery data with validation: $e'));
    }
  }

  // Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    final now = DateTime.now();
    final timeSinceLastSync = _lastSyncTime != null 
        ? now.difference(_lastSyncTime!).inMinutes 
        : null;

    return {
      'is_syncing': _isSyncing,
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'minutes_since_last_sync': timeSinceLastSync,
      'pending_operations_count': _pendingSyncOperations.length,
      'sync_needed': isSyncNeeded(),
      'current_state': state.runtimeType.toString(),
      'auth_valid': _pocketBaseClient.authStore.isValid,
    };
  }

  // Schedule periodic sync
  Timer? _periodicSyncTimer;
  
  void startPeriodicSync(BuildContext context, {Duration interval = const Duration(minutes: 30)}) {
    _periodicSyncTimer?.cancel();
    
    _periodicSyncTimer = Timer.periodic(interval, (timer) async {
      if (!_isSyncing && _pocketBaseClient.authStore.isValid) {
        debugPrint('⏰ SyncCubit: Periodic sync triggered');
        await checkAndSync(context);
      }
    });
    
    debugPrint('⏰ SyncCubit: Periodic sync started with ${interval.inMinutes} minute interval');
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    debugPrint('⏰ SyncCubit: Periodic sync stopped');
  }



  // Sync with network check
  Future<void> syncWithNetworkCheck(BuildContext context) async {
    try {
      // Simple network check by trying to ping PocketBase
      await _pocketBaseClient.health.check();
      
      debugPrint('🌐 SyncCubit: Network check passed, starting sync');
      await startSyncProcess(context);
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Network check failed: $e');
      emit(const SyncError(message: 'No network connection available'));
    }
  }

  // Get detailed sync report
  Map<String, dynamic> getDetailedSyncReport() {
    final pendingOpsByType = <String, int>{};
    final pendingOpsByEntity = <String, int>{};
    
    for (final opJson in _pendingSyncOperations) {
      try {
        final op = jsonDecode(opJson);
        final opType = op['operation_type'] as String;
        final entityType = op['entity_type'] as String;
        
        pendingOpsByType[opType] = (pendingOpsByType[opType] ?? 0) + 1;
        pendingOpsByEntity[entityType] = (pendingOpsByEntity[entityType] ?? 0) + 1;
      } catch (e) {
        debugPrint('⚠️ SyncCubit: Failed to parse pending operation: $e');
      }
    }

    return {
      'sync_status': getSyncStatistics(),
      'pending_operations_by_type': pendingOpsByType,
      'pending_operations_by_entity': pendingOpsByEntity,
      'total_pending_operations': _pendingSyncOperations.length,
      'periodic_sync_active': _periodicSyncTimer?.isActive ?? false,
    };
  }

  // Clean up old pending operations
  Future<void> cleanupOldPendingOperations({Duration maxAge = const Duration(days: 7)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOps = prefs.getStringList(_pendingOperationsKey) ?? [];
      final now = DateTime.now();
      final validOps = <String>[];
      
      int removedCount = 0;
      
      for (final opJson in pendingOps) {
        try {
          final op = jsonDecode(opJson);
          final timestamp = DateTime.parse(op['timestamp'] as String);
          
          if (now.difference(timestamp) <= maxAge) {
            validOps.add(opJson);
          } else {
            removedCount++;
          }
        } catch (e) {
          // Remove invalid operations
          removedCount++;
        }
      }
      
      if (removedCount > 0) {
        await prefs.setStringList(_pendingOperationsKey, validOps);
        _pendingSyncOperations.clear();
        _pendingSyncOperations.addAll(validOps);
        
        debugPrint('🧹 SyncCubit: Cleaned up $removedCount old pending operations');
      }
      
    } catch (e) {
      debugPrint('❌ SyncCubit: Failed to cleanup old pending operations: $e');
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _deliveryDataSubscription?.cancel();
    _periodicSyncTimer?.cancel();
    return super.close();
  }
}

