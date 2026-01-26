import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';

abstract class CancelledInvoiceEvent extends Equatable {
  const CancelledInvoiceEvent();

  @override
  List<Object?> get props => [];
}

class LoadCancelledInvoicesByTripIdEvent extends CancelledInvoiceEvent {
  final String tripId;

  const LoadCancelledInvoicesByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class LoadLocalCancelledInvoicesByTripIdEvent extends CancelledInvoiceEvent {
  final String tripId;

  const LoadLocalCancelledInvoicesByTripIdEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class LoadCancelledInvoicesByIdEvent extends CancelledInvoiceEvent {
  final String id;

  const LoadCancelledInvoicesByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadLocalCancelledInvoicesByIdEvent extends CancelledInvoiceEvent {
  final String id;

  const LoadLocalCancelledInvoicesByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateCancelledInvoiceByDeliveryDataIdEvent extends CancelledInvoiceEvent {
  final String deliveryDataId;
  final UndeliverableReason reason;
  final String? image;

  const CreateCancelledInvoiceByDeliveryDataIdEvent({
    required this.deliveryDataId,
    required this.reason,
    this.image,
  });

  @override
  List<Object?> get props => [deliveryDataId, reason, image];
}

class DeleteCancelledInvoiceEvent extends CancelledInvoiceEvent {
  final String cancelledInvoiceId;

  const DeleteCancelledInvoiceEvent(this.cancelledInvoiceId);

  @override
  List<Object?> get props => [cancelledInvoiceId];
}

class SyncCancelledInvoiceEvent extends CancelledInvoiceEvent {
  final String cancelledInvoiceId;

  const SyncCancelledInvoiceEvent(this.cancelledInvoiceId);

  @override
  List<Object?> get props => [cancelledInvoiceId];
}

class RefreshCancelledInvoicesEvent extends CancelledInvoiceEvent {
  final String tripId;

  const RefreshCancelledInvoicesEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}