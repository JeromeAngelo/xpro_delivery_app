import 'package:equatable/equatable.dart';

abstract class InvoiceStatusEvent extends Equatable {
  const InvoiceStatusEvent();

  @override
  List<Object> get props => [];
}

class GetAllInvoiceStatusEvent extends InvoiceStatusEvent {}

class GetInvoiceStatusByIdEvent extends InvoiceStatusEvent {
  final String id;

  const GetInvoiceStatusByIdEvent(this.id);

  @override
  List<Object> get props => [id];
}

class ExportInvoiceStatusToCsvEvent extends InvoiceStatusEvent {}

class ExportInvoiceStatusToExcelEvent extends InvoiceStatusEvent {}
