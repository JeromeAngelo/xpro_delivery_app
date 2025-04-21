import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/entity/undeliverable_customer_entity.dart';

abstract class UndeliverableCustomerState extends Equatable {
  const UndeliverableCustomerState();

  @override
  List<Object> get props => [];
}

class UndeliverableCustomerInitial extends UndeliverableCustomerState {}

class UndeliverableCustomerLoading extends UndeliverableCustomerState {}

class UndeliverableCustomerLoaded extends UndeliverableCustomerState {
  final List<UndeliverableCustomerEntity> customers;

  const UndeliverableCustomerLoaded(this.customers);

  @override
  List<Object> get props => [customers];
}

class UndeliverableCustomerError extends UndeliverableCustomerState {
  final String message;

  const UndeliverableCustomerError(this.message);

  @override
  List<Object> get props => [message];
}
