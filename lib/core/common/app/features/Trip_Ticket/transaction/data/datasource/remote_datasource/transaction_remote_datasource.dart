import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/enums/mode_of_payment.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class TransactionRemoteDatasource {
  Future<List<TransactionModel>> getTransactions(String customerId);
  Future<TransactionModel> getTransactionById(String id);
  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate, String customerId);
Future<TransactionModel> createTransaction({
  required TransactionModel transaction,
  required String customerId,
  required String tripId,
});
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<List<TransactionModel>> getTransactionsByCompletedCustomer(
      String completedCustomerId);
  Future<File> downloadTransactionPdf(String transactionId);
}

class TransactionRemoteDatasourceImpl implements TransactionRemoteDatasource {
  const TransactionRemoteDatasourceImpl({
    required PocketBase pocketBaseClient,
  }) : _pocketBase = pocketBaseClient;

  final PocketBase _pocketBase;
  @override
Future<TransactionModel> createTransaction({
  required TransactionModel transaction,
  required String customerId,
  required String tripId,
}) async {
  try {
    debugPrint('🔄 Creating transaction with data:');
    debugPrint('Customer ID: $customerId');
    debugPrint('Trip ID: $tripId');
    debugPrint('ModeOfPayment: ${transaction.modeOfPayment}');
    debugPrint('TotalAmount: ${transaction.totalAmount}');
    debugPrint('Invoices: ${transaction.invoices.map((inv) => inv.id).toList()}');

    final currentTime = DateTime.now().toUtc().toIso8601String();

    final body = {
      'customer': customerId,
      'customerName': transaction.customerName,
      'deliveryNumber': transaction.deliveryNumber,
      'invoice': transaction.invoices.map((inv) => inv.id).toList(),
      'status': 'completed',
      'modeOfPayment': transaction.modeOfPayment.toString().split('.').last,
      'totalAmount': transaction.totalAmount,
      'transactionDate': currentTime,
      'created': currentTime,
      'updated': currentTime,
      'isCompleted': true,
      'refNumber': transaction.refNumber,
      'trip': tripId,
    };

    debugPrint('📝 Request body prepared: $body');

    final files = <String, MultipartFile>{};

    if (transaction.signature != null) {
      final signatureBytes = await transaction.signature!.readAsBytes();
      files['signature'] = MultipartFile.fromBytes(
        'signature',
        signatureBytes,
        filename: 'signature.pdf',
        contentType: MediaType('application', 'pdf'),
      );
      debugPrint('📄 Signature file prepared: ${signatureBytes.length} bytes');
    }

    if (transaction.customerImage != null) {
      final imagePaths = transaction.customerImage!.split(',');
      for (var i = 0; i < imagePaths.length; i++) {
        final imageBytes = await File(imagePaths[i]).readAsBytes();
        files['customerImage'] = MultipartFile.fromBytes(
          'customerImage',
          imageBytes,
          filename: 'customer_image_$i.jpg',
        );
        debugPrint('📸 Customer image prepared: ${imageBytes.length} bytes');
      }
    }

    if (transaction.pdf != null) {
      final pdfBytes = await transaction.pdf!.readAsBytes();
      files['pdf'] = MultipartFile.fromBytes(
        'pdf',
        pdfBytes,
        filename: 'receipt.pdf',
        contentType: MediaType('application', 'pdf'),
      );
      debugPrint('📑 PDF file prepared: ${pdfBytes.length} bytes');
    }

    final record = await _pocketBase.collection('transactions').create(
      body: body,
      files: files.values.toList(),
    );

    // Update trip's transaction list
    await _pocketBase.collection('tripticket').update(
      tripId,
      body: {
        'transactionList+': record.id,
      },
    );

    // Update customer's transactionList
    await _pocketBase.collection('customers').update(
      customerId,
      body: {
        'transactionList+': record.id,
      },
    );

    // Update all invoices status to completed
    for (var invoice in transaction.invoices) {
      await _pocketBase.collection('invoices').update(
        invoice.id ?? '',
        body: {
          'status': 'completed',
          'customer': customerId,
          'isCompleted': true,
        },
      );
    }

    final responseMap = {
      'id': record.id,
      'collectionId': record.collectionId,
      'collectionName': record.collectionName,
      'transactionDate': currentTime,
      ...record.data,
    };

    debugPrint('✅ Transaction created successfully');
    return TransactionModel.fromJson(responseMap);
  } catch (e) {
    debugPrint('❌ Transaction creation error: ${e.toString()}');
    throw ServerException(
      message: 'Failed to create transaction: ${e.toString()}',
      statusCode: '500',
    );
  }
}


  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _pocketBase.collection('transactions').delete(id);
    } catch (e) {
      throw ServerException(
        message: 'Failed to delete transaction: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final record = await _pocketBase.collection('transactions').getOne(
            id,
            expand: 'customer,invoice',
          );
      return TransactionModel.fromJson(record.toJson());
    } catch (e) {
      throw ServerException(
        message: 'Failed to get transaction: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions(String customerId) async {
    try {
      final records = await _pocketBase.collection('transactions').getList(
            filter: 'customer = "$customerId"',
            expand: 'invoice',
          );
      return records.items
          .map((record) => TransactionModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to get transactions: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
    String customerId,
  ) async {
    try {
      final records = await _pocketBase.collection('transactions').getList(
            filter:
                'customer = "$customerId" && transactionDate >= "$startDate" && transactionDate <= "$endDate"',
            expand: 'invoice',
          );
      return records.items
          .map((record) => TransactionModel.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      throw ServerException(
        message: 'Failed to get transactions by date range: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
      TransactionModel transaction) async {
    try {
      final record = await _pocketBase.collection('transactions').update(
            transaction.id ?? '',
            body: transaction.toJson(),
          );
      return TransactionModel.fromJson(record.toJson());
    } catch (e) {
      throw ServerException(
        message: 'Failed to update transaction: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByCompletedCustomer(
      String completedCustomerId) async {
    try {
      debugPrint(
          '🔍 Fetching transactions for completed customer: $completedCustomerId');

      final records = await _pocketBase.collection('transactions').getList(
            filter: 'completedCustomer = "$completedCustomerId"',
            expand: 'invoice,customer',
          );

      final transactions = records.items.map((record) {
        final modeOfPaymentStr = record.data['modeOfPayment']?.toString() ?? '';
        final modeOfPayment = ModeOfPayment.values.firstWhere(
          (mode) => mode.toString() == 'ModeOfPayment.$modeOfPaymentStr',
          orElse: () => ModeOfPayment.cashOnDelivery,
        );

        debugPrint('📝 Creating Transaction Model:');
        debugPrint(
            '   📅 Raw Transaction Date: ${record.data['transactionDate']}');
        debugPrint('   ⏰ Created Date: ${record.created}');

        // Handle the specific ISO 8601 format with timezone
        final transactionDateStr = record.data['transactionDate'].toString();
        final DateTime transactionDate = DateTime.parse(transactionDateStr);

        final transaction = TransactionModel(
          id: record.id,
          collectionId: record.collectionId,
          collectionName: record.collectionName,
          refNumber: record.data['refNumber'],
          totalAmount: record.data['totalAmount'],
          modeOfPayment: modeOfPayment,
          transactionDate: transactionDate,
          customerModel: record.data['customer'],
          customerName: record.data['customerName'],
          deliveryNumber: record.data['deliveryNumber'],
          customerImage: record.data['customerImage'],
          isCompleted: record.data['isCompleted'],
        );

        debugPrint('✅ Transaction Model Created:');
        debugPrint(
            '   📅 Model Transaction Date: ${transaction.transactionDate}');

        return transaction;
      }).toList();

      debugPrint('✅ Found ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      debugPrint('❌ Error fetching transactions: ${e.toString()}');
      throw ServerException(
        message: 'Failed to get transactions: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<File> downloadTransactionPdf(String transactionId) async {
    try {
      debugPrint('📥 Downloading transaction PDF: $transactionId');

      final record = await _pocketBase.collection('transactions').getOne(
            transactionId,
            expand: 'customer,invoice',
          );

      if (record.data['pdf'] == null) {
        throw const ServerException(
          message: 'PDF not found for transaction',
          statusCode: '404',
        );
      }

      final pdfUrl = _pocketBase.getFileUrl(record, record.data['pdf']);
      final response = await http.get(Uri.parse(pdfUrl.toString()));

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/Transaction_$transactionId.pdf');
      await file.writeAsBytes(response.bodyBytes);

      debugPrint('✅ PDF downloaded successfully: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Failed to download PDF: $e');
      throw ServerException(
        message: 'Failed to download transaction PDF: $e',
        statusCode: '500',
      );
    }
  }
}
