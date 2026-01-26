import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

abstract class DeliveryDataState extends Equatable {
  const DeliveryDataState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DeliveryDataInitial extends DeliveryDataState {
  const DeliveryDataInitial();
}

/// Loading state
class DeliveryDataLoading extends DeliveryDataState {
  const DeliveryDataLoading();
}

/// Error state
class DeliveryDataError extends DeliveryDataState {
  final String message;
  final String? statusCode;

  const DeliveryDataError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// State when delivery time is calculated successfully
class DeliveryTimeCalculated extends DeliveryDataState {
  final int deliveryTimeInMinutes;
  final String deliveryId;

  const DeliveryTimeCalculated({
    required this.deliveryTimeInMinutes,
    required this.deliveryId,
  });

  @override
  List<Object?> get props => [deliveryTimeInMinutes, deliveryId];
}


/// State when all delivery data is loaded
class AllDeliveryDataLoaded extends DeliveryDataState {
  final List<DeliveryDataEntity> deliveryData;

  const AllDeliveryDataLoaded(this.deliveryData);

  @override
  List<Object?> get props => [deliveryData];
}

/// State when delivery data for a specific trip is loaded
class DeliveryDataByTripLoaded extends DeliveryDataState {
  final List<DeliveryDataEntity> deliveryData;
  final String tripId;

  const DeliveryDataByTripLoaded({
    required this.deliveryData,
    required this.tripId,
  });

  @override
  List<Object?> get props => [deliveryData, tripId];
}



class DeliveryDataByTripSynced extends DeliveryDataState {
  final List<DeliveryDataEntity> deliveryData;
  final String tripId;

  const DeliveryDataByTripSynced({
    required this.deliveryData,
    required this.tripId,
  });

  @override
  List<Object?> get props => [deliveryData, tripId];
}

/// State when a specific delivery data is loaded
class DeliveryDataLoaded extends DeliveryDataState {
  final DeliveryDataEntity deliveryData;

  const DeliveryDataLoaded(this.deliveryData);

  @override
  List<Object?> get props => [deliveryData];
}

/// State when delivery data is deleted successfully
class DeliveryDataDeleted extends DeliveryDataState {
  final String id;

  const DeliveryDataDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

/// State when delivery data is synced successfully by trip ID
class DeliveryDataSyncedByTrip extends DeliveryDataState {
  final List<DeliveryDataEntity> deliveryData;
  final String tripId;

  const DeliveryDataSyncedByTrip({
    required this.deliveryData,
    required this.tripId,
  });

  @override
  List<Object?> get props => [deliveryData, tripId];
}

/// State when invoice is successfully set to unloading
class InvoiceSetToUnloading extends DeliveryDataState {
  final DeliveryDataEntity deliveryData;
  final String deliveryDataId;

  const InvoiceSetToUnloading({
    required this.deliveryData,
    required this.deliveryDataId,
  });

  @override
  List<Object?> get props => [deliveryData, deliveryDataId];
}

/// State when invoice is successfully set to unloading
class InvoiceSetToUnloaded extends DeliveryDataState {
  final DeliveryDataEntity deliveryData;
  final String deliveryDataId;

  const InvoiceSetToUnloaded({
    required this.deliveryData,
    required this.deliveryDataId,
  });

  @override
  List<Object?> get props => [deliveryData, deliveryDataId];
}

/// State when invoice is successfully set to unloading
class InvoiceSetToCompleted extends DeliveryDataState {
  final DeliveryDataEntity deliveryData;
  final String deliveryDataId;

  const InvoiceSetToCompleted({
    required this.deliveryData,
    required this.deliveryDataId,
  });

  @override
  List<Object?> get props => [deliveryData, deliveryDataId];
}

/// State when delivery location is successfully updated
class DeliveryLocationUpdated extends DeliveryDataState {
  final DeliveryDataEntity deliveryData;
  final String deliveryDataId;
  final double latitude;
  final double longitude;

  const DeliveryLocationUpdated({
    required this.deliveryData,
    required this.deliveryDataId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [deliveryData, deliveryDataId, latitude, longitude];
}

/// 🔵 Loading / Watching in progress
class DeliveryDataWatching extends DeliveryDataState {}

class DeliveryDataByTripWatched extends DeliveryDataState {
  final List<DeliveryDataEntity> deliveryData;
  final String tripId;

  const DeliveryDataByTripWatched({
    required this.deliveryData,
    required this.tripId,
  });

  @override
  List<Object?> get props => [deliveryData, tripId];
}

class AllDeliveryDataWatched extends DeliveryDataState {
  final List<DeliveryDataEntity> deliveryData;

  const AllDeliveryDataWatched({
    required this.deliveryData,
  });

  @override
  List<Object?> get props => [deliveryData];
}

/// 🟢 Successfully received local data updates
class DeliveryDataUpdated extends DeliveryDataState {
  final List<DeliveryDataEntity> deliveryDataList;

  const DeliveryDataUpdated(this.deliveryDataList);

  @override
  List<Object?> get props => [deliveryDataList];
}

/// 🔴 Error while watching local delivery data
class DeliveryDataWatchError extends DeliveryDataState {
  final String message;

  const DeliveryDataWatchError(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryDataByIdWatched extends DeliveryDataState {
  final DeliveryDataEntity? deliveryData;
  final String deliveryId;

  const DeliveryDataByIdWatched({
    required this.deliveryData,
    required this.deliveryId,
  });

  @override
  List<Object?> get props => [deliveryData, deliveryId];
}
