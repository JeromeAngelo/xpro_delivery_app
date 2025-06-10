import 'package:equatable/equatable.dart';

abstract class InvoiceDataEvent extends Equatable {
  const InvoiceDataEvent();

  @override
  List<Object?> get props => [];
}

// Event for getting all invoice data
class GetAllInvoiceDataEvent extends InvoiceDataEvent {
  const GetAllInvoiceDataEvent();
}

// Event for getting invoice data by ID
class GetInvoiceDataByIdEvent extends InvoiceDataEvent {
  final String id;

  const GetInvoiceDataByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// Event for getting invoice data by delivery ID
class GetInvoiceDataByDeliveryIdEvent extends InvoiceDataEvent {
  final String deliveryId;

  const GetInvoiceDataByDeliveryIdEvent(this.deliveryId);

  @override
  List<Object?> get props => [deliveryId];
}

// Event for getting invoice data by customer ID
class GetInvoiceDataByCustomerIdEvent extends InvoiceDataEvent {
  final String customerId;

  const GetInvoiceDataByCustomerIdEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

// Event for adding invoice data to delivery
class AddInvoiceDataToDeliveryEvent extends InvoiceDataEvent {
  final String invoiceId;
  final String deliveryId;

  const AddInvoiceDataToDeliveryEvent({
    required this.invoiceId,
    required this.deliveryId,
  });

  @override
  List<Object?> get props => [invoiceId, deliveryId];
}

// Event for adding invoice data to invoice status
class AddInvoiceDataToInvoiceStatusEvent extends InvoiceDataEvent {
  final String invoiceId;
  final String invoiceStatusId;

  const AddInvoiceDataToInvoiceStatusEvent({
    required this.invoiceId,
    required this.invoiceStatusId,
  });

  @override
  List<Object?> get props => [invoiceId, invoiceStatusId];
}
