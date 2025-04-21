import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/entity/transaction_entity.dart';
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class CreateTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;
  final String customerId;
  final String tripId;

  const CreateTransactionEvent({
    required this.transaction,
    required this.customerId,
    required this.tripId,
  });

  @override
  List<Object?> get props => [transaction, customerId, tripId];
}


// Add local transaction events
class GetLocalTransactionsEvent extends TransactionEvent {
  final String customerId;
  const GetLocalTransactionsEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class GetLocalTransactionByIdEvent extends TransactionEvent {
  final String transactionId;
  const GetLocalTransactionByIdEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class GetLocalTransactionsByDateRangeEvent extends TransactionEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String customerId;

  const GetLocalTransactionsByDateRangeEvent({
    required this.startDate,
    required this.endDate,
    required this.customerId,
  });

  @override
  List<Object?> get props => [startDate, endDate, customerId];
}

// Existing remote events
class GetTransactionsEvent extends TransactionEvent {
  final String customerId;
  const GetTransactionsEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class GetTransactionByIdEvent extends TransactionEvent {
  final String transactionId;
  const GetTransactionByIdEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class GetTransactionsByDateRangeEvent extends TransactionEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String customerId;

  const GetTransactionsByDateRangeEvent({
    required this.startDate,
    required this.endDate,
    required this.customerId,
  });

  @override
  List<Object?> get props => [startDate, endDate, customerId];
}

class UpdateTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;
  const UpdateTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String transactionId;
  const DeleteTransactionEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class GetTransactionsByCompletedCustomerEvent extends TransactionEvent {
  final String completedCustomerId;
  const GetTransactionsByCompletedCustomerEvent(this.completedCustomerId);

  @override
  List<Object?> get props => [completedCustomerId];
}

class GenerateTransactionPdfEvent extends TransactionEvent {
  final CustomerEntity customer;
  final List<InvoiceEntity> invoices;

  const GenerateTransactionPdfEvent({
    required this.customer,
    required this.invoices,
  });

  @override
  List<Object?> get props => [customer, invoices];
}
