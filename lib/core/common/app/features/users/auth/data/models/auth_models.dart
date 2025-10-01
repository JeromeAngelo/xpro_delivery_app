import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/users_roles/model/user_role_model.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entity/users_entity.dart';

@Entity()
class LocalUsersModel extends LocalUser {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  String? tripId;

  @Property()
  String? deliveryTeamId;

  @Property()
  String? token;

  LocalUsersModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.email,
    super.profilePic,
    super.name,
    super.tripNumberId,
    UserRoleModel? userRole,
    DeliveryTeamModel? deliveryTeamModel,
    TripModel? tripModel,
    this.tripId,
    this.deliveryTeamId,
    this.token,
  }) : pocketbaseId = id ?? '', super(userRole: userRole) {
    if (deliveryTeamModel != null) {
      deliveryTeam.target = deliveryTeamModel;
      deliveryTeamId = deliveryTeamModel.id;
    }
    if (tripModel != null) {
      trip.target = tripModel;
      tripId = tripModel.id;
    }
  }

  factory LocalUsersModel.fromJson(DataMap json) {
    debugPrint('🔄 Creating LocalUsersModel from JSON');
    final expandedData = json['expand'] as Map<String, dynamic>?;

    // Handle trip data
    final tripData = expandedData?['trip'];
    TripModel? tripModel;
    if (tripData != null) {
      if (tripData is RecordModel) {
        tripModel = TripModel.fromJson({
          'id': tripData.id,
          'collectionId': tripData.collectionId,
          'collectionName': tripData.collectionName,
          ...tripData.data,
        });
      } else if (tripData is Map<String, dynamic>) {
        tripModel = TripModel.fromJson(tripData);
      }
    }

    // Handle delivery team data
    final deliveryTeamData = expandedData?['deliveryTeam'];
    DeliveryTeamModel? deliveryTeamModel;
    if (deliveryTeamData != null) {
      if (deliveryTeamData is RecordModel) {
        deliveryTeamModel = DeliveryTeamModel.fromJson({
          'id': deliveryTeamData.id,
          'collectionId': deliveryTeamData.collectionId,
          'collectionName': deliveryTeamData.collectionName,
          ...deliveryTeamData.data,
        });
      } else if (deliveryTeamData is Map<String, dynamic>) {
        deliveryTeamModel = DeliveryTeamModel.fromJson(deliveryTeamData);
      }
    }

    // Handle user role data
    final userRoleData = expandedData?['role'];
    UserRoleModel? userRoleModel;
    if (userRoleData != null) {
      if (userRoleData is RecordModel) {
        userRoleModel = UserRoleModel.fromJson({
          'id': userRoleData.id,
          'name': userRoleData.data['name'],
          'permissions': userRoleData.data['permissions'] ?? [],
        });
      } else if (userRoleData is Map<String, dynamic>) {
        userRoleModel = UserRoleModel.fromJson(userRoleData);
      }
    }

    // Get token from tokenKey field
    final token = json['tokenKey']?.toString();

    debugPrint('📊 Mapped data summary:');
    debugPrint('ID: ${json['id']}');
    debugPrint('Name: ${json['name']}');
    debugPrint('Trip Number: ${json['tripNumberId']}');
    debugPrint('Trip ID: ${tripModel?.id}');
    debugPrint('Delivery Team ID: ${deliveryTeamModel?.id}');
    debugPrint('User Role: ${userRoleModel?.name}');
    debugPrint('Token: ${token?.substring(0, 10)}...');

    return LocalUsersModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      email: json['email']?.toString(),
      profilePic: json['profilePic']?.toString(),
      name: json['name']?.toString(),
      tripNumberId: json['tripNumberId']?.toString(),
      userRole: userRoleModel,
      deliveryTeamModel: deliveryTeamModel,
      tripModel: tripModel,
      tripId: tripModel?.id,
      deliveryTeamId: deliveryTeamModel?.id,
      token: token,
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'email': email,
      'profilePic': profilePic,
      'name': name,
      'tripNumberId': tripNumberId,
      'role': userRole != null ? (userRole as UserRoleModel).pocketbaseId : null,
     // 'deliveryTeam': deliveryTeam.target!.id,
      'trip': trip.target?.toJson(),
      'tripId': tripId,
      'deliveryTeamId': deliveryTeamId,
      'token': token,
    };
  }

  LocalUsersModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? email,
    String? profilePic,
    String? name,
    String? tripNumberId,
    UserRoleModel? userRole,
    DeliveryTeamModel? deliveryTeamModel,
    TripModel? tripModel,
    String? tripId,
    String? deliveryTeamId,
    String? token,
  }) {
    return LocalUsersModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      name: name ?? this.name,
      tripNumberId: tripNumberId ?? this.tripNumberId,
      userRole: userRole ?? (this.userRole as UserRoleModel?),
      deliveryTeamModel: deliveryTeamModel ?? deliveryTeam.target,
      tripModel: tripModel ?? trip.target,
      tripId: tripId ?? this.tripId,
      deliveryTeamId: deliveryTeamId ?? this.deliveryTeamId,
      token: token ?? this.token,
    );
  }
}
