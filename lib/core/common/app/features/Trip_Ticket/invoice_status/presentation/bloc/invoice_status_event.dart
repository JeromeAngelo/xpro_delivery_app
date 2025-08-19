import 'package:equatable/equatable.dart';

abstract class InvoiceStatusEvent extends Equatable {
  const InvoiceStatusEvent();

  @override
  List<Object?> get props => [];
}

// Event for getting invoice status by invoice ID
class GetInvoiceStatusByInvoiceIdEvent extends InvoiceStatusEvent {
  final String invoiceId;

  const GetInvoiceStatusByInvoiceIdEvent(this.invoiceId);

  @override
  List<Object?> get props => [invoiceId];
}

// Event for getting local invoice status by invoice ID
class GetLocalInvoiceStatusByInvoiceIdEvent extends InvoiceStatusEvent {
  final String invoiceId;

  const GetLocalInvoiceStatusByInvoiceIdEvent(this.invoiceId);

  @override
  List<Object?> get props => [invoiceId];
}
