import 'dart:typed_data';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/entity/transaction_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class TransactionRepo {
  const TransactionRepo();

  // Get all transactions for a specific customer
  ResultFuture<List<TransactionEntity>> getTransactions(String customerId);

  // Get all transactions for a specific customer
  ResultFuture<List<TransactionEntity>> getTransactionsByCompletedCustomer(String completedCustomerId);

  // Get a single transaction by id
  ResultFuture<TransactionEntity> getTransactionById(String transactionId);

  // Create new transaction with all details
ResultFuture<void> createTransaction({
  required TransactionEntity transaction,
  required String customerId,
  
  required String tripId,
});


  // Update existing transaction
  ResultFuture<void> updateTransaction(TransactionEntity transaction);

  // Delete transaction
  ResultFuture<void> deleteTransaction(String transactionId);

  // Get transactions by date range
  ResultFuture<List<TransactionEntity>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
    String customerId,
  );

  // Generate PDF for transaction
  ResultFuture<Uint8List> generateTransactionPdf(
    CustomerEntity customer,
    List<InvoiceEntity> invoices,
  );
}
