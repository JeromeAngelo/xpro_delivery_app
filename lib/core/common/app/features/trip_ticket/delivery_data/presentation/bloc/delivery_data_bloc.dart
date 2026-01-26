import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/usecases/set_invoice_into_completed.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/mixins/offline_first_mixin.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/usecases/calculate_delivery_time_by_delivery_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/usecases/delete_delivery_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/usecases/get_all_delivery_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/usecases/get_delivery_data_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/usecases/get_delivery_data_by_trip_id.dart'
    show GetDeliveryDataByTripId;
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

import '../../domain/entity/delivery_data_entity.dart';
import '../../domain/usecases/set_invoice_into_unloaded.dart';
import '../../domain/usecases/set_invoice_into_unloading.dart';
import '../../domain/usecases/sync_delivery_data_by_trip_id.dart';
import '../../domain/usecases/update_delivery_location.dart';
import '../../domain/usecases/watch_all_local_delivery_data.dart';
import '../../domain/usecases/watch_local_delivery_data_by_id.dart';
import '../../domain/usecases/watch_local_delivery_data_by_trip.dart';

class DeliveryDataBloc extends Bloc<DeliveryDataEvent, DeliveryDataState>
    with OfflineFirstMixin<DeliveryDataEvent, DeliveryDataState> {
  final GetAllDeliveryData _getAllDeliveryData;
  final GetDeliveryDataByTripId _getDeliveryDataByTripId;
  final GetDeliveryDataById _getDeliveryDataById;
  final DeleteDeliveryData _deleteDeliveryData;
  final CalculateDeliveryTimeByDeliveryId _calculateDeliveryTime;
  final SyncDeliveryDataByTripId _syncDeliveryDataByTripId;
  final SetInvoiceIntoUnloading _setInvoiceIntoUnloading;
  final SetInvoiceIntoUnloaded _setInvoiceIntoUnloaded;
  final UpdateDeliveryLocation _updateDeliveryLocation;
  final ConnectivityProvider _connectivity;
  final SetInvoiceIntoCompleted _setInvoiceIntoCompleted;
  final WatchLocalDeliveryDataByTripId _watchLocalDeliveryDataByTripId;
    final WatchLocalDeliveryDataById _watchLocalDeliveryDataById;
    final WatchAllLocalDeliveryData _watchAllLocalDeliveryData;


  DeliveryDataState? _cachedState;

  DeliveryDataBloc({
    required GetAllDeliveryData getAllDeliveryData,
    required SyncDeliveryDataByTripId syncDeliveryDataByTripId,
    required GetDeliveryDataByTripId getDeliveryDataByTripId,
        required WatchLocalDeliveryDataByTripId watchLocalDeliveryDataByTripId,
    required WatchLocalDeliveryDataById watchLocalDeliveryDataById,
    required GetDeliveryDataById getDeliveryDataById,
    required SetInvoiceIntoUnloaded setInvoiceIntoUnloaded,
    required SetInvoiceIntoCompleted setInvoiceIntoCompleted,
    required DeleteDeliveryData deleteDeliveryData,
    required CalculateDeliveryTimeByDeliveryId calculateDeliveryTime,
    required SetInvoiceIntoUnloading setInvoiceIntoUnloading,
    required UpdateDeliveryLocation updateDeliveryLocation,
    required WatchAllLocalDeliveryData watchAllLocalDeliveryData,
    required ConnectivityProvider connectivity,
  }) : _getAllDeliveryData = getAllDeliveryData,
       _getDeliveryDataByTripId = getDeliveryDataByTripId,
       _getDeliveryDataById = getDeliveryDataById,
       _deleteDeliveryData = deleteDeliveryData,
       _watchLocalDeliveryDataByTripId = watchLocalDeliveryDataByTripId,
       _calculateDeliveryTime = calculateDeliveryTime,
       _watchLocalDeliveryDataById = watchLocalDeliveryDataById,
       _syncDeliveryDataByTripId = syncDeliveryDataByTripId,
       _setInvoiceIntoCompleted = setInvoiceIntoCompleted,
       _setInvoiceIntoUnloading = setInvoiceIntoUnloading,
       _setInvoiceIntoUnloaded = setInvoiceIntoUnloaded,
       _updateDeliveryLocation = updateDeliveryLocation,
       _watchAllLocalDeliveryData = watchAllLocalDeliveryData,
       _connectivity = connectivity,
       super(const DeliveryDataInitial()) {
    on<GetAllDeliveryDataEvent>(_onGetAllDeliveryData);
    on<GetDeliveryDataByTripIdEvent>(_onGetDeliveryDataByTripId);
    on<WatchAllDeliveryDataEvent>(_onWatchAllDeliveryData);
    on<GetDeliveryDataByIdEvent>(_onGetDeliveryDataById);
    on<DeleteDeliveryDataEvent>(_onDeleteDeliveryData);
    on<GetLocalDeliveryDataByTripIdEvent>(_onGetLocalDeliveryDataByTripId);
    on<GetLocalDeliveryDataByIdEvent>(_onGetLocalDeliveryDataById);
    on<CalculateDeliveryTimeEvent>(_onCalculateDeliveryTime); // Add this
    on<SyncDeliveryDataByTripIdEvent>(_onSyncDeliveryDataByTripId); // Add this
    on<SetInvoiceIntoUnloadingEvent>(_onSetInvoiceIntoUnloading);
    on<SetInvoiceIntoUnloadedEvent>(_onSetInvoiceIntoUnloaded);
    on<UpdateDeliveryLocationEvent>(_onUpdateDeliveryLocation);
    on<SetInvoiceIntoCompletedEvent>(_onSetInvoiceIntoCompleted);
    on<WatchLocalDeliveryDataByTripIdEvent>(_onWatchLocalDeliveryDataByTripId);
        on<WatchLocalDeliveryDataByIdEvent>(_onWatchLocalDeliveryDataById);

  }
Future<void> _onWatchAllDeliveryData(
  WatchAllDeliveryDataEvent event,
  Emitter<DeliveryDataState> emit,
) async {
  debugPrint('👀 BLOC: Watching all local delivery data');
  emit(const DeliveryDataLoading());

  try {
    // Call the usecase / repo function for watching all local delivery data
    final stream = _watchAllLocalDeliveryData.call();

    await emit.forEach<List<DeliveryDataEntity>>(
      stream,
      onData: (deliveryDataList) {
        debugPrint(
            '📦 BLOC: Received ${deliveryDataList.length} delivery data items from watchAllLocalDeliveryData');
        return AllDeliveryDataWatched(
          deliveryData: deliveryDataList,
        );
      },
      onError: (error, _) {
        debugPrint('❌ BLOC: Watch stream error: $error');
        return DeliveryDataError(
          message: 'Watch error: $error',
          statusCode: '500',
        );
      },
    );
  } catch (e) {
    debugPrint('❌ BLOC: Exception while watching all delivery data: $e');
    emit(
      DeliveryDataError(
        message: e.toString(),
        statusCode: '500',
      ),
    );
  }
}

  Future<void> _onWatchLocalDeliveryDataByTripId(
  WatchLocalDeliveryDataByTripIdEvent event,
  Emitter<DeliveryDataState> emit,
) async {
  debugPrint('👀 BLOC: Watching local delivery data for trip ID: ${event.tripId}');
  emit(const DeliveryDataLoading());

  try {
    final stream = _watchLocalDeliveryDataByTripId.call(event.tripId);

    await emit.forEach<List<DeliveryDataEntity>>(
  stream,
  onData: (deliveryDataList) {
    debugPrint('📦 BLOC: Received ${deliveryDataList.length} delivery data items from local watch');
    return DeliveryDataByTripWatched(
      deliveryData: deliveryDataList,
      tripId: event.tripId,
    );
  },
  onError: (error, _) {
    debugPrint('❌ BLOC: Watch stream error: $error');
    return DeliveryDataError(
      message: 'Watch error: $error',
      statusCode: '500',
    );
  },
);

  } catch (e) {
    debugPrint('❌ BLOC: Exception while watching local delivery data: $e');
    emit(
      DeliveryDataError(
        message: e.toString(),
        statusCode: '500',
      ),
    );
  }
}

Future<void> _onWatchLocalDeliveryDataById(
  WatchLocalDeliveryDataByIdEvent event,
  Emitter<DeliveryDataState> emit,
) async {
  debugPrint('👀 BLOC: Watching local delivery data for ID: ${event.deliveryId}');
  emit(const DeliveryDataLoading());

  try {
    final stream = _watchLocalDeliveryDataById.call(event.deliveryId);

    await emit.forEach<DeliveryDataEntity?>(
      stream,
      onData: (deliveryData) {
        debugPrint('📦 BLOC: Received update for delivery ID: ${event.deliveryId}');
        return DeliveryDataByIdWatched(
          deliveryData: deliveryData,
          deliveryId: event.deliveryId,
        );
      },
      onError: (error, _) {
        debugPrint('❌ BLOC: Watch stream error (by ID): $error');
        return DeliveryDataError(
          message: 'Watch error: $error',
          statusCode: '500',
        );
      },
    );
  } catch (e) {
    debugPrint('❌ BLOC: Exception while watching delivery data by ID: $e');
    emit(
      DeliveryDataError(
        message: e.toString(),
        statusCode: '500',
      ),
    );
  }
}


  // Add this event handler
  Future<void> _onSyncDeliveryDataByTripId(
    SyncDeliveryDataByTripIdEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    debugPrint('🔄 BLOC: Syncing delivery data for trip ID: ${event.tripId}');

    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const DeliveryDataLoading());
    }

    final result = await _syncDeliveryDataByTripId(event.tripId);

    await result.fold(
      (failure) async {
        debugPrint(
          '❌ BLOC: Failed to sync delivery data by trip ID: ${failure.message}',
        );

        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(
            DeliveryDataError(
              message: 'Sync error: ${failure.message}',
              statusCode: failure.statusCode.toString(),
            ),
          );
        }
      },
      (syncedDeliveryData) async {
        debugPrint(
          '✅ BLOC: Successfully synced ${syncedDeliveryData.length} delivery data records for trip ID: ${event.tripId}',
        );

        final newState = DeliveryDataSyncedByTrip(
          deliveryData: syncedDeliveryData,
          tripId: event.tripId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  /// Legacy method - use GetDeliveryDataByTripIdEvent with offline-first pattern instead
  Future<void> _onGetLocalDeliveryDataByTripId(
    GetLocalDeliveryDataByTripIdEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    debugPrint(
      '📱 BLOC: Getting local delivery data for trip ID: ${event.tripId}',
    );

    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const DeliveryDataLoading());
    }

    final result = await _getDeliveryDataByTripId(event.tripId);

    await result.fold(
      (failure) async {
        debugPrint(
          '❌ BLOC: Failed to get local delivery data by trip ID: ${failure.message}',
        );

        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(
            DeliveryDataError(
              message: 'Local data error: ${failure.message}',
              statusCode: failure.statusCode.toString(),
            ),
          );
        }
      },
      (localDeliveryData) async {
        debugPrint(
          '✅ BLOC: Successfully retrieved ${localDeliveryData.length} local delivery data records for trip ID: ${event.tripId}',
        );

        // Verify the data has proper relationships
        for (int i = 0; i < localDeliveryData.length; i++) {
          final delivery = localDeliveryData[i];
          debugPrint('🔍 BLOC Delivery ${i + 1}:');
          debugPrint('   ID: ${delivery.id}');
          debugPrint(
            '   Customer: ${delivery.customer.target?.name ?? 'NULL'}',
          );
          debugPrint('   Invoice: ${delivery.invoice.target?.name ?? 'NULL'}');
          debugPrint('   Payment Mode: ${delivery.paymentMode ?? 'NULL'}');
        }

        final newState = DeliveryDataByTripLoaded(
          deliveryData: localDeliveryData,
          tripId: event.tripId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  // Also fix all other methods in the same file:
  Future<void> _onGetAllDeliveryData(
    GetAllDeliveryDataEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    emit(const DeliveryDataLoading());
    debugPrint('🔄 BLOC: Getting all delivery data');

    final result = await _getAllDeliveryData();
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get delivery data: ${failure.message}');
        emit(
          DeliveryDataError(
            message: failure.message,
            statusCode: failure.statusCode.toString(), // Convert int to String
          ),
        );
      },
      (deliveryData) {
        debugPrint(
          '✅ BLOC: Successfully retrieved ${deliveryData.length} delivery data records',
        );
        final newState = AllDeliveryDataLoaded(deliveryData);
        _cachedState = newState;
        emit(newState);
      },
    );
  }
Future<void> _onGetDeliveryDataByTripId(
  GetDeliveryDataByTripIdEvent event,
  Emitter<DeliveryDataState> emit,
) async {
  debugPrint('🌐 Getting delivery data for trip ID: ${event.tripId}');
  emit(const DeliveryDataLoading());

  final result = await _getDeliveryDataByTripId(event.tripId);

  result.fold(
    (failure) {
      debugPrint('❌ Delivery Data by trip fetch failed: ${failure.message}');
      emit(DeliveryDataError(
        message: failure.message,
        statusCode: failure.statusCode ?? '500',
      ));
    },
    (deliveryData) {
      debugPrint('BLOC: ✅ Delivery data loaded: ${deliveryData.length} items');
      emit(DeliveryDataByTripLoaded(
        deliveryData: deliveryData,
        tripId: event.tripId,
      ));
    },
  );
}

  Future<void> _onGetDeliveryDataById(
    GetDeliveryDataByIdEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    emit(const DeliveryDataLoading());
    debugPrint('🔄 BLOC: Getting delivery data with ID: ${event.id}');

    final result = await _getDeliveryDataById(event.id);
    result.fold(
      (failure) {
        debugPrint(
          '❌ BLOC: Failed to get delivery data by ID: ${failure.message}',
        );
        emit(
          DeliveryDataError(
            message: failure.message,
            statusCode: failure.statusCode.toString(), // Convert int to String
          ),
        );
      },
      (deliveryData) {
        debugPrint(
          '✅ BLOC: Successfully retrieved delivery data with ID: ${event.id}',
        );
        final newState = DeliveryDataLoaded(deliveryData);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onDeleteDeliveryData(
    DeleteDeliveryDataEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    emit(const DeliveryDataLoading());
    debugPrint('🔄 BLOC: Deleting delivery data with ID: ${event.id}');

    final result = await _deleteDeliveryData(event.id);
    result.fold(
      (failure) {
        debugPrint(
          '❌ BLOC: Failed to delete delivery data: ${failure.message}',
        );
        emit(
          DeliveryDataError(
            message: failure.message,
            statusCode: failure.statusCode.toString(), // Convert int to String
          ),
        );
      },
      (success) {
        debugPrint(
          '✅ BLOC: Successfully deleted delivery data with ID: ${event.id}',
        );
        emit(DeliveryDataDeleted(event.id));

        // Optionally refresh the list after deletion
        add(const GetAllDeliveryDataEvent());
      },
    );
  }

  Future<void> _onGetLocalDeliveryDataById(
    GetLocalDeliveryDataByIdEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    debugPrint('📱 BLOC: Getting local delivery data with ID: ${event.id}');
    emit(const DeliveryDataLoading());

    final result = await _getDeliveryDataById.loadFromLocal(event.id);

    await result.fold(
      (failure) async {
        debugPrint(
          '❌ BLOC: Failed to get local delivery data by ID: ${failure.message}',
        );
        emit(
          DeliveryDataError(
            message: failure.message,
            statusCode: failure.statusCode.toString(), // Convert int to String
          ),
        );
      },
      (localDeliveryData) async {
        debugPrint(
          '✅ BLOC: Successfully retrieved local delivery data with ID: ${event.id}',
        );
        emit(DeliveryDataLoaded(localDeliveryData));
      },
    );
  }

  // Add the event handler
  Future<void> _onSetInvoiceIntoUnloading(
    SetInvoiceIntoUnloadingEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    debugPrint(
      '🔄 BLOC: Setting invoice to unloading for delivery data: ${event.deliveryDataId}',
    );

    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const DeliveryDataLoading());
    }

    final result = await _setInvoiceIntoUnloading(event.deliveryDataId);

    await result.fold(
      (failure) async {
        debugPrint(
          '❌ BLOC: Failed to set invoice to unloading: ${failure.message}',
        );

        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(
            DeliveryDataError(
              message: 'Failed to set invoice to unloading: ${failure.message}',
              statusCode: failure.statusCode.toString(),
            ),
          );
        }
      },
      (updatedDeliveryData) async {
        debugPrint(
          '✅ BLOC: Successfully set invoice to unloading for delivery data: ${event.deliveryDataId}',
        );

        final newState = InvoiceSetToUnloading(
          deliveryData: updatedDeliveryData,
          deliveryDataId: event.deliveryDataId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  // Add the event handler
  Future<void> _onSetInvoiceIntoUnloaded(
    SetInvoiceIntoUnloadedEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    debugPrint(
      '🔄 BLOC: Setting invoice to unloading for delivery data: ${event.deliveryDataId}',
    );

    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const DeliveryDataLoading());
    }

    final result = await _setInvoiceIntoUnloaded(event.deliveryDataId);

    await result.fold(
      (failure) async {
        debugPrint(
          '❌ BLOC: Failed to set invoice to unloaded: ${failure.message}',
        );

        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(
            DeliveryDataError(
              message: 'Failed to set invoice to unloaded: ${failure.message}',
              statusCode: failure.statusCode.toString(),
            ),
          );
        }
      },
      (updatedDeliveryData) async {
        debugPrint(
          '✅ BLOC: Successfully set invoice to unloaded for delivery data: ${event.deliveryDataId}',
        );

        final newState = InvoiceSetToUnloaded(
          deliveryData: updatedDeliveryData,
          deliveryDataId: event.deliveryDataId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  // Add this new event handler
  Future<void> _onCalculateDeliveryTime(
    CalculateDeliveryTimeEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    debugPrint(
      '⏱️ BLOC: Calculating delivery time for delivery ID: ${event.deliveryId}',
    );

    // Don't emit loading if we have cached state
    if (_cachedState == null) {
      emit(const DeliveryDataLoading());
    }

    final result = await _calculateDeliveryTime(event.deliveryId);

    await result.fold(
      (failure) async {
        debugPrint(
          '❌ BLOC: Failed to calculate delivery time: ${failure.message}',
        );

        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(
            DeliveryDataError(
              message: 'Delivery time calculation error: ${failure.message}',
              statusCode: failure.statusCode.toString(),
            ),
          );
        }
      },
      (deliveryTimeInMinutes) async {
        debugPrint(
          '✅ BLOC: Successfully calculated delivery time: $deliveryTimeInMinutes minutes for delivery ID: ${event.deliveryId}',
        );

        final newState = DeliveryTimeCalculated(
          deliveryTimeInMinutes: deliveryTimeInMinutes,
          deliveryId: event.deliveryId,
        );

        emit(newState);
      },
    );
  }

  // Add the event handler for updating delivery location
  Future<void> _onUpdateDeliveryLocation(
    UpdateDeliveryLocationEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    debugPrint('🔄 BLOC: Updating delivery location for ID: ${event.id}');
    debugPrint(
      '📍 BLOC: Coordinates: Lat: ${event.latitude}, Long: ${event.longitude}',
    );

    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const DeliveryDataLoading());
    }

    final result = await _updateDeliveryLocation(
      UpdateDeliveryLocationParams(
        id: event.id,
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );

    await result.fold(
      (failure) async {
        debugPrint(
          '❌ BLOC: Failed to update delivery location: ${failure.message}',
        );

        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(
            DeliveryDataError(
              message: 'Failed to update delivery location: ${failure.message}',
              statusCode: failure.statusCode.toString(),
            ),
          );
        }
      },
      (updatedDeliveryData) async {
        debugPrint(
          '✅ BLOC: Successfully updated delivery location for ID: ${event.id}',
        );

        final newState = DeliveryLocationUpdated(
          deliveryData: updatedDeliveryData,
          deliveryDataId: event.id,
          latitude: event.latitude,
          longitude: event.longitude,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  // Add the event handler for setting invoice to completed
  Future<void> _onSetInvoiceIntoCompleted(
    SetInvoiceIntoCompletedEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    debugPrint(
      '🔄 BLOC: Setting invoice to completed for delivery data: ${event.deliveryDataId}',
    );

    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const DeliveryDataLoading());
    }

    final result = await _setInvoiceIntoCompleted(event.deliveryDataId);

    await result.fold(
      (failure) async {
        debugPrint(
          '❌ BLOC: Failed to set invoice to completed: ${failure.message}',
        );

        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(
            DeliveryDataError(
              message: 'Failed to set invoice to completed: ${failure.message}',
              statusCode: failure.statusCode.toString(),
            ),
          );
        }
      },
      (updatedDeliveryData) async {
        debugPrint(
          '✅ BLOC: Successfully set invoice to completed for delivery data: ${event.deliveryDataId}',
        );

        final newState = InvoiceSetToCompleted(
          deliveryData: updatedDeliveryData,
          deliveryDataId: event.deliveryDataId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
