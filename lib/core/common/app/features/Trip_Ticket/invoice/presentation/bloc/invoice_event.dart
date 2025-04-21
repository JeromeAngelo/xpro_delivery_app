import 'package:equatable/equatable.dart';
abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  
  @override
  List<Object?> get props => [];
}

class GetInvoiceEvent extends InvoiceEvent {
  const GetInvoiceEvent();
}

class LoadLocalInvoiceEvent extends InvoiceEvent {
  const LoadLocalInvoiceEvent();
}

class GetInvoicesByTripEvent extends InvoiceEvent {
  final String tripId;
  const GetInvoicesByTripEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class LoadLocalInvoicesByTripEvent extends InvoiceEvent {
  final String tripId;
  const LoadLocalInvoicesByTripEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class GetInvoicesByCustomerEvent extends InvoiceEvent {
  final String customerId;
  const GetInvoicesByCustomerEvent(this.customerId);
  
  @override
  List<Object?> get props => [customerId];
}

class LoadLocalInvoicesByCustomerEvent extends InvoiceEvent {
  final String customerId;
  const LoadLocalInvoicesByCustomerEvent(this.customerId);
  
  @override
  List<Object?> get props => [customerId];
}

class RefreshInvoiceEvent extends InvoiceEvent {
  const RefreshInvoiceEvent();
}


// New event for setting all invoices to completed status
class SetAllInvoicesCompletedEvent extends InvoiceEvent {
  final String tripId;
  
  const SetAllInvoicesCompletedEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}