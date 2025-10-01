import 'package:equatable/equatable.dart';

import '../../../../Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';

abstract class DeliveryReceiptEvent extends Equatable {
  const DeliveryReceiptEvent();

  @override
  List<Object?> get props => [];
}

/// Event to get delivery receipt by trip ID from remote
class GetDeliveryReceiptByTripIdEvent extends DeliveryReceiptEvent {
  final String tripId;

  const GetDeliveryReceiptByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Event to load delivery receipt by trip ID from local storage
class LoadLocalDeliveryReceiptByTripIdEvent extends DeliveryReceiptEvent {
  final String tripId;

  const LoadLocalDeliveryReceiptByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Event to get delivery receipt by delivery data ID from remote
class GetDeliveryReceiptByDeliveryDataIdEvent extends DeliveryReceiptEvent {
  final String deliveryDataId;

  const GetDeliveryReceiptByDeliveryDataIdEvent(this.deliveryDataId);

  @override
  List<Object?> get props => [deliveryDataId];
}

/// Event to load delivery receipt by delivery data ID from local storage
class LoadLocalDeliveryReceiptByDeliveryDataIdEvent extends DeliveryReceiptEvent {
  final String deliveryDataId;

  const LoadLocalDeliveryReceiptByDeliveryDataIdEvent(this.deliveryDataId);

  @override
  List<Object?> get props => [deliveryDataId];
}

/// Event to create delivery receipt
class CreateDeliveryReceiptEvent extends DeliveryReceiptEvent {
  final String deliveryDataId;
  final String? status;
  final DateTime? dateTimeCompleted;
  final List<String>? customerImages;
   final double? amount;
  final String? customerSignature;
  final String? receiptFile;

  const CreateDeliveryReceiptEvent({
    required this.deliveryDataId,
    this.status,
    this.dateTimeCompleted,
    this.customerImages,
    this.amount,
    this.customerSignature,
    this.receiptFile,
  });

  @override
  List<Object?> get props => [
    deliveryDataId,
    status,
    dateTimeCompleted,
    customerImages,
    customerSignature,
    receiptFile,
  ];
}



/// Event to delete delivery receipt
class DeleteDeliveryReceiptEvent extends DeliveryReceiptEvent {
  final String receiptId;

  const DeleteDeliveryReceiptEvent(this.receiptId);

  @override
  List<Object?> get props => [receiptId];
}

/// Event to clear all local delivery receipts
class ClearAllLocalDeliveryReceiptsEvent extends DeliveryReceiptEvent {
  const ClearAllLocalDeliveryReceiptsEvent();
}

/// Event to get all local delivery receipts
class GetAllLocalDeliveryReceiptsEvent extends DeliveryReceiptEvent {
  const GetAllLocalDeliveryReceiptsEvent();
}

/// Event to manually cache a delivery receipt
class CacheDeliveryReceiptEvent extends DeliveryReceiptEvent {
  final String receiptId;

  const CacheDeliveryReceiptEvent(this.receiptId);

  @override
  List<Object?> get props => [receiptId];
}

class GenerateDeliveryReceiptPdfEvent extends DeliveryReceiptEvent {
  final DeliveryDataEntity deliveryData;

  const GenerateDeliveryReceiptPdfEvent(this.deliveryData);

  @override
  List<Object?> get props => [deliveryData];
}
