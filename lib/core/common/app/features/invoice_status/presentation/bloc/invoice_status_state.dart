import 'package:equatable/equatable.dart';

import '../../domain/entity/invoice_status_entity.dart';

abstract class InvoiceStatusState extends Equatable {
  const InvoiceStatusState();

  @override
  List<Object?> get props => [];
}

class InvoiceStatusInitial extends InvoiceStatusState {}

class InvoiceStatusLoading extends InvoiceStatusState {}

class AllInvoiceStatusLoaded extends InvoiceStatusState {
  final List<InvoiceStatusEntity> invoiceStatusList;

  const AllInvoiceStatusLoaded(this.invoiceStatusList);

  @override
  List<Object?> get props => [invoiceStatusList];
}

class InvoiceStatusLoadedById extends InvoiceStatusState {
  final String id;

  const InvoiceStatusLoadedById(this.id);

  @override
  List<Object?> get props => [id];
}

class InvoiceStatusError extends InvoiceStatusState {
  final String message;

  const InvoiceStatusError(this.message);

  @override
  List<Object?> get props => [message];
}

class InvoiceStatusCsvExported extends InvoiceStatusState {
  final List<int> bytes;
  const InvoiceStatusCsvExported(this.bytes);

  @override
  List<Object?> get props => [bytes];
}

class InvoiceStatusExcelExported extends InvoiceStatusState {
  final List<int> bytes;
  const InvoiceStatusExcelExported(this.bytes);

  @override
  List<Object?> get props => [bytes];
}


/// ✅ EXPORT STATES
class InvoiceStatusExporting extends InvoiceStatusState {
  final String format; // "csv" or "excel"
  const InvoiceStatusExporting(this.format);

  @override
  List<Object?> get props => [format];
}

class InvoiceStatusExportSuccess extends InvoiceStatusState {
  final String format; // "csv" or "excel"
  final String? savedPath; // local path if saved
  const InvoiceStatusExportSuccess({
    required this.format,
    this.savedPath,
  });

  @override
  List<Object?> get props => [format, savedPath];
}