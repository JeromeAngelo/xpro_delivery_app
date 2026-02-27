import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/invoice_status/domain/usecases/export_invoice_status_csv.dart';

import '../../domain/usecases/export_invoice_status_excel.dart';
import '../../domain/usecases/get_all_invoice_status.dart';
import '../../domain/usecases/get_invoice_status_by_id.dart';
import 'invoice_status_event.dart';
import 'invoice_status_state.dart';

class InvoiceStatusBloc extends Bloc<InvoiceStatusEvent, InvoiceStatusState> {
  final GetAllInvoiceStatus _getAllInvoiceStatus;
  final GetInvoiceStatusById _getInvoiceStatusById;
  final ExportInvoiceStatusesCsv _exportInvoiceStatusesCsv;
  final ExportInvoiceStatusesExcel _exportInvoiceStatusesExcel;

  InvoiceStatusState? _cachedState;

  InvoiceStatusBloc({
    required GetAllInvoiceStatus getAllInvoiceStatus,
    required GetInvoiceStatusById getInvoiceStatusById,
    required ExportInvoiceStatusesCsv exportInvoiceStatusesCsv,
    required ExportInvoiceStatusesExcel exportInvoiceStatusesExcel,
  }) : _getAllInvoiceStatus = getAllInvoiceStatus,
       _getInvoiceStatusById = getInvoiceStatusById,
       _exportInvoiceStatusesCsv = exportInvoiceStatusesCsv,
       _exportInvoiceStatusesExcel = exportInvoiceStatusesExcel,
       super(InvoiceStatusInitial()) {
    on<GetAllInvoiceStatusEvent>(_onGetAllInvoiceStatus);
    on<GetInvoiceStatusByIdEvent>(_onGetInvoiceStatusById);
    on<ExportInvoiceStatusToCsvEvent>(_onExportInvoiceStatusesCsv);
    on<ExportInvoiceStatusToExcelEvent>(_onExportInvoiceStatusesExcel);
  }

  Future<void> _onGetAllInvoiceStatus(
    GetAllInvoiceStatusEvent event,
    Emitter<InvoiceStatusState> emit,
  ) async {
    emit(InvoiceStatusLoading());
    debugPrint('🔄 BLOC: Getting all invoice statuses');

    final result = await _getAllInvoiceStatus();
    result.fold(
      (failure) {
        debugPrint(
          '❌ BLOC: Failed to get all invoice statuses: ${failure.message}',
        );
        emit(InvoiceStatusError(failure.message));
      },
      (list) {
        debugPrint(
          '✅ BLOC: Successfully retrieved ${list.length} invoice statuses',
        );
        final newState = AllInvoiceStatusLoaded(list);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetInvoiceStatusById(
    GetInvoiceStatusByIdEvent event,
    Emitter<InvoiceStatusState> emit,
  ) async {
    emit(InvoiceStatusLoading());
    debugPrint('🔄 BLOC: Getting invoice status by ID: ${event.id}');

    final result = await _getInvoiceStatusById(event.id);
    result.fold(
      (failure) {
        debugPrint(
          '❌ BLOC: Failed to get invoice status by ID: ${failure.message}',
        );
        emit(InvoiceStatusError(failure.message));
      },
      (invoiceStatus) {
        debugPrint(
          '✅ BLOC: Successfully retrieved invoice status: ${invoiceStatus.id}',
        );

        // ⚠️ Your current state class only accepts an id (not the entity).
        // Keeping it as-is per your design:
        final newState = InvoiceStatusLoadedById(event.id);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onExportInvoiceStatusesCsv(
    ExportInvoiceStatusToCsvEvent event,
    Emitter<InvoiceStatusState> emit,
  ) async {
    emit(const InvoiceStatusExporting('csv'));
    debugPrint('📤 BLOC: Exporting invoice statuses to CSV...');

    final result = await _exportInvoiceStatusesCsv();
    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: CSV export failed: ${failure.message}');
        emit(InvoiceStatusError(failure.message));
      },
      (bytes) async {
        debugPrint('✅ BLOC: CSV bytes ready: ${bytes.length}');
        // Saving happens in UI (recommended), so just signal success.
        emit(const InvoiceStatusExportSuccess(format: 'csv'));
      },
    );
  }

  Future<void> _onExportInvoiceStatusesExcel(
    ExportInvoiceStatusToExcelEvent event,
    Emitter<InvoiceStatusState> emit,
  ) async {
    emit(const InvoiceStatusExporting('excel'));
    debugPrint('📤 BLOC: Exporting invoice statuses to Excel...');

    final result = await _exportInvoiceStatusesExcel();
    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: Excel export failed: ${failure.message}');
        emit(InvoiceStatusError(failure.message));
      },
      (bytes) async {
        debugPrint('✅ BLOC: Excel bytes ready: ${bytes.length}');
        emit(const InvoiceStatusExportSuccess(format: 'excel'));
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}

extension InvoiceStatusBlocExportHelpers on InvoiceStatusBloc {
  Future<List<int>> exportCsvBytesDirect() async {
    final result = await _exportInvoiceStatusesCsv();
    return result.fold((f) => throw Exception(f.message), (bytes) => bytes);
  }

  Future<List<int>> exportExcelBytesDirect() async {
    final result = await _exportInvoiceStatusesExcel();
    return result.fold((f) => throw Exception(f.message), (bytes) => bytes);
  }
}
