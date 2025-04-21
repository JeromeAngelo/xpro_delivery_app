import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';
abstract class PersonelEvent extends Equatable {
  const PersonelEvent();
}

class GetPersonelEvent extends PersonelEvent {
  @override
  List<Object> get props => [];
}

class SetRoleEvent extends PersonelEvent {
  final String id;
  final UserRole newRole;
  const SetRoleEvent({required this.id, required this.newRole});
  
  @override
  List<Object> get props => [id, newRole];
}

class LoadPersonelsByTripIdEvent extends PersonelEvent {
  final String tripId;
  const LoadPersonelsByTripIdEvent(this.tripId);
  
  @override
  List<Object> get props => [tripId];
}

class LoadPersonelsByDeliveryTeamEvent extends PersonelEvent {
  final String deliveryTeamId;
  const LoadPersonelsByDeliveryTeamEvent(this.deliveryTeamId);
  
  @override
  List<Object> get props => [deliveryTeamId];
}

class LoadLocalPersonelsByTripIdEvent extends PersonelEvent {
  final String tripId;
  const LoadLocalPersonelsByTripIdEvent(this.tripId);
  
  @override
  List<Object> get props => [tripId];
}

class LoadLocalPersonelsByDeliveryTeamEvent extends PersonelEvent {
  final String deliveryTeamId;
  const LoadLocalPersonelsByDeliveryTeamEvent(this.deliveryTeamId);
  
  @override
  List<Object> get props => [deliveryTeamId];
}
