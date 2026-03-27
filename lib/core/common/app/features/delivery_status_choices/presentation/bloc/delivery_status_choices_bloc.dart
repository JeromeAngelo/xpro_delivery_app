import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/domain/usecase/sync_all_delivery_status_choices.dart';

import '../../domain/usecase/get_assigned_delivery_status_choices.dart';
import '../../domain/usecase/revert_update_delivery_status.dart';
import '../../domain/usecase/set_end_delivery.dart';
import '../../domain/usecase/update_customer_status.dart';
import '../../domain/usecase/get_all_bulk_delivery_status_choices.dart';
import '../../domain/usecase/bulk_update_delivery_status_usecase.dart';
import 'delivery_status_choices_event.dart';
import 'delivery_status_choices_state.dart';
import 'package:x_pro_delivery_app/core/services/injection_container.dart'
    show sl;
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';

class DeliveryStatusChoicesBloc
    extends Bloc<DeliveryStatusChoicesEvent, DeliveryStatusChoicesState> {
  final SyncAllDeliveryStatusChoices _syncDeliveryStatusChoices;
  final GetAssignedDeliveryStatusChoices _getAssignedDeliveryStatusChoices;
  final UpdateCustomerStatus _updateCustomerStatus;
  final GetAllBulkDeliveryStatusChoices _getAllBulkDeliveryStatusChoices;
  final BulkUpdateDeliveryStatusUsecase _bulkUpdateDeliveryStatus;
  final SetEndDelivery _completeDelivery;
  final RevertUpdateDeliveryStatus _revertUpdateDeliveryStatus;

  DeliveryStatusChoicesBloc({
    required SyncAllDeliveryStatusChoices syncDeliveryStatusChoices,
    required GetAssignedDeliveryStatusChoices getAssignedDeliveryStatusChoices,
    required RevertUpdateDeliveryStatus revertUpdateDeliveryStatus,
    required UpdateCustomerStatus updateCustomerStatus,
    required GetAllBulkDeliveryStatusChoices getAllBulkDeliveryStatusChoices,
    required BulkUpdateDeliveryStatusUsecase bulkUpdateDeliveryStatus,
    required SetEndDelivery completeDelivery,
  }) : _syncDeliveryStatusChoices = syncDeliveryStatusChoices,
       _getAssignedDeliveryStatusChoices = getAssignedDeliveryStatusChoices,
       _revertUpdateDeliveryStatus = revertUpdateDeliveryStatus,
       _updateCustomerStatus = updateCustomerStatus,
       _getAllBulkDeliveryStatusChoices = getAllBulkDeliveryStatusChoices,
       _bulkUpdateDeliveryStatus = bulkUpdateDeliveryStatus,
       _completeDelivery = completeDelivery,
       super(DeliveryStatusChoicesInitial()) {
    on<SyncAllDeliveryStatusChoicesEvent>(_onSyncDeliveryStatusChoices);
    on<GetAllAssignedDeliveryStatusChoicesEvent>(
      _onGetAssignedDeliveryStatusChoices,
    );
    on<UpdateCustomerStatusEvent>(_onUpdateCustomerStatus);
    on<RevertUpdateCustomerStatusEvent>(_onRevertUpdateDeliveryStatus);
    on<GetAllBulkDeliveryStatusChoicesEvent>(
      _onGetAllBulkDeliveryStatusChoices,
    );
    on<BulkUpdateDeliveryStatusEvent>(_onBulkUpdateDeliveryStatus);
    on<SetEndDeliveryEvent>(_onSetEndDelivery);
  }

  Future<void> _onSetEndDelivery(
    SetEndDeliveryEvent event,
    Emitter<DeliveryStatusChoicesState> emit,
  ) async {
    debugPrint(
      '🔄 Starting delivery completion for delivery data: ${event.deliveryData.id}',
    );
    emit(DeliveryStatusChoicesLoading());

    final result = await _completeDelivery(
      SetEndDeliveryParams(deliveryData: event.deliveryData),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Delivery completion failed: ${failure.message}');
        emit(DeliveryStatusChoicesError(failure.message));
      },
      (_) {
        debugPrint('✅ Delivery completion successful');
        emit(
          EndDeliverySuccess(
            deliveryDataId: event.deliveryData.id ?? '',
            tripId: event.deliveryData.trip.target?.id,
          ),
        );
      },
    );
  }

  Future<void> _onGetAllBulkDeliveryStatusChoices(
    GetAllBulkDeliveryStatusChoicesEvent event,
    Emitter<DeliveryStatusChoicesState> emit,
  ) async {
    emit(DeliveryStatusChoicesLoading());
    debugPrint(
      '📦 Fetching bulk assigned status choices for ${event.deliveryDataIds.length} customers',
    );

    final result = await _getAllBulkDeliveryStatusChoices(
      event.deliveryDataIds,
    );

    result.fold(
      (failure) {
        debugPrint('❌ Bulk fetch failed: ${failure.message}');
        emit(DeliveryStatusChoicesError(failure.message));
      },
      (map) {
        debugPrint('✅ Bulk choices loaded for ${map.length} customers');
        emit(BulkAssignedDeliveryStatusChoicesLoaded(map));
      },
    );
  }

  Future<void> _onBulkUpdateDeliveryStatus(
    BulkUpdateDeliveryStatusEvent event,
    Emitter<DeliveryStatusChoicesState> emit,
  ) async {
    emit(DeliveryStatusChoicesLoading());
    debugPrint('🔄 Bulk updating ${event.deliveryDataIds.length} customers');

    final params = BulkUpdateDeliveryStatusUsecaseParams(
      customerIds: event.deliveryDataIds,
      statusId: event.status,
    );

    final result = await _bulkUpdateDeliveryStatus(params);

    result.fold(
      (failure) {
        debugPrint('❌ Bulk update failed: ${failure.message}');
        emit(DeliveryStatusChoicesError(failure.message));
      },
      (_) {
        debugPrint('✅ Bulk update succeeded');
        emit(const BulkDeliveryStatusUpdated());

        // Optionally refresh UI by reloading per-customer assigned choices
        for (final id in event.deliveryDataIds) {
          add(GetAllAssignedDeliveryStatusChoicesEvent(id));
        }
      },
    );
  }

  

  Future<void> _onSyncDeliveryStatusChoices(
    SyncAllDeliveryStatusChoicesEvent event,
    Emitter<DeliveryStatusChoicesState> emit,
  ) async {
    emit(DeliveryStatusChoicesLoading());
    debugPrint('🔄 Starting sync of delivery status choices…');

    final result = await _syncDeliveryStatusChoices();

    result.fold(
      (failure) {
        debugPrint('❌ Sync failed: ${failure.message}');
        emit(DeliveryStatusChoicesError(failure.message));
      },
      (syncedChoices) {
        debugPrint(
          '✅ Successfully synced ${syncedChoices.length} delivery statuses',
        );
        emit(DeliveryStatusChoicesSynced(syncedChoices));
      },
    );
  }

  /// 📦 Get assigned delivery status choices (offline-first)
  Future<void> _onGetAssignedDeliveryStatusChoices(
    GetAllAssignedDeliveryStatusChoicesEvent event,
    Emitter<DeliveryStatusChoicesState> emit,
  ) async {
    emit(DeliveryStatusChoicesLoading());
    debugPrint(
      '📦 Fetching assigned delivery status choices for ${event.deliveryDataId}',
    );

    final result = await _getAssignedDeliveryStatusChoices(
      event.deliveryDataId,
    );

    result.fold(
      (failure) {
        debugPrint('❌ Failed to fetch assigned statuses: ${failure.message}');
        emit(DeliveryStatusChoicesError(failure.message));
      },
      (assignedStatuses) {
        debugPrint('✅ Loaded ${assignedStatuses.length} assigned statuses');
        emit(AssignedDeliveryStatusChoicesLoaded(assignedStatuses));
      },
    );
  }

  /// 📝 Update customer delivery status (offline-first + remote sync)
  Future<void> _onUpdateCustomerStatus(
    UpdateCustomerStatusEvent event,
    Emitter<DeliveryStatusChoicesState> emit,
  ) async {
    debugPrint('🔄 Updating delivery status for ${event.deliveryDataId}');
    emit(DeliveryStatusChoicesLoading());

    final result = await _updateCustomerStatus(
      UpdateDeliveryStatusParams(
        deliveryDataId: event.deliveryDataId,
        status: event.status,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Update failed: ${failure.message}');
        emit(DeliveryStatusChoicesError(failure.message));
      },
      (_) {
        debugPrint('✅ Status updated successfully');
        emit(const DeliveryStatusUpdated());

        // Optionally, refresh assigned choices to reflect new state
        add(GetAllAssignedDeliveryStatusChoicesEvent(event.deliveryDataId));
        // Trigger a by-id load so DeliveryDataBloc emits the freshly persisted
        // delivery object (this forces UI tiles to receive the updated item).
        try {
          final deliveryBloc = sl<DeliveryDataBloc>();
          deliveryBloc.add(GetDeliveryDataByIdEvent(event.deliveryDataId));
        } catch (e, st) {
          debugPrint('🔔 Unable to dispatch DeliveryData load by-id: $e\n$st');
        }
      },
    );
  }

  Future<void> _onRevertUpdateDeliveryStatus(
    RevertUpdateCustomerStatusEvent event,
    Emitter<DeliveryStatusChoicesState> emit,
  ) async {
    debugPrint('🔄 Updating delivery status for ${event.deliveryDataId}');
    emit(DeliveryStatusChoicesLoading());

    final result = await _revertUpdateDeliveryStatus(
      RevertDeliveryStatusParams(
        deliveryDataId: event.deliveryDataId,
        status: event.status,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Update failed: ${failure.message}');
        emit(DeliveryStatusChoicesError(failure.message));
      },
      (_) {
        debugPrint('✅ Status updated successfully');
        emit(const RevertDeliveryStatusUpdated());

        // Optionally, refresh assigned choices to reflect new state
        add(GetAllAssignedDeliveryStatusChoicesEvent(event.deliveryDataId));
        // Trigger a by-id load so DeliveryDataBloc emits the freshly persisted
        // delivery object (this forces UI tiles to receive the updated item).
        try {
          final deliveryBloc = sl<DeliveryDataBloc>();
          deliveryBloc.add(GetDeliveryDataByIdEvent(event.deliveryDataId));
        } catch (e, st) {
          debugPrint('🔔 Unable to dispatch DeliveryData load by-id: $e\n$st');
        }
      },
    );
  }
}
