import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entity/users_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

   @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class SignedIn extends AuthState {
  const SignedIn(this.users);

  final LocalUser users;

  @override
  List<Object> get props => [users];
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<String> get props => [message];
}

class UserDataRefreshed extends AuthState {
  const UserDataRefreshed(this.user);

  final LocalUser user;

  @override
  List<Object> get props => [user];
}

class UserByIdLoaded extends AuthState {
  final LocalUser user;
 
  
  const UserByIdLoaded(this.user,);
  
  @override
  List<Object> get props => [user,];
}


class LocalUserDataLoaded extends AuthState {
  final LocalUser user;
  
  const LocalUserDataLoaded(this.user);
  
  @override
  List<Object> get props => [user];
}

class RemoteUserDataLoaded extends AuthState {
  final LocalUser user;
  
  const RemoteUserDataLoaded(this.user);
  
  @override
  List<Object> get props => [user];
}

class UserTripLoaded extends AuthState {
  final TripEntity trip;
  final bool isFromLocal;
  
  const UserTripLoaded(this.trip, {this.isFromLocal = false});
  
  @override
  List<Object> get props => [trip, isFromLocal];
}

class UserTripLoading extends AuthState {
  const UserTripLoading();
}


// auth_state.dart
class UserDataSyncing extends AuthState {
  const UserDataSyncing();
}

class UserDataSynced extends AuthState {
  const UserDataSynced();
  
  @override
  List<Object> get props => [];
}

class TripDataSyncing extends AuthState {
  const TripDataSyncing();
}

class TripDataSynced extends AuthState {
  const TripDataSynced();
  
  @override
  List<Object> get props => [];
}


