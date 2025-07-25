import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/enums/user_role.dart';
import 'package:equatable/equatable.dart';

abstract class PersonelState extends Equatable {
  const PersonelState();

  @override
  List<Object> get props => [];
}

class PersonelInitial extends PersonelState {
  const PersonelInitial();
}

class PersonelLoading extends PersonelState {
  const PersonelLoading();
}

class PersonelLoaded extends PersonelState {
  final List<PersonelEntity> personel;
  const PersonelLoaded(this.personel);

  @override
  List<Object> get props => [personel];
}

class PersonelsByTripLoaded extends PersonelState {
  final List<PersonelEntity> personel;
  const PersonelsByTripLoaded(this.personel);

  @override
  List<Object> get props => [personel];
}

class PersonelsByDeliveryTeamLoaded extends PersonelState {
  final List<PersonelEntity> personel;
  const PersonelsByDeliveryTeamLoaded(this.personel);

  @override
  List<Object> get props => [personel];
}

class PersonelLoadedById extends PersonelState {
  final PersonelEntity personel;
  const PersonelLoadedById(this.personel);

  @override
  List<Object> get props => [personel];
}

class SetRoleState extends PersonelState {
  final UserRole role;
  const SetRoleState(this.role);

  @override
  List<Object> get props => [role];
}

// New states for CRUD operations
class PersonelCreated extends PersonelState {
  final PersonelEntity personel;
  const PersonelCreated(this.personel);

  @override
  List<Object> get props => [personel];
}

class PersonelUpdated extends PersonelState {
  final PersonelEntity personel;
  const PersonelUpdated(this.personel);

  @override
  List<Object> get props => [personel];
}

class PersonelDeleted extends PersonelState {
  final String personelId;
  const PersonelDeleted(this.personelId);

  @override
  List<Object> get props => [personelId];
}

class AllPersonelsDeleted extends PersonelState {
  final List<String> personelIds;
  const AllPersonelsDeleted(this.personelIds);

  @override
  List<Object> get props => [personelIds];
}

class PersonelError extends PersonelState {
  final String message;
  const PersonelError(this.message);

  @override
  List<Object> get props => [message];
}
