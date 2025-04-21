import 'package:equatable/equatable.dart';
abstract class ReturnEvent extends Equatable { 
  const ReturnEvent();

  @override
  List<Object> get props => [];
}

class GetReturnsEvent extends ReturnEvent {
  final String tripId;
  const GetReturnsEvent(this.tripId);

  @override
  List<Object> get props => [tripId];
}

class LoadLocalReturnsEvent extends ReturnEvent {
  final String tripId;
  const LoadLocalReturnsEvent(this.tripId);

  @override
  List<Object> get props => [tripId];
}

class GetReturnByCustomerIdEvent extends ReturnEvent {
  final String customerId;
  const GetReturnByCustomerIdEvent(this.customerId);

  @override
  List<Object> get props => [customerId];
}

