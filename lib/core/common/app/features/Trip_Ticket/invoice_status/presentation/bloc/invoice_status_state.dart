import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/domain/entity/invoice_status_entity.dart';

abstract class InvoiceStatusState extends Equatable {
  const InvoiceStatusState();

  @override
  List<Object?> get props => [];
}

class InvoiceStatusInitial extends InvoiceStatusState {
  const InvoiceStatusInitial();
}

class InvoiceStatusLoading extends InvoiceStatusState {
  const InvoiceStatusLoading();
}

class InvoiceStatusError extends InvoiceStatusState {
  final String message;
  final String? statusCode;

  const InvoiceStatusError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

// State for getting invoice status by invoice ID
class InvoiceStatusByInvoiceIdLoaded extends InvoiceStatusState {
  final List<InvoiceStatusEntity> invoiceStatus;
  final String invoiceId;

  const InvoiceStatusByInvoiceIdLoaded({
    required this.invoiceStatus,
    required this.invoiceId,
  });

  @override
  List<Object?> get props => [invoiceStatus, invoiceId];
}

// State for getting local invoice status by invoice ID
class LocalInvoiceStatusByInvoiceIdLoaded extends InvoiceStatusState {
  final List<InvoiceStatusEntity> invoiceStatus;
  final String invoiceId;

  const LocalInvoiceStatusByInvoiceIdLoaded({
    required this.invoiceStatus,
    required this.invoiceId,
  });

  @override
  List<Object?> get props => [invoiceStatus, invoiceId];
}
