import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/entity/completed_customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_state.dart';

abstract class CompletedCustomerState extends Equatable {
  const CompletedCustomerState();

  @override
  List<Object> get props => [];
}

class CompletedCustomerInitial extends CompletedCustomerState {
  const CompletedCustomerInitial();
}

class CompletedCustomerLoading extends CompletedCustomerState {
  const CompletedCustomerLoading();
}


class CompletedCustomerLoaded extends CompletedCustomerState {
  final List<CompletedCustomerEntity> customers;
  final InvoiceState invoice;
  final bool isFromLocal;
  
  const CompletedCustomerLoaded({
    required this.customers,
    required this.invoice,
    this.isFromLocal = false,
  });
  
  @override
  List<Object> get props => [customers, invoice, isFromLocal];
}

class CompletedCustomerByIdLoaded extends CompletedCustomerState {
  final CompletedCustomerEntity customer;
  
  const CompletedCustomerByIdLoaded(this.customer);
  
  @override
  List<Object> get props => [customer];
}

class CompletedCustomerError extends CompletedCustomerState {
  final String message;
  
  const CompletedCustomerError(this.message);
  
  @override
  List<Object> get props => [message];
}
