import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/usecase/check_end_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/usecase/complete_delivery_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/usecase/create_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/usecase/get_delivery_update.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/usecase/itialized_pending_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/usecase/update_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/usecase/update_queue_remarks.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/usecase/pin_arrived_location.dart';
import '../../domain/usecase/bulk_update_delivery_status.dart';
import '../../domain/usecase/get_bulk_delivery_status_choices.dart';
import '../../domain/usecase/sync_delivery_status_choices.dart';
import 'delivery_update_event.dart';
import 'delivery_update_state.dart';

class DeliveryUpdateBloc extends Bloc<DeliveryUpdateEvent, DeliveryUpdateState> {
  final GetDeliveryStatusChoices _getDeliveryStatusChoices;
  final GetBulkDeliveryStatusChoices _getBulkDeliveryStatusChoices;
  final UpdateDeliveryStatus _updateDeliveryStatus;
  final CompleteDelivery _completeDelivery;
  final CheckEndDeliverStatus _checkEndDeliverStatus;
  final InitializePendingStatus _initializePendingStatus;
  final CreateDeliveryStatus _createDeliveryStatus;
  final UpdateQueueRemarks _updateQueueRemarks;
  final PinArrivedLocation _pinArrivedLocation;
  final SyncDeliveryStatusChoices _syncDeliveryStatusChoices;
  // Add the dependency
final BulkUpdateDeliveryStatus _bulkUpdateDeliveryStatus;
  DeliveryUpdateState? _cachedState;

  DeliveryUpdateBloc({
    required GetDeliveryStatusChoices getDeliveryStatusChoices,
    required UpdateDeliveryStatus updateDeliveryStatus,
    required CompleteDelivery completeDelivery,
    required GetBulkDeliveryStatusChoices getBulkDeliveryStatusChoices,
    required CheckEndDeliverStatus checkEndDeliverStatus,
    required InitializePendingStatus initializePendingStatus,
    required SyncDeliveryStatusChoices syncDeliveryStatusChoices,
    required CreateDeliveryStatus createDeliveryStatus,
   required UpdateQueueRemarks updateQueueRemarks,
   required PinArrivedLocation pinArrivedLocation,
required BulkUpdateDeliveryStatus bulkUpdateDeliveryStatus,
  }) : _getDeliveryStatusChoices = getDeliveryStatusChoices,
       _updateDeliveryStatus = updateDeliveryStatus,
       _completeDelivery = completeDelivery,
       _getBulkDeliveryStatusChoices = getBulkDeliveryStatusChoices,
       _checkEndDeliverStatus = checkEndDeliverStatus,
       _syncDeliveryStatusChoices = syncDeliveryStatusChoices,
       _initializePendingStatus = initializePendingStatus,
       _createDeliveryStatus = createDeliveryStatus,
       _updateQueueRemarks = updateQueueRemarks,
       _pinArrivedLocation = pinArrivedLocation,

_bulkUpdateDeliveryStatus = bulkUpdateDeliveryStatus,

       super(DeliveryUpdateInitial()) {
    on<GetDeliveryStatusChoicesEvent>(_onGetDeliveryStatusChoices);
    on<LoadLocalDeliveryStatusChoicesEvent>(_onLoadLocalDeliveryStatusChoices);
    on<UpdateDeliveryStatusEvent>(_onUpdateDeliveryStatus);
    on<CompleteDeliveryEvent>(_onCompleteDelivery);
    on<CheckEndDeliveryStatusEvent>(_onCheckEndDeliveryStatus);
    on<InitializePendingStatusEvent>(_onInitializePendingStatus);
    on<CreateDeliveryStatusEvent>(_onCreateDeliveryStatus);
       on<UpdateQueueRemarksEvent>(_onUpdateQueueRemarks);
on<CheckLocalEndDeliveryStatusEvent>(_onCheckLocalEndDeliveryStatus);
    on<PinArrivedLocationEvent>(_onPinArrivedLocation);
on<BulkUpdateDeliveryStatusEvent>(_onBulkUpdateDeliveries);
 on<GetBulkDeliveryStatusChoicesEvent>(_onGetBulkDeliveryStatusChoices);
  on<LoadLocalBulkDeliveryStatusChoicesEvent>(_onLoadLocalBulkDeliveryStatusChoices);
  on<SyncDeliveryStatusChoicesEvent>(_onSyncDeliveryStatusChoices);

  }

Future<void> _onUpdateQueueRemarks(
  UpdateQueueRemarksEvent event,
  Emitter<DeliveryUpdateState> emit,
) async {
  emit(DeliveryUpdateLoading());

  final result = await _updateQueueRemarks(
    UpdateQueueRemarksParams(
      statusId: event.statusId,
      remarks: event.remarks,
      image: event.image,
    ),
  );

  if (!emit.isDone) {
    result.fold(
      (failure) => emit(DeliveryUpdateError(failure.message)),
      (_) => emit(QueueRemarksUpdated(
        statusId: event.statusId,
        remarks: event.remarks,
        image: event.image,
      )),
    );
  }
}


Future<void> _onGetBulkDeliveryStatusChoices(
  GetBulkDeliveryStatusChoicesEvent event,
  Emitter<DeliveryUpdateState> emit,
) async {
  debugPrint('🌐 Fetching bulk delivery status choices (remote)');
  emit(DeliveryUpdateLoading());

  final result = await _getBulkDeliveryStatusChoices(event.customerIds);

  result.fold(
    (failure) {
      debugPrint('❌ Bulk fetch failed: ${failure.message}');
      emit(DeliveryUpdateError(failure.message));
    },
    (data) {
      debugPrint('✅ Bulk fetch success for ${data.length} customers');
      emit(BulkDeliveryStatusChoicesLoaded(data));
    },
  );
}

Future<void> _onLoadLocalBulkDeliveryStatusChoices(
  LoadLocalBulkDeliveryStatusChoicesEvent event,
  Emitter<DeliveryUpdateState> emit,
) async {
  debugPrint('📱 Fetching bulk delivery status choices (local)');
  emit(DeliveryUpdateLoading());

  final result = await _getBulkDeliveryStatusChoices(event.customerIds);

  result.fold(
    (failure) {
      emit(DeliveryUpdateError(failure.message, isLocalError: true));
      add(GetBulkDeliveryStatusChoicesEvent(event.customerIds)); // fallback remote
    },
    (data) {
      emit(BulkDeliveryStatusChoicesLoaded(data, isFromLocal: true));
      add(GetBulkDeliveryStatusChoicesEvent(event.customerIds)); // refresh in background
    },
  );
}


Future<void> _onGetDeliveryStatusChoices(
  GetDeliveryStatusChoicesEvent event,
  Emitter<DeliveryUpdateState> emit,
) async {
  emit(DeliveryUpdateLoading());
  debugPrint('🌐 Fetching delivery status choices from remote');

  final result = await _getDeliveryStatusChoices(event.customerId);
  result.fold(
    (failure) => emit(DeliveryUpdateError(failure.message)),
    (statusChoices) {
      final newState = DeliveryStatusChoicesLoaded(statusChoices);
      _cachedState = newState;
      emit(newState);
    },
  );
}

  Future<void> _onLoadLocalDeliveryStatusChoices(
  LoadLocalDeliveryStatusChoicesEvent event,
  Emitter<DeliveryUpdateState> emit,
) async {
  debugPrint('📱 Loading local delivery status choices');
  emit(DeliveryUpdateLoading());
  
  final result = await _getDeliveryStatusChoices.loadFromLocal(event.customerId);
  
  await result.fold(
    (failure) async {
      emit(DeliveryUpdateError(failure.message, isLocalError: true));
      // Immediately try remote fetch if local fails
      add(GetDeliveryStatusChoicesEvent(event.customerId));
    },
    (localStatusChoices) async {
      emit(DeliveryStatusChoicesLoaded(localStatusChoices, isFromLocal: true));
      // Refresh with remote data in background
      add(GetDeliveryStatusChoicesEvent(event.customerId));
    },
  );
}


Future<void> _onUpdateDeliveryStatus(
  UpdateDeliveryStatusEvent event,
  Emitter<DeliveryUpdateState> emit,
) async {
  debugPrint('🔄 Starting delivery status update');
  emit(DeliveryUpdateLoading());

  final result = await _updateDeliveryStatus(
    UpdateDeliveryStatusParams(
      deliveryDataId: event.deliveryDataId,
      status: event.status,
    ),
  );

  result.fold(
    (failure) => emit(DeliveryUpdateError(failure.message)),
    (_) {
      emit(const DeliveryStatusUpdateSuccess());

      // Refresh local + remote choices
      add(LoadLocalDeliveryStatusChoicesEvent(event.deliveryDataId));
      add(GetDeliveryStatusChoicesEvent(event.deliveryDataId));
    },
  );
}



// Now add the function
Future<void> _onBulkUpdateDeliveries(
  BulkUpdateDeliveryStatusEvent event,
  Emitter<DeliveryUpdateState> emit,
) async {
  debugPrint('🔄 Bulk updating delivery statuses');
  emit(DeliveryUpdateLoading());

  final result = await _bulkUpdateDeliveryStatus(
    BulkUpdateDeliveryStatusParams(
      customerIds: event.customerIds,
      statusId: event.statusId,
    ),
  );

  result.fold(
    (failure) {
      debugPrint('❌ Bulk update failed: ${failure.message}');
      emit(DeliveryUpdateError(failure.message));
    },
    (_) {
      debugPrint('✅ Bulk update successful for ${event.customerIds.length} deliveries');
      emit(BulkDeliveryStatusUpdateSuccess(
        customerIds: event.customerIds,
        statusId: event.statusId,
      ));

      // Refresh each delivery's statuses
      for (final deliveryId in event.customerIds) {
        add(LoadLocalDeliveryStatusChoicesEvent(deliveryId));
        add(GetDeliveryStatusChoicesEvent(deliveryId));
      }
    },
  );
}


   Future<void> _onCompleteDelivery(
    CompleteDeliveryEvent event,
    Emitter<DeliveryUpdateState> emit,
  ) async {
    debugPrint('🔄 Starting delivery completion for delivery data: ${event.deliveryData.id}');
    emit(DeliveryUpdateLoading());

    final result = await _completeDelivery(
      CompleteDeliveryParams(
        deliveryData: event.deliveryData,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Delivery completion failed: ${failure.message}');
        emit(DeliveryUpdateError(failure.message));
      },
      (_) {
        debugPrint('✅ Delivery completion successful');
        emit(DeliveryCompletionSuccess(
          deliveryDataId: event.deliveryData.id ?? '',
          tripId: event.deliveryData.trip.target?.id,
        ));
      },
    );
  }


  Future<void> _onCheckEndDeliveryStatus(
  CheckEndDeliveryStatusEvent event,
  Emitter<DeliveryUpdateState> emit,
) async {
  emit(DeliveryUpdateLoading());
  debugPrint('🔄 Checking remote delivery status for trip: ${event.tripId}');

  final result = await _checkEndDeliverStatus(event.tripId);
  result.fold(
    (failure) => emit(DeliveryUpdateError(failure.message)),
    (stats) => emit(EndDeliveryStatusChecked(
      stats: stats,
      tripId: event.tripId,
    )),
  );
}

Future<void> _onCheckLocalEndDeliveryStatus(
  CheckLocalEndDeliveryStatusEvent event,
  Emitter<DeliveryUpdateState> emit,
) async {
  emit(DeliveryUpdateLoading());
  debugPrint('📱 Checking local delivery status for trip: ${event.tripId}');

  final result = await _checkEndDeliverStatus.checkLocal(event.tripId);
  result.fold(
    (failure) => emit(DeliveryUpdateError(failure.message)),
    (stats) => emit(EndDeliveryStatusChecked(
      stats: stats,
      tripId: event.tripId,
      isFromLocal: true,
    )),
  );
}


  Future<void> _onInitializePendingStatus(
    InitializePendingStatusEvent event,
    Emitter<DeliveryUpdateState> emit,
  ) async {
    emit(DeliveryUpdateLoading());

    final result = await _initializePendingStatus(event.customerIds);

    result.fold(
      (failure) => emit(DeliveryUpdateError(failure.message)),
      (_) => emit(PendingStatusInitialized()),
    );
  }

  Future<void> _onCreateDeliveryStatus(
    CreateDeliveryStatusEvent event,
    Emitter<DeliveryUpdateState> emit,
  ) async {
    emit(DeliveryUpdateLoading());

    final result = await _createDeliveryStatus(
      CreateDeliveryStatusParams(
        customerId: event.customerId,
        title: event.title,
        subtitle: event.subtitle,
        time: event.time,
        isAssigned: event.isAssigned,
        image: event.image,
      ),
    );

    result.fold(
      (failure) => emit(DeliveryUpdateError(failure.message)),
      (_) => emit(DeliveryStatusCreated(event.customerId)),
    );
  }

  Future<void> _onPinArrivedLocation(
    PinArrivedLocationEvent event,
    Emitter<DeliveryUpdateState> emit,
  ) async {
    debugPrint('📍 Starting location pinning for delivery: ${event.deliveryId}');
    emit(DeliveryUpdateLoading());

    final result = await _pinArrivedLocation(
      PinArrivedLocationParams(
        deliveryId: event.deliveryId,
      ),
    );

    if (!emit.isDone) {
      result.fold(
        (failure) {
          debugPrint('❌ Location pinning failed: ${failure.message}');
          emit(DeliveryUpdateError(failure.message));
        },
        (_) {
          debugPrint('✅ Location pinning successful');
          emit(PinArrivedLocationSuccess(
            deliveryId: event.deliveryId,
          ));
        },
      );
    }
  }

  Future<void> _onSyncDeliveryStatusChoices(
  SyncDeliveryStatusChoicesEvent event,
  Emitter<DeliveryUpdateState> emit,
) async {
  emit(DeliveryStatusSyncing(event.customerId));
  debugPrint('🔄 Starting sync of delivery status choices for ${event.customerId}');

  final result = await _syncDeliveryStatusChoices(event.customerId);

  result.fold(
    (failure) {
      debugPrint('❌ Sync failed: ${failure.message}');
      emit(DeliveryUpdateError(failure.message));
    },
    (syncedChoices) {
      debugPrint('✅ Successfully synced ${syncedChoices.length} delivery statuses for ${event.customerId}');
      emit(DeliveryStatusChoicesSynced(syncedChoices));
    },
  );
}


  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}