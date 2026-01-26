import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/return_items/domain/usecases/get_return_items_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/return_items/domain/usecases/add_items_to_return_items_by_delivery_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/return_items/presentation/bloc/return_items_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/return_items/presentation/bloc/return_items_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/return_items/data/repo/return_items_repo_impl.dart';

import '../../domain/usecases/get_return_items_by_id.dart';

class ReturnItemsBloc extends Bloc<ReturnItemsEvent, ReturnItemsState> {
  final GetReturnItemsByTripId _getReturnItemsByTripId;
  final GetReturnItemById _getReturnItemById;
  final AddItemsToReturnItemsByDeliveryId _addItemsToReturnItemsByDeliveryId;
  final ReturnItemsRepoImpl _returnItemsRepo;

  ReturnItemsBloc({
    required GetReturnItemsByTripId getReturnItemsByTripId,
    required GetReturnItemById getReturnItemById,
    required AddItemsToReturnItemsByDeliveryId addItemsToReturnItemsByDeliveryId,
    required ReturnItemsRepoImpl returnItemsRepo,
  })  : _getReturnItemsByTripId = getReturnItemsByTripId,
        _getReturnItemById = getReturnItemById,
        _addItemsToReturnItemsByDeliveryId = addItemsToReturnItemsByDeliveryId,
        _returnItemsRepo = returnItemsRepo,
        super(const ReturnItemsInitial()) {
    on<GetReturnItemsByTripIdEvent>(_onGetReturnItemsByTripId);
    on<LoadLocalReturnItemsByTripIdEvent>(_onLoadLocalReturnItemsByTripId);
    on<GetReturnItemByIdEvent>(_onGetReturnItemById);
    on<GetReturnItemByLocalIdEvent>(_onGetReturnItemByLocalId);
    on<AddItemsToReturnItemsByDeliveryIdEvent>(_onAddItemsToReturnItemsByDeliveryId);
    on<SyncReturnItemsForTripEvent>(_onSyncReturnItemsForTrip);
   
  }

  Future<void> _onGetReturnItemsByTripId(
    GetReturnItemsByTripIdEvent event,
    Emitter<ReturnItemsState> emit,
  ) async {
    debugPrint('🔄 BLOC: Fetching return items for trip ID: ${event.tripId}');
    emit(const ReturnItemsLoading());

    final result = await _getReturnItemsByTripId(event.tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get return items: ${failure.message}');
        emit(ReturnItemsError(failure.message));
      },
      (returnItems) {
        debugPrint('✅ BLOC: Successfully retrieved ${returnItems.length} return items');
        if (returnItems.isEmpty) {
          emit(const ReturnItemsEmpty('No return items found for this trip'));
        } else {
          emit(ReturnItemsLoaded(returnItems));
        }
      },
    );
  }

  Future<void> _onLoadLocalReturnItemsByTripId(
    LoadLocalReturnItemsByTripIdEvent event,
    Emitter<ReturnItemsState> emit,
  ) async {
    debugPrint('📱 BLOC: Loading local return items for trip ID: ${event.tripId}');
    emit(const ReturnItemsLoading());

    final result = await _getReturnItemsByTripId.loadFromLocal(event.tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to load local return items: ${failure.message}');
        emit(ReturnItemsError(failure.message));
      },
      (returnItems) {
        debugPrint('✅ BLOC: Successfully loaded ${returnItems.length} local return items');
        if (returnItems.isEmpty) {
          emit(const ReturnItemsEmpty('No return items found in local storage'));
        } else {
          emit(LocalReturnItemsLoaded(returnItems));
        }
      },
    );
  }

  Future<void> _onGetReturnItemById(
    GetReturnItemByIdEvent event,
    Emitter<ReturnItemsState> emit,
  ) async {
    debugPrint('🔄 BLOC: Fetching return item with ID: ${event.returnItemId}');
    emit(const ReturnItemsLoading());

    final result = await _getReturnItemById(event.returnItemId);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get return item: ${failure.message}');
        emit(ReturnItemsError(failure.message));
      },
      (returnItem) {
        debugPrint('✅ BLOC: Successfully retrieved return item: ${returnItem.id}');
        emit(ReturnItemLoaded(returnItem));
      },
    );
  }

  Future<void> _onGetReturnItemByLocalId(
    GetReturnItemByLocalIdEvent event,
    Emitter<ReturnItemsState> emit,
  ) async {
    debugPrint('📱 BLOC: Loading local return item with ID: ${event.returnItemId}');
    emit(const ReturnItemsLoading());

    final result = await _getReturnItemById.loadFromLocal(event.returnItemId);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to load local return item: ${failure.message}');
        emit(ReturnItemsError(failure.message));
      },
      (returnItem) {
        debugPrint('✅ BLOC: Successfully loaded local return item: ${returnItem.id}');
        emit(LocalReturnItemLoaded(returnItem));
      },
    );
  }

  Future<void> _onAddItemsToReturnItemsByDeliveryId(
    AddItemsToReturnItemsByDeliveryIdEvent event,
    Emitter<ReturnItemsState> emit,
  ) async {
    debugPrint('🔄 BLOC: Adding return item to delivery ID: ${event.deliveryId}');
    emit(const ReturnItemsLoading());

    final params = AddReturnItemsParams(
      deliveryId: event.deliveryId,
      returnItem: event.returnItem,
    );

    final result = await _addItemsToReturnItemsByDeliveryId(params);
    
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to add return item: ${failure.message}');
        emit(ReturnItemsError(failure.message));
      },
      (returnItem) {
        debugPrint('✅ BLOC: Successfully added return item: ${returnItem.id}');
        emit(ReturnItemAdded(returnItem));
      },
    );
  }

  Future<void> _onSyncReturnItemsForTrip(
    SyncReturnItemsForTripEvent event,
    Emitter<ReturnItemsState> emit,
  ) async {
    debugPrint('🔄 BLOC: Syncing return items for trip: ${event.tripId}');
    emit(const ReturnItemsLoading());

    try {
      await _returnItemsRepo.syncReturnItemsForTrip(event.tripId);
      debugPrint('✅ BLOC: Successfully synced return items for trip: ${event.tripId}');
           emit(ReturnItemsSynced(event.tripId));
    } catch (e) {
      debugPrint('❌ BLOC: Failed to sync return items for trip: ${e.toString()}');
      emit(ReturnItemsError('Failed to sync return items: ${e.toString()}'));
    }
  }


  /// Helper method to refresh return items for a trip
  void refreshReturnItemsForTrip(String tripId) {
    debugPrint('🔄 BLOC: Refreshing return items for trip: $tripId');
    add(GetReturnItemsByTripIdEvent(tripId));
  }

  /// Helper method to load return items from local storage only
  void loadLocalReturnItems(String tripId) {
    debugPrint('📱 BLOC: Loading return items from local storage for trip: $tripId');
    add(LoadLocalReturnItemsByTripIdEvent(tripId));
  }

  /// Helper method to sync and then load return items
  void syncAndLoadReturnItems(String tripId) {
    debugPrint('🔄 BLOC: Syncing and loading return items for trip: $tripId');
    add(SyncReturnItemsForTripEvent(tripId));
    // After sync, load the updated data
    Future.delayed(const Duration(milliseconds: 500), () {
      add(LoadLocalReturnItemsByTripIdEvent(tripId));
    });
  }

  /// Helper method to add return item and refresh the list
  void addReturnItemAndRefresh(String deliveryId, String tripId, dynamic returnItem) {
    debugPrint('🔄 BLOC: Adding return item and refreshing list');
    add(AddItemsToReturnItemsByDeliveryIdEvent(
      deliveryId: deliveryId,
      returnItem: returnItem,
    ));
    // After adding, refresh the list
    Future.delayed(const Duration(milliseconds: 500), () {
      add(GetReturnItemsByTripIdEvent(tripId));
    });
  }

  /// Helper method to check if return items are loaded
  bool get hasReturnItemsLoaded {
    return state is ReturnItemsLoaded || 
           state is LocalReturnItemsLoaded ||
           state is ReturnItemsEmpty;
  }

  /// Helper method to get current return items
  List<dynamic> get currentReturnItems {
    if (state is ReturnItemsLoaded) {
      return (state as ReturnItemsLoaded).returnItems;
    } else if (state is LocalReturnItemsLoaded) {
      return (state as LocalReturnItemsLoaded).returnItems;
    }
    return [];
  }

  /// Helper method to get current return item
  dynamic get currentReturnItem {
    if (state is ReturnItemLoaded) {
      return (state as ReturnItemLoaded).returnItem;
    } else if (state is LocalReturnItemLoaded) {
      return (state as LocalReturnItemLoaded).returnItem;
    } else if (state is ReturnItemAdded) {
      return (state as ReturnItemAdded).returnItem;
    }
    return null;
  }

  /// Helper method to check if currently loading
  bool get isLoading => state is ReturnItemsLoading;

  /// Helper method to check if there's an error
  bool get hasError => state is ReturnItemsError;

  /// Helper method to get error message
  String get errorMessage {
    if (state is ReturnItemsError) {
      return (state as ReturnItemsError).message;
    }
    return '';
  }

  /// Helper method to check if return items are empty
  bool get isEmpty => state is ReturnItemsEmpty;

  /// Helper method to get empty message
  String get emptyMessage {
    if (state is ReturnItemsEmpty) {
      return (state as ReturnItemsEmpty).message;
    }
    return '';
  }

  /// Helper method to get cache statistics
  Map<String, dynamic> get cacheStats {
    if (state is ReturnItemsCacheStatsLoaded) {
      return (state as ReturnItemsCacheStatsLoaded).stats;
    }
    return {};
  }

  /// Helper method to get return items count
  int get returnItemsCount {
    if (state is ReturnItemsCountLoaded) {
      return (state as ReturnItemsCountLoaded).count;
    }
    return 0;
  }

  /// Helper method to reset to initial state
  void reset() {
    debugPrint('🔄 BLOC: Resetting to initial state');
    emit(const ReturnItemsInitial());
  }

  /// Helper method to handle offline scenarios
  void handleOfflineMode(String tripId) {
    debugPrint('📱 BLOC: Handling offline mode for trip: $tripId');
    add(LoadLocalReturnItemsByTripIdEvent(tripId));
  }

  /// Helper method to handle online scenarios
  void handleOnlineMode(String tripId) {
    debugPrint('🌐 BLOC: Handling online mode for trip: $tripId');
    add(GetReturnItemsByTripIdEvent(tripId));
  }
}

