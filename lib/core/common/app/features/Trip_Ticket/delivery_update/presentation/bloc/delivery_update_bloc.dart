import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/check_end_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/complete_delivery_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/create_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/get_delivery_update.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/itialized_pending_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/update_delivery_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/usecase/update_queue_remarks.dart';
import './delivery_update_event.dart';
import './delivery_update_state.dart';

class DeliveryUpdateBloc extends Bloc<DeliveryUpdateEvent, DeliveryUpdateState> {
  final GetDeliveryStatusChoices _getDeliveryStatusChoices;
  final UpdateDeliveryStatus _updateDeliveryStatus;
  final CompleteDelivery _completeDelivery;
  final CheckEndDeliverStatus _checkEndDeliverStatus;
  final InitializePendingStatus _initializePendingStatus;
  final CreateDeliveryStatus _createDeliveryStatus;
  final UpdateQueueRemarks _updateQueueRemarks;
  DeliveryUpdateState? _cachedState;

  DeliveryUpdateBloc({
    required GetDeliveryStatusChoices getDeliveryStatusChoices,
    required UpdateDeliveryStatus updateDeliveryStatus,
    required CompleteDelivery completeDelivery,
    required CheckEndDeliverStatus checkEndDeliverStatus,
    required InitializePendingStatus initializePendingStatus,
    required CreateDeliveryStatus createDeliveryStatus,
   required UpdateQueueRemarks updateQueueRemarks,

  }) : _getDeliveryStatusChoices = getDeliveryStatusChoices,
       _updateDeliveryStatus = updateDeliveryStatus,
       _completeDelivery = completeDelivery,
       _checkEndDeliverStatus = checkEndDeliverStatus,
       _initializePendingStatus = initializePendingStatus,
       _createDeliveryStatus = createDeliveryStatus,
       _updateQueueRemarks = updateQueueRemarks,
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

  }

  Future<void> _onUpdateQueueRemarks(
    UpdateQueueRemarksEvent event,
    Emitter<DeliveryUpdateState> emit,
  ) async {
    emit(DeliveryUpdateLoading());

    final result = await _updateQueueRemarks(
      UpdateQueueRemarksParams(
        customerId: event.customerId,
        queueCount: event.queueCount,
      ),
    );

    if (!emit.isDone) {
      result.fold(
        (failure) => emit(DeliveryUpdateError(failure.message)),
        (_) => emit(QueueRemarksUpdated(
          customerId: event.customerId,
          queueCount: event.queueCount,
        )),
      );
    }
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
      customerId: event.customerId,
      statusId: event.statusId,
    ),
  );

  result.fold(
    (failure) => emit(DeliveryUpdateError(failure.message)),
    (_) {
      emit(const DeliveryStatusUpdateSuccess());
      // Immediately refresh local data
      add(LoadLocalDeliveryStatusChoicesEvent(event.customerId));
      // Then update with remote data
      add(GetDeliveryStatusChoicesEvent(event.customerId));
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

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
