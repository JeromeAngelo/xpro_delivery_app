import 'package:equatable/equatable.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';

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

/// State when all delivery data with trips is loaded
class AllDeliveryDataWithTripsLoaded extends DeliveryDataState {
  final List<DeliveryDataEntity> deliveryData;

  const AllDeliveryDataWithTripsLoaded(this.deliveryData);

  @override
  List<Object?> get props => [deliveryData];
}

/// State when delivery data is successfully added to trip
class DeliveryDataAddedToTrip extends DeliveryDataState {
  final String tripId;

  const DeliveryDataAddedToTrip(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

