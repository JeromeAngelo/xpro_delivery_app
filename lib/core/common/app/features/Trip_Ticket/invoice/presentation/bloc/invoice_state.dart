import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
abstract class InvoiceState extends Equatable {
  const InvoiceState();

  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}

class InvoiceLoading extends InvoiceState {}

class InvoiceLoaded extends InvoiceState {
  final List<InvoiceEntity> invoices;
  final bool isFromLocal;
  final String? tripId;
  final String? customerId;

  const InvoiceLoaded(
    this.invoices, {
    this.isFromLocal = false,
    this.tripId,
    this.customerId,
  });

  @override
  List<Object?> get props => [invoices, isFromLocal, tripId, customerId];
}

class InvoiceError extends InvoiceState {
  final String message;
  final bool isLocalError;

  const InvoiceError(this.message, {this.isLocalError = false});

  @override
  List<Object?> get props => [message, isLocalError];
}

class InvoiceRefreshing extends InvoiceState {}

class TripInvoicesLoaded extends InvoiceState {
  final List<InvoiceEntity> invoices;
  final String tripId;
  final bool isFromLocal;

  const TripInvoicesLoaded(
    this.invoices,
    this.tripId, {
    this.isFromLocal = false,
  });

  @override
  List<Object?> get props => [invoices, tripId, isFromLocal];
}

class CustomerInvoicesLoaded extends InvoiceState {
  final List<InvoiceEntity> invoices;
  final String customerId;
  final bool isFromLocal;

  const CustomerInvoicesLoaded(
    this.invoices,
    this.customerId, {
    this.isFromLocal = false,
  });

  @override
  List<Object?> get props => [invoices, customerId, isFromLocal];
}


// New state for when all invoices have been set to completed
class AllInvoicesCompletedState extends InvoiceState {
  final List<InvoiceEntity> invoices;
  final String tripId;
  
  const AllInvoicesCompletedState(this.invoices, this.tripId);
  
  @override
  List<Object?> get props => [invoices, tripId];
}
