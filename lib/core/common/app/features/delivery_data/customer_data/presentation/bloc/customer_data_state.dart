import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/entity/customer_data_entity.dart';

abstract class CustomerDataState extends Equatable {
  const CustomerDataState();

  @override
  List<Object?> get props => [];
}

class CustomerDataInitial extends CustomerDataState {
  const CustomerDataInitial();
}

class CustomerDataLoading extends CustomerDataState {
  const CustomerDataLoading();
}

class CustomerDataError extends CustomerDataState {
  final String message;
  final String? statusCode;

  const CustomerDataError({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// States for getting all customer data
class AllCustomerDataLoaded extends CustomerDataState {
  final List<CustomerDataEntity> customerData;

  const AllCustomerDataLoaded(this.customerData);

  @override
  List<Object?> get props => [customerData];
}

// States for getting customer data by ID
class CustomerDataLoaded extends CustomerDataState {
  final CustomerDataEntity customerData;

  const CustomerDataLoaded(this.customerData);

  @override
  List<Object?> get props => [customerData];
}

// States for creating customer data
class CustomerDataCreated extends CustomerDataState {
  final CustomerDataEntity customerData;

  const CustomerDataCreated(this.customerData);

  @override
  List<Object?> get props => [customerData];
}

// States for updating customer data
class CustomerDataUpdated extends CustomerDataState {
  final CustomerDataEntity customerData;

  const CustomerDataUpdated(this.customerData);

  @override
  List<Object?> get props => [customerData];
}

// States for deleting customer data
class CustomerDataDeleted extends CustomerDataState {
  final String id;

  const CustomerDataDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

// States for deleting multiple customer data
class AllCustomerDataDeleted extends CustomerDataState {
  final List<String> ids;

  const AllCustomerDataDeleted(this.ids);

  @override
  List<Object?> get props => [ids];
}

// States for adding customer to delivery
class CustomerAddedToDelivery extends CustomerDataState {
  final String customerId;
  final String deliveryId;

  const CustomerAddedToDelivery({
    required this.customerId,
    required this.deliveryId,
  });

  @override
  List<Object?> get props => [customerId, deliveryId];
}

// States for getting customers by delivery ID
class CustomersByDeliveryLoaded extends CustomerDataState {
  final List<CustomerDataEntity> customers;
  final String deliveryId;

  const CustomersByDeliveryLoaded({
    required this.customers,
    required this.deliveryId,
  });

  @override
  List<Object?> get props => [customers, deliveryId];
}
