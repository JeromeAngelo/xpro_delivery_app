import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/calculate_delivery_time_by_delivery_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/delete_delivery_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_all_delivery_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_delivery_data_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_delivery_data_by_trip_id.dart' show GetDeliveryDataByTripId;
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

import '../../domain/usecases/set_invoice_into_unloaded.dart';
import '../../domain/usecases/set_invoice_into_unloading.dart';
import '../../domain/usecases/sync_delivery_data_by_trip_id.dart';


class DeliveryDataBloc extends Bloc<DeliveryDataEvent, DeliveryDataState> {
  final GetAllDeliveryData _getAllDeliveryData;
  final GetDeliveryDataByTripId _getDeliveryDataByTripId;
  final GetDeliveryDataById _getDeliveryDataById;
  final DeleteDeliveryData _deleteDeliveryData;
  final CalculateDeliveryTimeByDeliveryId _calculateDeliveryTime; // Add this
  final SyncDeliveryDataByTripId _syncDeliveryDataByTripId;
  final SetInvoiceIntoUnloading _setInvoiceIntoUnloading;
    final SetInvoiceIntoUnloaded _setInvoiceIntoUnloaded;


  DeliveryDataState? _cachedState;

  DeliveryDataBloc({
    required GetAllDeliveryData getAllDeliveryData,
      required SyncDeliveryDataByTripId syncDeliveryDataByTripId,
    required GetDeliveryDataByTripId getDeliveryDataByTripId,
    required GetDeliveryDataById getDeliveryDataById,
    required SetInvoiceIntoUnloaded setInvoiceIntoUnloaded,
    required DeleteDeliveryData deleteDeliveryData,
    required CalculateDeliveryTimeByDeliveryId calculateDeliveryTime, // Add this
      required SetInvoiceIntoUnloading setInvoiceIntoUnloading,
  })  : _getAllDeliveryData = getAllDeliveryData,
        _getDeliveryDataByTripId = getDeliveryDataByTripId,
        _getDeliveryDataById = getDeliveryDataById,
        _deleteDeliveryData = deleteDeliveryData,
        _calculateDeliveryTime = calculateDeliveryTime, // Add this
          _syncDeliveryDataByTripId = syncDeliveryDataByTripId, // Add this
             _setInvoiceIntoUnloading = setInvoiceIntoUnloading,
              _setInvoiceIntoUnloaded = setInvoiceIntoUnloaded,
        super(const DeliveryDataInitial()) {
    on<GetAllDeliveryDataEvent>(_onGetAllDeliveryData);
    on<GetDeliveryDataByTripIdEvent>(_onGetDeliveryDataByTripId);

    on<GetDeliveryDataByIdEvent>(_onGetDeliveryDataById);
    on<DeleteDeliveryDataEvent>(_onDeleteDeliveryData);
    on<GetLocalDeliveryDataByTripIdEvent>(_onGetLocalDeliveryDataByTripId);
    on<GetLocalDeliveryDataByIdEvent>(_onGetLocalDeliveryDataById);
    on<CalculateDeliveryTimeEvent>(_onCalculateDeliveryTime); // Add this
    on<SyncDeliveryDataByTripIdEvent>(_onSyncDeliveryDataByTripId); // Add this
    on<SetInvoiceIntoUnloadingEvent>(_onSetInvoiceIntoUnloading);
    on<SetInvoiceIntoUnloadedEvent>(_onSetInvoiceIntoUnloaded);
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
        debugPrint('❌ BLOC: Failed to sync delivery data by trip ID: ${failure.message}');
        
        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(DeliveryDataError(
            message: 'Sync error: ${failure.message}',
            statusCode: failure.statusCode.toString(),
          ));
        }
      },
      (syncedDeliveryData) async {
        debugPrint('✅ BLOC: Successfully synced ${syncedDeliveryData.length} delivery data records for trip ID: ${event.tripId}');
        
        final newState = DeliveryDataSyncedByTrip(
          deliveryData: syncedDeliveryData,
          tripId: event.tripId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetLocalDeliveryDataByTripId(
  GetLocalDeliveryDataByTripIdEvent event,
  Emitter<DeliveryDataState> emit,
) async {
  debugPrint('📱 BLOC: Getting local delivery data for trip ID: ${event.tripId}');
  
  // Don't emit loading if we have cached data
  if (_cachedState == null) {
    emit(const DeliveryDataLoading());
  }

  final result = await _getDeliveryDataByTripId.loadFromLocal(event.tripId);

  await result.fold(
    (failure) async {
      debugPrint('❌ BLOC: Failed to get local delivery data by trip ID: ${failure.message}');
      
      // Only emit error if we don't have cached data
      if (_cachedState == null) {
        emit(DeliveryDataError(
          message: 'Local data error: ${failure.message}', 
          statusCode: failure.statusCode.toString(),
        ));
      }
    },
    (localDeliveryData) async {
      debugPrint('✅ BLOC: Successfully retrieved ${localDeliveryData.length} local delivery data records for trip ID: ${event.tripId}');
      
      // Verify the data has proper relationships
      for (int i = 0; i < localDeliveryData.length; i++) {
        final delivery = localDeliveryData[i];
        debugPrint('🔍 BLOC Delivery ${i + 1}:');
        debugPrint('   ID: ${delivery.id}');
        debugPrint('   Customer: ${delivery.customer.target?.name ?? 'NULL'}');
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
      emit(DeliveryDataError(
        message: failure.message, 
        statusCode: failure.statusCode.toString(), // Convert int to String
      ));
    },
    (deliveryData) {
      debugPrint('✅ BLOC: Successfully retrieved ${deliveryData.length} delivery data records');
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
  emit(const DeliveryDataLoading());
  debugPrint('🔄 BLOC: Getting delivery data for trip ID: ${event.tripId}');

  final result = await _getDeliveryDataByTripId(event.tripId);
  result.fold(
    (failure) {
      debugPrint('❌ BLOC: Failed to get delivery data by trip ID: ${failure.message}');
      emit(DeliveryDataError(
        message: failure.message, 
        statusCode: failure.statusCode.toString(), // Convert int to String
      ));
    },
    (deliveryData) {
      debugPrint('✅ BLOC: Successfully retrieved ${deliveryData.length} delivery data records for trip ID: ${event.tripId}');
      final newState = DeliveryDataByTripLoaded(
        deliveryData: deliveryData,
        tripId: event.tripId,
      );
      _cachedState = newState;
      emit(newState);
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
      debugPrint('❌ BLOC: Failed to get delivery data by ID: ${failure.message}');
      emit(DeliveryDataError(
        message: failure.message, 
        statusCode: failure.statusCode.toString(), // Convert int to String
      ));
    },
    (deliveryData) {
      debugPrint('✅ BLOC: Successfully retrieved delivery data with ID: ${event.id}');
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
      debugPrint('❌ BLOC: Failed to delete delivery data: ${failure.message}');
      emit(DeliveryDataError(
        message: failure.message, 
        statusCode: failure.statusCode.toString(), // Convert int to String
      ));
    },
    (success) {
      debugPrint('✅ BLOC: Successfully deleted delivery data with ID: ${event.id}');
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
      debugPrint('❌ BLOC: Failed to get local delivery data by ID: ${failure.message}');
      emit(DeliveryDataError(
        message: failure.message, 
        statusCode: failure.statusCode.toString(), // Convert int to String
      ));
    },
    (localDeliveryData) async {
      debugPrint('✅ BLOC: Successfully retrieved local delivery data with ID: ${event.id}');
      emit(DeliveryDataLoaded(
        localDeliveryData,
      ));
    },
  );
}

 // Add the event handler
  Future<void> _onSetInvoiceIntoUnloading(
    SetInvoiceIntoUnloadingEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    debugPrint('🔄 BLOC: Setting invoice to unloading for delivery data: ${event.deliveryDataId}');
    
    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const DeliveryDataLoading());
    }

    final result = await _setInvoiceIntoUnloading(event.deliveryDataId);

    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: Failed to set invoice to unloading: ${failure.message}');
        
        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(DeliveryDataError(
            message: 'Failed to set invoice to unloading: ${failure.message}',
            statusCode: failure.statusCode.toString(),
          ));
        }
      },
      (updatedDeliveryData) async {
        debugPrint('✅ BLOC: Successfully set invoice to unloading for delivery data: ${event.deliveryDataId}');
        
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
    debugPrint('🔄 BLOC: Setting invoice to unloading for delivery data: ${event.deliveryDataId}');
    
    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const DeliveryDataLoading());
    }

    final result = await _setInvoiceIntoUnloaded(event.deliveryDataId);

    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: Failed to set invoice to unloaded: ${failure.message}');
        
        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(DeliveryDataError(
            message: 'Failed to set invoice to unloaded: ${failure.message}',
            statusCode: failure.statusCode.toString(),
          ));
        }
      },
      (updatedDeliveryData) async {
        debugPrint('✅ BLOC: Successfully set invoice to unloaded for delivery data: ${event.deliveryDataId}');
        
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
    debugPrint('⏱️ BLOC: Calculating delivery time for delivery ID: ${event.deliveryId}');
    
    // Don't emit loading if we have cached state
    if (_cachedState == null) {
      emit(const DeliveryDataLoading());
    }

    final result = await _calculateDeliveryTime(event.deliveryId);

    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: Failed to calculate delivery time: ${failure.message}');
        
        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(DeliveryDataError(
            message: 'Delivery time calculation error: ${failure.message}',
            statusCode: failure.statusCode.toString(),
          ));
        }
      },
      (deliveryTimeInMinutes) async {
        debugPrint('✅ BLOC: Successfully calculated delivery time: $deliveryTimeInMinutes minutes for delivery ID: ${event.deliveryId}');
        
        final newState = DeliveryTimeCalculated(
          deliveryTimeInMinutes: deliveryTimeInMinutes,
          deliveryId: event.deliveryId,
        );
        
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
