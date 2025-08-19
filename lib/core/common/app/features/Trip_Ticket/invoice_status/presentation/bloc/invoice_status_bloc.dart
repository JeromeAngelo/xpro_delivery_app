import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/domain/usecase/get_invoice_status_by_invoice_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/presentation/bloc/invoice_status_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/presentation/bloc/invoice_status_state.dart';

class InvoiceStatusBloc extends Bloc<InvoiceStatusEvent, InvoiceStatusState> {
  final GetInvoiceStatusByInvoiceId _getInvoiceStatusByInvoiceId;

  InvoiceStatusState? _cachedState;

  InvoiceStatusBloc({
    required GetInvoiceStatusByInvoiceId getInvoiceStatusByInvoiceId,
  }) : _getInvoiceStatusByInvoiceId = getInvoiceStatusByInvoiceId,
       super(const InvoiceStatusInitial()) {
    on<GetInvoiceStatusByInvoiceIdEvent>(_onGetInvoiceStatusByInvoiceId);
    on<GetLocalInvoiceStatusByInvoiceIdEvent>(_onGetLocalInvoiceStatusByInvoiceId);
  }

  Future<void> _onGetInvoiceStatusByInvoiceId(
    GetInvoiceStatusByInvoiceIdEvent event,
    Emitter<InvoiceStatusState> emit,
  ) async {
    emit(const InvoiceStatusLoading());
    debugPrint('🔄 BLOC: Getting invoice status for invoice ID: ${event.invoiceId}');

    final result = await _getInvoiceStatusByInvoiceId(event.invoiceId);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get invoice status: ${failure.message}');
        emit(InvoiceStatusError(message: failure.message, statusCode: failure.statusCode));
      },
      (invoiceStatus) {
        debugPrint('✅ BLOC: Successfully retrieved ${invoiceStatus.length} invoice status records');
        final newState = InvoiceStatusByInvoiceIdLoaded(
          invoiceStatus: invoiceStatus,
          invoiceId: event.invoiceId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetLocalInvoiceStatusByInvoiceId(
    GetLocalInvoiceStatusByInvoiceIdEvent event,
    Emitter<InvoiceStatusState> emit,
  ) async {
    emit(const InvoiceStatusLoading());
    debugPrint('🔄 BLOC: Getting local invoice status for invoice ID: ${event.invoiceId}');

    // For local data, we can use the same usecase with loadFromLocal if available
    // or create a separate usecase for local-only operations
    final result = await _getInvoiceStatusByInvoiceId(event.invoiceId);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get local invoice status: ${failure.message}');
        emit(InvoiceStatusError(message: failure.message, statusCode: failure.statusCode));
      },
      (invoiceStatus) {
        debugPrint('✅ BLOC: Successfully retrieved ${invoiceStatus.length} local invoice status records');
        final newState = LocalInvoiceStatusByInvoiceIdLoaded(
          invoiceStatus: invoiceStatus,
          invoiceId: event.invoiceId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
