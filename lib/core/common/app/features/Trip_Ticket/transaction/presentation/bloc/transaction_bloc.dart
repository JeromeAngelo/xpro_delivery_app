import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/create_transaction_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/delete_transaction_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/generate_pdf.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/get_transaction_by_completed_customer.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/get_transaction_by_date_range_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/get_transaction_by_id_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/get_transaction_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/domain/usecase/update_transaction_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/presentation/bloc/transaction_state.dart';
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final CreateTransactionUseCase _createTransaction;
  final DeleteTransactionUseCase _deleteTransaction;
  final GetTransactionByIdUseCase _getTransactionById;
  final GetTransactionUseCase _getTransactions;
  final GetTransactionByDateRangeUseCase _getTransactionsByDateRange;
  final UpdateTransactionUseCase _updateTransaction;
  final GetTransactionsByCompletedCustomer _getTransactionsByCompletedCustomer;
  final GenerateTransactionPdf _generateTransactionPdf;

  TransactionBloc({
    required CreateTransactionUseCase createTransaction,
    required DeleteTransactionUseCase deleteTransaction,
    required GetTransactionByIdUseCase getTransactionById,
    required GetTransactionUseCase getTransactions,
    required GetTransactionByDateRangeUseCase getTransactionsByDateRange,
    required UpdateTransactionUseCase updateTransaction,
    required GenerateTransactionPdf generateTransactionPdf,
    required GetTransactionsByCompletedCustomer getTransactionsByCompletedCustomer,
  })  : _createTransaction = createTransaction,
        _generateTransactionPdf = generateTransactionPdf,
        _deleteTransaction = deleteTransaction,
        _getTransactionById = getTransactionById,
        _getTransactions = getTransactions,
        _getTransactionsByDateRange = getTransactionsByDateRange,
        _updateTransaction = updateTransaction,
        _getTransactionsByCompletedCustomer = getTransactionsByCompletedCustomer,
        super(TransactionInitial()) {
    on<CreateTransactionEvent>(_createTransactionHandler);
    on<DeleteTransactionEvent>(_deleteTransactionHandler);
    on<GetTransactionByIdEvent>(_getTransactionByIdHandler);
    on<GetTransactionsEvent>(_getTransactionsHandler);
    on<GetTransactionsByDateRangeEvent>(_getTransactionsByDateRangeHandler);
    on<UpdateTransactionEvent>(_updateTransactionHandler);
    on<GetTransactionsByCompletedCustomerEvent>(_getTransactionsByCompletedCustomerHandler);
    on<GenerateTransactionPdfEvent>(_generatePdfHandler);
  }

  Future<void> _createTransactionHandler(
    CreateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    debugPrint('🔄 Creating transaction');

    final result = await _createTransaction(
      CreateTransactionParams(
        transaction: event.transaction,
        customerId: event.customerId,
        tripId: event.tripId,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Transaction creation failed: ${failure.message}');
        emit(TransactionError(failure.message));
      },
      (_) {
        debugPrint('✅ Transaction created successfully');
        emit(TransactionCreated());
      },
    );
  }

  Future<void> _generatePdfHandler(
    GenerateTransactionPdfEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(PdfGenerating());
    debugPrint('📄 Starting PDF generation');

    final result = await _generateTransactionPdf(
      GeneratePdfParams(
        customer: event.customer,
        invoices: event.invoices,
      ),
    );

    result.fold(
      (failure) {
        debugPrint('❌ PDF generation failed: ${failure.message}');
        emit(PdfGenerationError(failure.message));
      },
      (pdfBytes) {
        debugPrint('✅ PDF generated successfully');
        emit(PdfGenerated(pdfBytes));
      },
    );
  }

  Future<void> _deleteTransactionHandler(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await _deleteTransaction(event.transactionId);
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (_) => emit(TransactionDeleted()),
    );
  }

  Future<void> _getTransactionByIdHandler(
    GetTransactionByIdEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await _getTransactionById(event.transactionId);
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transaction) => emit(TransactionLoaded(transaction)),
    );
  }

  Future<void> _getTransactionsHandler(
    GetTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await _getTransactions(event.customerId);
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) => emit(TransactionsLoaded(transactions)),
    );
  }

  Future<void> _getTransactionsByDateRangeHandler(
    GetTransactionsByDateRangeEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await _getTransactionsByDateRange(
      GetTransactionByDateRangeParams(
        startDate: event.startDate,
        endDate: event.endDate,
        customerId: event.customerId,
      ),
    );
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) => emit(TransactionsLoaded(transactions)),
    );
  }

  Future<void> _updateTransactionHandler(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await _updateTransaction(event.transaction);
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (_) => emit(TransactionUpdated()),
    );
  }

  Future<void> _getTransactionsByCompletedCustomerHandler(
    GetTransactionsByCompletedCustomerEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await _getTransactionsByCompletedCustomer(event.completedCustomerId);
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) => emit(TransactionsLoaded(transactions)),
    );
  }
}
