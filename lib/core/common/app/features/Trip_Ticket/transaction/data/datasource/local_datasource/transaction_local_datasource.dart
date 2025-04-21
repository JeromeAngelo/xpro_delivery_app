import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/src/transcation_screeen/presentation/utils/delivery_orders_pdf.dart';

abstract class TransactionLocalDatasource {
  Future<List<TransactionModel>> getTransactions(String customerId);
  Future<TransactionModel> getTransactionById(String id);
  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate, String customerId);
 Future<void> createTransaction({
  required TransactionModel transaction,
  required String customerId,
  required String tripId,
})  ;
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<Uint8List> generateTransactionPdf(
    CustomerEntity customer,
    List<InvoiceEntity> invoices,
  );
  Future<List<TransactionModel>> getTransactionsByCompletedCustomer(
      String completedCustomerId);
}

class TransactionLocalDatasourceImpl implements TransactionLocalDatasource {
  final Box<TransactionModel> _transactionBox;
  final Box<CustomerModel> _customerBox;
  final Store _store;

  const TransactionLocalDatasourceImpl(
      this._transactionBox, this._customerBox, this._store);

  Future<void> _autoSave(TransactionModel transaction) async {
    try {
      debugPrint('🔍 Processing transaction: ${transaction.customerName}');

      final existingTransaction = _transactionBox
          .query(TransactionModel_.pocketbaseId.equals(transaction.id ?? ''))
          .build()
          .findFirst();

      if (existingTransaction != null) {
        debugPrint('🔄 Updating existing transaction');
        transaction.dbId = existingTransaction.dbId;
      } else {
        debugPrint('➕ Adding new transaction');
      }

      _transactionBox.put(transaction);
      final totalTransactions = _transactionBox.count();
      debugPrint('📊 Current total transactions: $totalTransactions');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> cleanupInvalidEntries() async {
    final invalidTransactions = _transactionBox
        .getAll()
        .where((t) => t.customerName == null || t.id!.isEmpty)
        .toList();

    if (invalidTransactions.isNotEmpty) {
      debugPrint(
          '🧹 Removing ${invalidTransactions.length} invalid transactions');
      _transactionBox
          .removeMany(invalidTransactions.map((t) => t.dbId).toList());
    }
  }
  @override
Future<void> createTransaction({
  required TransactionModel transaction,
  required String customerId,
  required String tripId,
}) async {
  try {
    debugPrint('💾 Creating transaction locally');
    debugPrint('Customer ID: $customerId');
    debugPrint('Trip ID: $tripId');
    debugPrint('Invoices: ${transaction.invoices.map((inv) => inv.id).toList()}');

    // Save transaction with relationships
    transaction.customer.target = CustomerModel(id: customerId);
    transaction.tripRef.target = TripModel(id: tripId);
    
    await _autoSave(transaction);

    // Create and save "Mark as Received" delivery status
    final deliveryStatus = DeliveryUpdateModel(
      title: "Mark as Received",
      subtitle: "Payment received and confirmed",
      time: DateTime.now(),
      isAssigned: true,
      customer: customerId,
      created: DateTime.now(),
      updated: DateTime.now(),
    );

    // Update customer's delivery status
    final customer = _customerBox
        .query(CustomerModel_.pocketbaseId.equals(customerId))
        .build()
        .findFirst();

    if (customer != null) {
      customer.deliveryStatus.add(deliveryStatus);
      _customerBox.put(customer);
      debugPrint('✅ Customer delivery status updated with Mark as Received');
    }

    debugPrint('✅ Transaction created successfully in local storage');
  } catch (e) {
    debugPrint('❌ Local transaction creation failed: ${e.toString()}');
    throw CacheException(message: e.toString());
  }
}

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      final query = _transactionBox
          .query(TransactionModel_.pocketbaseId.equals(id))
          .build();
      final results = query.find();
      if (results.isNotEmpty) {
        _transactionBox.remove(results.first.dbId);
      }
      query.close();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final query = _transactionBox
          .query(TransactionModel_.pocketbaseId.equals(id))
          .build();
      final result = query.findFirst();
      query.close();
      if (result == null) {
        throw const CacheException(message: 'Transaction not found');
      }
      return result;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions(String customerId) async {
    try {
      await cleanupInvalidEntries();
      final query = _transactionBox
          .query(TransactionModel_.customerId.equals(customerId))
          .build();
      final results = query.find();
      query.close();
      return results;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate, String customerId) async {
    try {
      final query = _transactionBox
          .query(TransactionModel_.customerId.equals(customerId).and(
              TransactionModel_.transactionDate.between(
                  startDate.millisecondsSinceEpoch,
                  endDate.millisecondsSinceEpoch)))
          .build();
      final results = query.find();
      query.close();
      return results;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      debugPrint('🔄 Updating transaction: ${transaction.customerName}');
      await _autoSave(transaction);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByCompletedCustomer(
      String completedCustomerId) async {
    try {
      debugPrint(
          '🔍 Fetching local transactions for completed customer: $completedCustomerId');

      final query = _transactionBox
          .query(
              TransactionModel_.completedCustomerId.equals(completedCustomerId))
          .build();

      final transactions = query.find();
      query.close();

      debugPrint('📊 Found ${transactions.length} local transactions');
      for (final transaction in transactions) {
        debugPrint('   💰 Transaction: ${transaction.refNumber}');
        debugPrint('   💵 Amount: ${transaction.totalAmount}');
      }

      return transactions;
    } catch (e) {
      debugPrint('❌ Local transaction fetch failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<Uint8List> generateTransactionPdf(
    CustomerEntity customer,
    List<InvoiceEntity> invoices,
  ) async {
    try {
      debugPrint(
          '📄 LOCAL: Generating PDF for customer: ${customer.storeName}');

      final pdfBytes = await DeliveryOrdersPDF.generatePDF(
        customer: customer,
        invoices: invoices,
        products: invoices.expand((i) => i.productList).toList(),
        themeColor: PdfColor.fromHex('#FFA000'),
      );

      debugPrint('✅ LOCAL: PDF generated successfully');
      return pdfBytes;
    } catch (e) {
      debugPrint('❌ LOCAL: PDF generation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
