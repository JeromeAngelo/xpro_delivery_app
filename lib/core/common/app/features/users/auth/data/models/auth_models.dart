import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/users_roles/model/user_role_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entity/users_entity.dart';

@Entity()
class LocalUsersModel extends LocalUser {
 @Id(assignable: true)
  int objectBoxId = 0;

  // -----------------------------
  // PocketBase Remote Fields
  // -----------------------------
  @Property()
  String? pocketbaseId;

  @Property()
  String? id; // PB id

  @Property()
  String? collectionId;

  @Property()
  String? collectionName;

  @Property()
  String? email;

  @Property()
  String? profilePic;

  @Property()
  String? name;

  @Property()
  String? tripNumberId;

  // Local stored IDs for convenience
  @Property()
  String? tripId;

  @Property()
  String? deliveryTeamId;

  @Property()
  String? token;

  // -----------------------------
  // Relations
  // -----------------------------
  final trip = ToOne<TripModel>();
  final deliveryTeam = ToOne<DeliveryTeamModel>();

  // -----------------------------
  // Constructor
  // -----------------------------
  LocalUsersModel({
    this.objectBoxId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    this.email,
    this.profilePic,
    this.name,
    this.tripNumberId,
    this.pocketbaseId,
    this.tripId,
    this.deliveryTeamId,
    this.token,
    TripModel? tripModel,
    DeliveryTeamModel? deliveryTeamModel,
    UserRoleModel? userRoleModel,
  }) {
    if (tripModel != null) trip.target = tripModel;
    if (deliveryTeamModel != null) deliveryTeam.target = deliveryTeamModel;
  }

  // -----------------------------
  // JSON Parsing
  // -----------------------------
  factory LocalUsersModel.fromJson(dynamic json) {
    debugPrint('🔄 LocalUsersModel.fromJson');

    if (json is String) {
      return LocalUsersModel(id: json);
    }

    final expanded = json['expand'] as Map<String, dynamic>?;

    // trip expand
    TripModel? tripModel;
    final tripData = expanded?['trip'] ?? json['trip'];
    if (tripData != null) {
      if (tripData is RecordModel) {
        tripModel = TripModel.fromJson({
          'id': tripData.id,
          'collectionId': tripData.collectionId,
          'collectionName': tripData.collectionName,
          ...tripData.data,
        });
      } else if (tripData is Map) {
        tripModel = TripModel.fromJson(tripData as Map<String, dynamic>);
      }
    }

    // delivery team expand
    DeliveryTeamModel? deliveryTeamModel;
    final dtData = expanded?['deliveryTeam'] ?? json['deliveryTeam'];
    if (dtData != null) {
      if (dtData is RecordModel) {
        deliveryTeamModel = DeliveryTeamModel.fromJson({
          'id': dtData.id,
          'collectionId': dtData.collectionId,
          'collectionName': dtData.collectionName,
          ...dtData.data,
        });
      } else if (dtData is Map) {
        deliveryTeamModel = DeliveryTeamModel.fromJson(dtData);
      }
    }

    // role expand
    UserRoleModel? roleModel;
    final roleData = expanded?['role'] ?? json['role'];
    if (roleData != null) {
      if (roleData is RecordModel) {
        roleModel = UserRoleModel.fromJson({
          'id': roleData.id,
          'collectionId': roleData.collectionId,
          'collectionName': roleData.collectionName,
          ...roleData.data,
        });
      } else if (roleData is Map) {
        roleModel = UserRoleModel.fromJson(roleData);
      }
    }

    return LocalUsersModel(
      id: json['id']?.toString(),
      pocketbaseId: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      email: json['email']?.toString(),
      profilePic: json['profilePic']?.toString(),
      name: json['name']?.toString(),
      tripNumberId: json['tripNumberId']?.toString(),
      token: json['tokenKey']?.toString(),
      tripId: tripModel?.id,
      deliveryTeamId: deliveryTeamModel?.id,
      tripModel: tripModel,
      deliveryTeamModel: deliveryTeamModel,
      userRoleModel: roleModel,
    );
  }

  // -----------------------------
  // Serialize to JSON
  // -----------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'email': email,
      'profilePic': profilePic,
      'name': name,
      'tripNumberId': tripNumberId,
      'tripId': tripId,
      'deliveryTeamId': deliveryTeamId,
      'token': token,
      'trip': trip.target?.id,
      'deliveryTeam': deliveryTeam.target?.id,
    };
  }

  // -----------------------------
  // Copy With
  // -----------------------------
  LocalUsersModel copyWith({
    int? objectBoxId,
    String? id,
    String? pocketbaseId,
    String? collectionId,
    String? collectionName,
    String? email,
    String? profilePic,
    String? name,
    String? tripNumberId,
    String? tripId,
    String? deliveryTeamId,
    String? token,
    TripModel? tripModel,
    DeliveryTeamModel? deliveryTeamModel,
    UserRoleModel? userRoleModel,
  }) {
    return LocalUsersModel(
      objectBoxId: objectBoxId ?? this.objectBoxId,
      id: id ?? this.id,
      pocketbaseId: pocketbaseId ?? this.pocketbaseId,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      name: name ?? this.name,
      tripNumberId: tripNumberId ?? this.tripNumberId,
      tripId: tripId ?? this.tripId,
      deliveryTeamId: deliveryTeamId ?? this.deliveryTeamId,
      token: token ?? this.token,
      tripModel: tripModel ?? trip.target,
      deliveryTeamModel: deliveryTeamModel ?? deliveryTeam.target,
    );
  }
}
