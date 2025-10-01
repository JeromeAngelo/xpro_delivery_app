import 'package:equatable/equatable.dart';

import '../../domain/entity/invoice_items_entity.dart';

abstract class InvoiceItemsEvent extends Equatable {
  const InvoiceItemsEvent();

  @override
  List<Object?> get props => [];
}

// Event for getting invoice items by invoice data ID
class GetInvoiceItemsByInvoiceDataIdEvent extends InvoiceItemsEvent {
  final String invoiceDataId;

  const GetInvoiceItemsByInvoiceDataIdEvent(this.invoiceDataId);

  @override
  List<Object?> get props => [invoiceDataId];
}

// Event for getting all invoice items
class GetAllInvoiceItemsEvent extends InvoiceItemsEvent {
  const GetAllInvoiceItemsEvent();
}

// Event for updating an invoice item by ID
class UpdateInvoiceItemByIdEvent extends InvoiceItemsEvent {
  final InvoiceItemsEntity invoiceItem;

  const UpdateInvoiceItemByIdEvent(this.invoiceItem);

  @override
  List<Object?> get props => [invoiceItem];
}

// New events for local functions
// Event for getting all local invoice items
class GetAllLocalInvoiceItemsEvent extends InvoiceItemsEvent {
  const GetAllLocalInvoiceItemsEvent();
}

// Event for getting local invoice items by invoice data ID
class GetLocalInvoiceItemsByInvoiceDataIdEvent extends InvoiceItemsEvent {
  final String invoiceDataId;

  const GetLocalInvoiceItemsByInvoiceDataIdEvent(this.invoiceDataId);

  @override
  List<Object?> get props => [invoiceDataId];
}
