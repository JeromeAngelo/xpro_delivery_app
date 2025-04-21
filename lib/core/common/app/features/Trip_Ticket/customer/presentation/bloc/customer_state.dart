import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_state.dart';
abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLocationLoading extends CustomerState {}

class CustomerLocationLoaded extends CustomerState {
  final CustomerEntity customer;
  final bool isFromLocal;
  
  const CustomerLocationLoaded(this.customer, {this.isFromLocal = false});
  
  @override
  List<Object> get props => [customer, isFromLocal];
}

class CustomerLoaded extends CustomerState {
  final List<CustomerEntity> customer;
  final InvoiceState invoice;
  final DeliveryUpdateState deliveryUpdate;
  final bool isFromLocal;

  const CustomerLoaded({
    required this.customer,
    required this.invoice,
    required this.deliveryUpdate,
    this.isFromLocal = false,
  });

  @override
  List<Object> get props => [customer, invoice, deliveryUpdate, isFromLocal];
}

class CustomerError extends CustomerState {
  final String message;
  final bool isLocalError;
  
  const CustomerError(this.message, {this.isLocalError = false});
  
  @override
  List<Object> get props => [message, isLocalError];
}

class CustomerTotalTimeCalculated extends CustomerState {
  final String totalTime;
  final String customerId;
  
  const CustomerTotalTimeCalculated({
    required this.totalTime,
    required this.customerId,
  });
  
  @override
  List<Object> get props => [totalTime, customerId];
}


class CustomerRefreshing extends CustomerState {}
