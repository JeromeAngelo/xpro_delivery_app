import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/return_items/domain/entity/return_items_entity.dart';

abstract class ReturnItemsState extends Equatable {
  const ReturnItemsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ReturnItemsInitial extends ReturnItemsState {
  const ReturnItemsInitial();
}

/// Loading state
class ReturnItemsLoading extends ReturnItemsState {
  const ReturnItemsLoading();
}

/// State when return items are loaded successfully
class ReturnItemsLoaded extends ReturnItemsState {
  const ReturnItemsLoaded(this.returnItems);

  final List<ReturnItemsEntity> returnItems;

  @override
  List<Object?> get props => [returnItems];
}

/// State when a single return item is loaded
class ReturnItemLoaded extends ReturnItemsState {
  const ReturnItemLoaded(this.returnItem);

  final ReturnItemsEntity returnItem;

  @override
  List<Object?> get props => [returnItem];
}

/// State when return items are loaded from local storage
class LocalReturnItemsLoaded extends ReturnItemsState {
  const LocalReturnItemsLoaded(this.returnItems);

  final List<ReturnItemsEntity> returnItems;

  @override
  List<Object?> get props => [returnItems];
}

/// State when a single return item is loaded from local storage
class LocalReturnItemLoaded extends ReturnItemsState {
  const LocalReturnItemLoaded(this.returnItem);

  final ReturnItemsEntity returnItem;

  @override
  List<Object?> get props => [returnItem];
}

/// State when a return item is successfully added
class ReturnItemAdded extends ReturnItemsState {
  const ReturnItemAdded(this.returnItem);

  final ReturnItemsEntity returnItem;

  @override
  List<Object?> get props => [returnItem];
}

/// State when return items are successfully synced
class ReturnItemsSynced extends ReturnItemsState {
  const ReturnItemsSynced(this.tripId);

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

/// State when cache is cleared
class ReturnItemsCacheCleared extends ReturnItemsState {
  const ReturnItemsCacheCleared();
}

/// State when cache statistics are loaded
class ReturnItemsCacheStatsLoaded extends ReturnItemsState {
  const ReturnItemsCacheStatsLoaded(this.stats);

  final Map<String, dynamic> stats;

  @override
  List<Object?> get props => [stats];
}

/// State when return items count is loaded
class ReturnItemsCountLoaded extends ReturnItemsState {
  const ReturnItemsCountLoaded({
    required this.tripId,
    required this.count,
  });

  final String tripId;
  final int count;

  @override
  List<Object?> get props => [tripId, count];
}

/// Error state
class ReturnItemsError extends ReturnItemsState {
  const ReturnItemsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// State when no return items are found
class ReturnItemsEmpty extends ReturnItemsState {
  const ReturnItemsEmpty(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
