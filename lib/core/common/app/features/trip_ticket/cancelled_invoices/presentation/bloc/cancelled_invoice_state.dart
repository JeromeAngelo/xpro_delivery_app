import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';

abstract class CancelledInvoiceState extends Equatable {
  const CancelledInvoiceState();

  @override
  List<Object> get props => [];
}

class CancelledInvoiceInitial extends CancelledInvoiceState {
  const CancelledInvoiceInitial();
}

class CancelledInvoiceLoading extends CancelledInvoiceState {
  const CancelledInvoiceLoading();
}

class CancelledInvoicesLoaded extends CancelledInvoiceState {
  final List<CancelledInvoiceEntity> cancelledInvoices;

  const CancelledInvoicesLoaded(this.cancelledInvoices);

  @override
  List<Object> get props => [cancelledInvoices];
}

class SpecificCancelledInvoiceLoaded extends CancelledInvoiceState {
  final CancelledInvoiceEntity cancelledInvoice;

  const SpecificCancelledInvoiceLoaded(this.cancelledInvoice);

  @override
  List<Object> get props => [cancelledInvoice];
}

class CancelledInvoiceCreated extends CancelledInvoiceState {
  final CancelledInvoiceEntity cancelledInvoice;

  const CancelledInvoiceCreated(this.cancelledInvoice);

  @override
  List<Object> get props => [cancelledInvoice];
}

class CancelledInvoiceDeleted extends CancelledInvoiceState {
  final String cancelledInvoiceId;

  const CancelledInvoiceDeleted(this.cancelledInvoiceId);

  @override
  List<Object> get props => [cancelledInvoiceId];
}

class CancelledInvoiceError extends CancelledInvoiceState {
  final String message;

  const CancelledInvoiceError(this.message);

  @override
  List<Object> get props => [message];
}

class CancelledInvoicesOffline extends CancelledInvoiceState {
  final List<CancelledInvoiceEntity> cancelledInvoices;
  final String message;

  const CancelledInvoicesOffline({
    required this.cancelledInvoices,
    required this.message,
  });

  @override
  List<Object> get props => [cancelledInvoices, message];
 
}

class CancelledInvoicesEmpty extends CancelledInvoiceState {
  final String tripId;

  const CancelledInvoicesEmpty(this.tripId);

  @override
  List<Object> get props => [tripId];
}