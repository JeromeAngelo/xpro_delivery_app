import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/datasource/local_datasource/transaction_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/datasource/remote_datasource/transaction_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/entity/transaction_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/repo/transaction_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class TransactionRepoImpl extends TransactionRepo {
  final TransactionRemoteDatasource _remoteDatasource;
  final TransactionLocalDatasource _localDatasource;

  const TransactionRepoImpl(this._remoteDatasource, this._localDatasource);

  @override
  ResultFuture<void> createTransaction({
    required TransactionEntity transaction,
    required String customerId,
    required String tripId,
  }) async {
    try {
      debugPrint('🔄 Starting transaction creation flow');
      
      // 1. Save to local first
      await _localDatasource.createTransaction(
        transaction: transaction as TransactionModel,
        customerId: customerId,
        tripId: tripId,
      );
      debugPrint('✅ Transaction saved locally');

      // 2. Update local data
      await _localDatasource.updateTransaction(transaction);
      debugPrint('✅ Local data updated');

      // 3. Finally sync with remote and update local with remote data
      await _remoteDatasource.createTransaction(
        transaction: transaction,
        customerId: customerId,
        tripId: tripId,
      );
      debugPrint('✅ Remote sync completed');

      return const Right(null);
    } catch (e) {
      debugPrint('❌ Transaction operation failed: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<void> deleteTransaction(String transactionId) async {
    try {
      await _remoteDatasource.deleteTransaction(transactionId);
      await _localDatasource.deleteTransaction(transactionId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<TransactionEntity> getTransactionById(String transactionId) async {
    try {
      final result = await _remoteDatasource.getTransactionById(transactionId);
      await _localDatasource.createTransaction(
        transaction: result,
        customerId: result.customer.target?.id ?? '',
        tripId: result.tripRef.target?.id ?? '',
      );
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote fetch failed, attempting local retrieval');
      try {
        final localResult = await _localDatasource.getTransactionById(transactionId);
        return Right(localResult);
      } catch (_) {
        return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }

  @override
  ResultFuture<List<TransactionEntity>> getTransactions(String customerId) async {
    try {
      final result = await _remoteDatasource.getTransactions(customerId);
      for (var transaction in result) {
        await _localDatasource.createTransaction(
          transaction: transaction,
          customerId: customerId,
          tripId: transaction.tripRef.target?.id ?? '',
        );
      }
      return Right(result);
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote fetch failed, using local data');
      final localTransactions = await _localDatasource.getTransactions(customerId);
      if (localTransactions.isNotEmpty) {
        return Right(localTransactions);
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<TransactionEntity>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
    String customerId,
  ) async {
    try {
      final result = await _remoteDatasource.getTransactionsByDateRange(
        startDate,
        endDate,
        customerId,
      );
      for (var transaction in result) {
        await _localDatasource.createTransaction(
          transaction: transaction,
          customerId: customerId,
          tripId: transaction.tripRef.target?.id ?? '',
        );
      }
      return Right(result);
    } on ServerException catch (e) {
      final localTransactions = await _localDatasource.getTransactionsByDateRange(
        startDate,
        endDate,
        customerId,
      );
      if (localTransactions.isNotEmpty) {
        return Right(localTransactions);
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> updateTransaction(TransactionEntity transaction) async {
    try {
      await _remoteDatasource.updateTransaction(transaction as TransactionModel);
      await _localDatasource.updateTransaction(transaction);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<TransactionEntity>> getTransactionsByCompletedCustomer(
    String completedCustomerId,
  ) async {
    try {
      debugPrint('🔄 Fetching transactions for completed customer');
      final remoteTransactions = await _remoteDatasource.getTransactionsByCompletedCustomer(completedCustomerId);
      return Right(remoteTransactions);
    } on ServerException catch (_) {
      debugPrint('⚠️ Remote fetch failed, attempting local fallback');
      try {
        final localTransactions = await _localDatasource.getTransactionsByCompletedCustomer(completedCustomerId);
        debugPrint('📱 Successfully loaded from local storage');
        return Right(localTransactions);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }

  @override
  ResultFuture<Uint8List> generateTransactionPdf(
    CustomerEntity customer,
    List<InvoiceEntity> invoices,
  ) async {
    try {
      debugPrint('🔄 Starting PDF generation process');
      final pdfBytes = await _localDatasource.generateTransactionPdf(
        customer,
        invoices,
      );
      debugPrint('✅ PDF generated successfully');
      return Right(pdfBytes);
    } catch (e) {
      debugPrint('❌ PDF generation failed: ${e.toString()}');
      return Left(CacheFailure(
        message: 'Failed to generate PDF: ${e.toString()}',
        statusCode: '500',
      ));
    }
  }
}
