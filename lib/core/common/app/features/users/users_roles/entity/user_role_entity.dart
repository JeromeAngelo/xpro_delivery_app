import 'package:equatable/equatable.dart';

class UserRoleEntity extends Equatable {
  final String? id;
  final String? name;
  final List<String> permissions;

  const UserRoleEntity({
    this.id,
    this.name,
    List<String>? permissions,
  }) : permissions = permissions ?? const [];

  @override
  List<Object?> get props => [
    id,
    name,
    permissions,
  ];
}
