import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class CheckUserTripEvent extends SyncEvent {
  final BuildContext context;
  
  const CheckUserTripEvent(this.context);

  @override
  List<Object?> get props => [context];
}

class StartSyncProcessEvent extends SyncEvent {
  final BuildContext context;
  
  const StartSyncProcessEvent(this.context);

  @override
  List<Object?> get props => [context];
}

class ProcessPendingOperationsEvent extends SyncEvent {
  const ProcessPendingOperationsEvent();
}

class QueueOperationEvent extends SyncEvent {
  final String operationType;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> data;
  
  const QueueOperationEvent({
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.data,
  });

  @override
  List<Object?> get props => [operationType, entityType, entityId, data];
}

class RefreshDataEvent extends SyncEvent {
  final BuildContext context;
  
  const RefreshDataEvent(this.context);

  @override
  List<Object?> get props => [context];
}

class ConnectionRestoredEvent extends SyncEvent {
  const ConnectionRestoredEvent();
}
