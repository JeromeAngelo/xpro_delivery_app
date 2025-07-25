import 'package:xpro_delivery_admin_app/core/enums/user_role.dart';
import 'package:equatable/equatable.dart';

abstract class PersonelEvent extends Equatable {
  const PersonelEvent();
}

class GetPersonelEvent extends PersonelEvent {
  @override
  List<Object> get props => [];
}

class GetPersonelByIdEvent extends PersonelEvent {
  final String personelId;
  const GetPersonelByIdEvent(this.personelId);
  
  @override
  List<Object> get props => [personelId];
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

// New events for CRUD operations
class CreatePersonelEvent extends PersonelEvent {
  final String name;
  final UserRole role;
  final String? deliveryTeamId;
  final String? tripId;
  
  const CreatePersonelEvent({
    required this.name,
    required this.role,
    this.deliveryTeamId,
    this.tripId,
  });
  
  @override
  List<Object?> get props => [name, role, deliveryTeamId, tripId];
}

class UpdatePersonelEvent extends PersonelEvent {
  final String personelId;
  final String? name;
  final UserRole? role;
  final String? deliveryTeamId;
  final String? tripId;
  
  const UpdatePersonelEvent({
    required this.personelId,
    this.name,
    this.role,
    this.deliveryTeamId,
    this.tripId,
  });
  
  @override
  List<Object?> get props => [personelId, name, role, deliveryTeamId, tripId];
}

class DeletePersonelEvent extends PersonelEvent {
  final String personelId;
  
  const DeletePersonelEvent(this.personelId);
  
  @override
  List<Object> get props => [personelId];
}

class DeleteAllPersonelsEvent extends PersonelEvent {
  final List<String> personelIds;
  
  const DeleteAllPersonelsEvent(this.personelIds);
  
  @override
  List<Object> get props => [personelIds];
}
