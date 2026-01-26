import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/return_items/domain/entity/return_items_entity.dart';

abstract class ReturnItemsEvent extends Equatable {
  const ReturnItemsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to get return items by trip ID (remote with local fallback)
class GetReturnItemsByTripIdEvent extends ReturnItemsEvent {
  const GetReturnItemsByTripIdEvent(this.tripId);

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

/// Event to load return items from local storage by trip ID
class LoadLocalReturnItemsByTripIdEvent extends ReturnItemsEvent {
  const LoadLocalReturnItemsByTripIdEvent(this.tripId);

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

/// Event to get a specific return item by ID (remote with local fallback)
class GetReturnItemByIdEvent extends ReturnItemsEvent {
  const GetReturnItemByIdEvent(this.returnItemId);

  final String returnItemId;

  @override
  List<Object?> get props => [returnItemId];
}

/// Event to get a specific return item from local storage by ID
class GetReturnItemByLocalIdEvent extends ReturnItemsEvent {
  const GetReturnItemByLocalIdEvent(this.returnItemId);

  final String returnItemId;

  @override
  List<Object?> get props => [returnItemId];
}

/// Event to add return items to a delivery
class AddItemsToReturnItemsByDeliveryIdEvent extends ReturnItemsEvent {
  const AddItemsToReturnItemsByDeliveryIdEvent({
    required this.deliveryId,
    required this.returnItem,
  });

  final String deliveryId;
  final ReturnItemsEntity returnItem;

  @override
  List<Object?> get props => [deliveryId, returnItem];
}

/// Event to sync return items for a trip
class SyncReturnItemsForTripEvent extends ReturnItemsEvent {
  const SyncReturnItemsForTripEvent(this.tripId);

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

/// Event to clear return items cache
class ClearReturnItemsCacheEvent extends ReturnItemsEvent {
  const ClearReturnItemsCacheEvent();
}

/// Event to get return items cache statistics
class GetReturnItemsCacheStatsEvent extends ReturnItemsEvent {
  const GetReturnItemsCacheStatsEvent();
}

/// Event to get return items count for a trip
class GetReturnItemsCountForTripEvent extends ReturnItemsEvent {
  const GetReturnItemsCountForTripEvent(this.tripId);

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}
