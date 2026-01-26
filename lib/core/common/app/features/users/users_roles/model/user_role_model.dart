import 'package:objectbox/objectbox.dart';
import '../../../../../../utils/typedefs.dart';
import '../../users_roles/entity/user_role_entity.dart';

@Entity()
class UserRoleModel extends UserRoleEntity {
  @Id(assignable: true)
  int objectBoxId = 0;

  @override
  @Property()
  String? id;

  @override
  @Property()
  String? name;

  @override
  @Property()
  List<String> permissions;

  @Property()
  String pocketbaseId;

  UserRoleModel({
    this.id,
    this.name,
    List<String>? permissions,
  })  : permissions = permissions ?? [],
        pocketbaseId = id ?? '' {
    // pocketbaseId initialized safely
  }

  /// --- From JSON ---
  factory UserRoleModel.fromJson(dynamic json) {
    return UserRoleModel(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// --- To JSON ---
  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'name': name,
      'permissions': permissions,
    };
  }

  /// --- Copy With ---
  UserRoleModel copyWith({
    String? id,
    String? name,
    List<String>? permissions,
  }) {
    return UserRoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  String toString() {
    return 'UserRoleModel(id: $id, name: $name, permissions: $permissions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRoleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
