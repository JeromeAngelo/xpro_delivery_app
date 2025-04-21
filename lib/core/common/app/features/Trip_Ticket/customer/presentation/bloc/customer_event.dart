import 'package:equatable/equatable.dart';
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();
}

class GetCustomerEvent extends CustomerEvent {
  final String tripId;
  const GetCustomerEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class GetCustomerLocationEvent extends CustomerEvent {
  final String customerId;
  const GetCustomerLocationEvent(this.customerId);
  
  @override
  List<Object?> get props => [customerId];
}

class LoadLocalCustomersEvent extends CustomerEvent {
  final String tripId;
  const LoadLocalCustomersEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class LoadLocalCustomerLocationEvent extends CustomerEvent {
  final String customerId;
  const LoadLocalCustomerLocationEvent(this.customerId);
  
  @override
  List<Object?> get props => [customerId];
}

class RefreshCustomersEvent extends CustomerEvent {
  final String tripId;
  const RefreshCustomersEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}
class CalculateCustomerTotalTimeEvent extends CustomerEvent {
  final String customerId;
  
  const CalculateCustomerTotalTimeEvent(this.customerId);
  
  @override
  List<Object?> get props => [customerId];
}

