import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  const SyncInitial();
}

class SyncLoading extends SyncState {
  const SyncLoading();
}

class CheckingTrip extends SyncState {
  const CheckingTrip();
}

class TripFound extends SyncState {
  final String tripId;
  final String tripNumber;
  
  const TripFound({
    required this.tripId,
    required this.tripNumber,
  });

  @override
  List<Object?> get props => [tripId, tripNumber];
}

class NoTripFound extends SyncState {
  const NoTripFound();
}

class SyncingAuthData extends SyncState {
  const SyncingAuthData();
}

class AuthDataSynced extends SyncState {
  const AuthDataSynced();
}

class SyncingTripData extends SyncState {
  final double progress;
  final String statusMessage;
  
  const SyncingTripData({
    required this.progress,
    required this.statusMessage,
  });

  @override
  List<Object?> get props => [progress, statusMessage];
}

class SyncingDeliveryData extends SyncState {
  final double progress;
  final String statusMessage;
  
  const SyncingDeliveryData({
    required this.progress,
    required this.statusMessage,
  });

  @override
  List<Object?> get props => [progress, statusMessage];
}

class SyncingDependentData extends SyncState {
  final double progress;
  final String statusMessage;
  
  const SyncingDependentData({
    required this.progress,
    required this.statusMessage,
  });

  @override
  List<Object?> get props => [progress, statusMessage];
}

class SyncCompleted extends SyncState {
  const SyncCompleted();
}

class SyncError extends SyncState {
  final String message;
  final String? errorCode;
  
  const SyncError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class ProcessingPendingOperations extends SyncState {
  final int totalOperations;
  final int completedOperations;
  
  const ProcessingPendingOperations({
    required this.totalOperations,
    required this.completedOperations,
  });

  @override
  List<Object?> get props => [totalOperations, completedOperations];
}

class PendingOperationsCompleted extends SyncState {
  final int processedOperations;
  final int failedOperations;
  
  const PendingOperationsCompleted({
    required this.processedOperations,
    required this.failedOperations,
  });

  @override
  List<Object?> get props => [processedOperations, failedOperations];
}
