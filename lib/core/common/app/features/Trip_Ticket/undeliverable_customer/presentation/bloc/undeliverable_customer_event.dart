import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/entity/undeliverable_customer_entity.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';

abstract class UndeliverableCustomerEvent extends Equatable {
  const UndeliverableCustomerEvent();
}

class GetUndeliverableCustomersEvent extends UndeliverableCustomerEvent {
  final String tripId;
  const GetUndeliverableCustomersEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class GetUndeliverableCustomerByIdEvent extends UndeliverableCustomerEvent {
  final String customerId;
  const GetUndeliverableCustomerByIdEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class CreateUndeliverableCustomerEvent extends UndeliverableCustomerEvent {
  final UndeliverableCustomerEntity customer;
  final String customerId;

  const CreateUndeliverableCustomerEvent(this.customer, this.customerId);

  @override
  List<Object?> get props => [customer, customerId];
}

class LoadLocalUndeliverableCustomersEvent extends UndeliverableCustomerEvent {
  final String tripId;
  const LoadLocalUndeliverableCustomersEvent(this.tripId);

  @override
  List<Object?> get props => [];
}

class SaveUndeliverableCustomerEvent extends UndeliverableCustomerEvent {
  final UndeliverableCustomerEntity customer;
  final String customerId;

  const SaveUndeliverableCustomerEvent(this.customer, this.customerId);

  @override
  List<Object?> get props => [customer, customerId];
}

class UpdateUndeliverableCustomerEvent extends UndeliverableCustomerEvent {
  final UndeliverableCustomerEntity customer;
  final String tripId;

  const UpdateUndeliverableCustomerEvent(this.customer, this.tripId);

  @override
  List<Object?> get props => [customer, tripId];
}


class DeleteUndeliverableCustomerEvent extends UndeliverableCustomerEvent {
  final String customerId;

  const DeleteUndeliverableCustomerEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class SetUndeliverableReasonEvent extends UndeliverableCustomerEvent {
  final String customerId;
  final UndeliverableReason reason;

  const SetUndeliverableReasonEvent(this.customerId, this.reason);

  @override
  List<Object?> get props => [customerId, reason];
}
