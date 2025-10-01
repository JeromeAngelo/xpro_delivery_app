
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class SignInEvent extends AuthEvent{
  const SignInEvent({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object> get props => [email, password];
}

class SignOutEvent extends AuthEvent {
  const SignOutEvent();

  @override
  List<Object> get props => [];
}


class RefreshUserDataEvent extends AuthEvent {
  const RefreshUserDataEvent();

  @override
  List<Object> get props => [];
}

class LoadUserByIdEvent extends AuthEvent {
  final String userId;
  
  const LoadUserByIdEvent(this.userId);
  
  @override
  List<Object> get props => [userId];
}

class LoadLocalUserByIdEvent extends AuthEvent {
  final String userId;
  
  const LoadLocalUserByIdEvent(this.userId);
  
  @override
  List<Object> get props => [userId];
}

class LoadLocalUserDataEvent extends AuthEvent {
  const LoadLocalUserDataEvent();
  
  @override
  List<Object> get props => [];
}

class LoadRemoteUserDataEvent extends AuthEvent {
  const LoadRemoteUserDataEvent();
  
  @override
  List<Object> get props => [];
}

class GetUserTripEvent extends AuthEvent {
  final String userId;
  
  const GetUserTripEvent(this.userId);
  
  @override
  List<Object> get props => [userId];
}

class LoadLocalUserTripEvent extends AuthEvent {
  final String userId;
  
  const LoadLocalUserTripEvent(this.userId);
  
  @override
  List<Object> get props => [userId];
}

// auth_event.dart
class SyncUserDataEvent extends AuthEvent {
  final String userId;
  
  const SyncUserDataEvent(this.userId);
  
  @override
  List<Object> get props => [userId];
}

class SyncUserTripDataEvent extends AuthEvent {
  final String userId;
  
  const SyncUserTripDataEvent(this.userId);
  
  @override
  List<Object> get props => [userId];
}

class RefreshUserEvent extends AuthEvent {
  const RefreshUserEvent();
  
  @override
  // TODO: implement props
  List<Object?> get props => [];
}


