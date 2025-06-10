import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/entity/invoice_data_entity.dart';

abstract class InvoiceDataState extends Equatable {
  const InvoiceDataState();

  @override
  List<Object?> get props => [];
}

class InvoiceDataInitial extends InvoiceDataState {
  const InvoiceDataInitial();
}

class InvoiceDataLoading extends InvoiceDataState {
  const InvoiceDataLoading();
}

class InvoiceDataError extends InvoiceDataState {
  final String message;
  final String? statusCode;

  const InvoiceDataError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

// States for getting all invoice data
class AllInvoiceDataLoaded extends InvoiceDataState {
  final List<InvoiceDataEntity> invoiceData;

  const AllInvoiceDataLoaded(this.invoiceData);

  @override
  List<Object?> get props => [invoiceData];
}

// States for getting invoice data by ID
class InvoiceDataLoaded extends InvoiceDataState {
  final InvoiceDataEntity invoiceData;

  const InvoiceDataLoaded(this.invoiceData);

  @override
  List<Object?> get props => [invoiceData];
}

// States for getting invoice data by delivery ID
class InvoiceDataByDeliveryLoaded extends InvoiceDataState {
  final List<InvoiceDataEntity> invoiceData;
  final String deliveryId;

  const InvoiceDataByDeliveryLoaded({
    required this.invoiceData,
    required this.deliveryId,
  });

  @override
  List<Object?> get props => [invoiceData, deliveryId];
}

// States for getting invoice data by customer ID
class InvoiceDataByCustomerLoaded extends InvoiceDataState {
  final List<InvoiceDataEntity> invoiceData;
  final String customerId;

  const InvoiceDataByCustomerLoaded({
    required this.invoiceData,
    required this.customerId,
  });

  @override
  List<Object?> get props => [invoiceData, customerId];
}

// States for adding invoice data to delivery
class InvoiceDataAddedToDelivery extends InvoiceDataState {
  final String invoiceId;
  final String deliveryId;

  const InvoiceDataAddedToDelivery({
    required this.invoiceId,
    required this.deliveryId,
  });

  @override
  List<Object?> get props => [invoiceId, deliveryId];
}

// States for adding invoice data to invoice status
class InvoiceDataAddedToInvoiceStatus extends InvoiceDataState {
  final String invoiceId;
  final String invoiceStatusId;

  const InvoiceDataAddedToInvoiceStatus({
    required this.invoiceId,
    required this.invoiceStatusId,
  });

  @override
  List<Object?> get props => [invoiceId, invoiceStatusId];
}
