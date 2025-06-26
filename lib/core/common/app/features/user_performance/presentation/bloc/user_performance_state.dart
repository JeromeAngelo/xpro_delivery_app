import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/user_performance/domain/entity/user_performance_entity.dart';

abstract class UserPerformanceState extends Equatable {
  const UserPerformanceState();

  @override
  List<Object?> get props => [];
}

class UserPerformanceInitial extends UserPerformanceState {
  const UserPerformanceInitial();
}

class UserPerformanceLoading extends UserPerformanceState {
  const UserPerformanceLoading();
}

class UserPerformanceLoaded extends UserPerformanceState {
  final UserPerformanceEntity userPerformance;
  final bool isFromCache;

  const UserPerformanceLoaded({
    required this.userPerformance,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [userPerformance, isFromCache];
}

class AllUserPerformanceLoaded extends UserPerformanceState {
  final List<UserPerformanceEntity> userPerformanceList;

  const AllUserPerformanceLoaded(this.userPerformanceList);

  @override
  List<Object?> get props => [userPerformanceList];
}

class DeliveryAccuracyCalculated extends UserPerformanceState {
  final String userId;
  final double accuracy;
  final bool isFromCache;

  const DeliveryAccuracyCalculated({
    required this.userId,
    required this.accuracy,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [userId, accuracy, isFromCache];
}

class UserPerformanceSynced extends UserPerformanceState {
  final UserPerformanceEntity userPerformance;
  final String message;

  const UserPerformanceSynced({
    required this.userPerformance,
    this.message = 'User performance synced successfully',
  });

  @override
  List<Object?> get props => [userPerformance, message];
}

class UserPerformanceUpdated extends UserPerformanceState {
  final UserPerformanceEntity userPerformance;
  final String message;

  const UserPerformanceUpdated({
    required this.userPerformance,
    this.message = 'User performance updated successfully',
  });

  @override
  List<Object?> get props => [userPerformance, message];
}

class UserPerformanceDeleted extends UserPerformanceState {
  final String userId;
  final String message;

  const UserPerformanceDeleted({
    required this.userId,
    this.message = 'User performance deleted successfully',
  });

  @override
  List<Object?> get props => [userId, message];
}

class AccuracyRecalculated extends UserPerformanceState {
  final String userId;
  final double newAccuracy;
  final String message;

  const AccuracyRecalculated({
    required this.userId,
    required this.newAccuracy,
    this.message = 'Delivery accuracy recalculated successfully',
  });

  @override
  List<Object?> get props => [userId, newAccuracy, message];
}

class UserPerformanceError extends UserPerformanceState {
  final String message;
  final String? errorCode;
  final bool isNetworkError;

  const UserPerformanceError({
    required this.message,
    this.errorCode,
    this.isNetworkError = false,
  });

  @override
  List<Object?> get props => [message, errorCode, isNetworkError];
}

class UserPerformanceEmpty extends UserPerformanceState {
  final String message;

  const UserPerformanceEmpty({
    this.message = 'No user performance data found',
  });

  @override
  List<Object?> get props => [message];
}

class UserPerformanceOffline extends UserPerformanceState {
  final UserPerformanceEntity? cachedUserPerformance;
  final String message;

  const UserPerformanceOffline({
    this.cachedUserPerformance,
    this.message = 'Using cached data - No internet connection',
  });

  @override
  List<Object?> get props => [cachedUserPerformance, message];
}
