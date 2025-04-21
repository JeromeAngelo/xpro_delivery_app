import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';
abstract class PersonelState extends Equatable {
  const PersonelState();

  @override
  List<Object> get props => [];
}

class PersonelInitial extends PersonelState {}

class PersonelLoading extends PersonelState {}

class PersonelLoaded extends PersonelState {
  final List<PersonelEntity> personel;
  const PersonelLoaded(this.personel);

  @override
  List<Object> get props => [personel];
}

class PersonelsByTripLoaded extends PersonelState {
  final List<PersonelEntity> personel;
  final bool isFromLocal;
  const PersonelsByTripLoaded(this.personel, {this.isFromLocal = false});

  @override
  List<Object> get props => [personel, isFromLocal];
}

class PersonelsByDeliveryTeamLoaded extends PersonelState {
  final List<PersonelEntity> personel;
  final bool isFromLocal;
  const PersonelsByDeliveryTeamLoaded(this.personel, {this.isFromLocal = false});

  @override
  List<Object> get props => [personel, isFromLocal];
}

class SetRoleState extends PersonelState {
  final UserRole role;
  const SetRoleState(this.role);

  @override
  List<Object> get props => [role];
}

class PersonelError extends PersonelState {
  final String message;
  const PersonelError(this.message);

  @override
  List<Object> get props => [message];
}
