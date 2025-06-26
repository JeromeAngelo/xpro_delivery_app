import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/user_performance/domain/entity/user_performance_entity.dart';

abstract class UserPerformanceEvent extends Equatable {
  const UserPerformanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserPerformanceByUserIdEvent extends UserPerformanceEvent {
  final String userId;

  const LoadUserPerformanceByUserIdEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadLocalUserPerformanceByUserIdEvent extends UserPerformanceEvent {
  final String userId;

  const LoadLocalUserPerformanceByUserIdEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CalculateDeliveryAccuracyEvent extends UserPerformanceEvent {
  final String userId;

  const CalculateDeliveryAccuracyEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SyncUserPerformanceEvent extends UserPerformanceEvent {
  final String userId;

  const SyncUserPerformanceEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUserPerformanceEvent extends UserPerformanceEvent {
  final UserPerformanceEntity userPerformance;

  const UpdateUserPerformanceEvent(this.userPerformance);

  @override
  List<Object?> get props => [userPerformance];
}

class DeleteUserPerformanceEvent extends UserPerformanceEvent {
  final String userId;

  const DeleteUserPerformanceEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadAllUserPerformanceEvent extends UserPerformanceEvent {
  const LoadAllUserPerformanceEvent();

  @override
  List<Object?> get props => [];
}

class RecalculateAndUpdateAccuracyEvent extends UserPerformanceEvent {
  final String userId;

  const RecalculateAndUpdateAccuracyEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RefreshUserPerformanceEvent extends UserPerformanceEvent {
  final String userId;

  const RefreshUserPerformanceEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ClearUserPerformanceEvent extends UserPerformanceEvent {
  const ClearUserPerformanceEvent();

  @override
  List<Object?> get props => [];
}
