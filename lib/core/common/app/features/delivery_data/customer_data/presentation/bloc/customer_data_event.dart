import 'package:equatable/equatable.dart';

abstract class CustomerDataEvent extends Equatable {
  const CustomerDataEvent();

  @override
  List<Object?> get props => [];
}

// Event for getting all customer data
class GetAllCustomerDataEvent extends CustomerDataEvent {
  const GetAllCustomerDataEvent();
}

// Event for getting customer data by ID
class GetCustomerDataByIdEvent extends CustomerDataEvent {
  final String id;

  const GetCustomerDataByIdEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// Event for creating customer data
class CreateCustomerDataEvent extends CustomerDataEvent {
  final String name;
  final String refId;
  final String province;
  final String municipality;
  final String barangay;
  final double? longitude;
  final double? latitude;

  const CreateCustomerDataEvent({
    required this.name,
    required this.refId,
    required this.province,
    required this.municipality,
    required this.barangay,
    this.longitude,
    this.latitude,
  });

  @override
  List<Object?> get props => [
        name,
        refId,
        province,
        municipality,
        barangay,
        longitude,
        latitude,
      ];
}

// Event for updating customer data
class UpdateCustomerDataEvent extends CustomerDataEvent {
  final String id;
  final String? name;
  final String? refId;
  final String? province;
  final String? municipality;
  final String? barangay;
  final double? longitude;
  final double? latitude;

  const UpdateCustomerDataEvent({
    required this.id,
    this.name,
    this.refId,
    this.province,
    this.municipality,
    this.barangay,
    this.longitude,
    this.latitude,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        refId,
        province,
        municipality,
        barangay,
        longitude,
        latitude,
      ];
}

// Event for deleting customer data
class DeleteCustomerDataEvent extends CustomerDataEvent {
  final String id;

  const DeleteCustomerDataEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// Event for deleting multiple customer data
class DeleteAllCustomerDataEvent extends CustomerDataEvent {
  final List<String> ids;

  const DeleteAllCustomerDataEvent(this.ids);

  @override
  List<Object?> get props => [ids];
}

// Event for adding customer to delivery
class AddCustomerToDeliveryEvent extends CustomerDataEvent {
  final String customerId;
  final String deliveryId;

  const AddCustomerToDeliveryEvent({
    required this.customerId,
    required this.deliveryId,
  });

  @override
  List<Object?> get props => [customerId, deliveryId];
}

// Event for getting customers by delivery ID
class GetCustomersByDeliveryIdEvent extends CustomerDataEvent {
  final String deliveryId;

  const GetCustomersByDeliveryIdEvent(this.deliveryId);

  @override
  List<Object?> get props => [deliveryId];
}
