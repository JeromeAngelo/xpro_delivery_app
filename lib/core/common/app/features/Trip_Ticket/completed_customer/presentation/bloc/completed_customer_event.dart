import 'package:equatable/equatable.dart';
abstract class CompletedCustomerEvent extends Equatable {
  const CompletedCustomerEvent();

  @override
  List<Object> get props => [];
}

class GetCompletedCustomerEvent extends CompletedCustomerEvent {
  final String tripId;
  const GetCompletedCustomerEvent(this.tripId);

  @override
  List<Object> get props => [tripId];
}

class GetCompletedCustomerByIdEvent extends CompletedCustomerEvent {
  final String customerId;
  const GetCompletedCustomerByIdEvent(this.customerId);
  
  @override
  List<Object> get props => [customerId];
}

class LoadLocalCompletedCustomerEvent extends CompletedCustomerEvent {
  final String tripId;
  const LoadLocalCompletedCustomerEvent(this.tripId);

  @override
  List<Object> get props => [tripId];
}

class LoadLocalCompletedCustomerByIdEvent extends CompletedCustomerEvent {
  final String customerId;
  const LoadLocalCompletedCustomerByIdEvent(this.customerId);
  
  @override
  List<Object> get props => [customerId];
}

