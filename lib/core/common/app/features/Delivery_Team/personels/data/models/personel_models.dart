import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/delivery_team/data/models/delivery_team_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:xpro_delivery_admin_app/core/enums/user_role.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:pocketbase/pocketbase.dart';

class PersonelModel extends PersonelEntity {
  String pocketbaseId;
  String? tripId;
  String? deliveryTeamId;

  PersonelModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.name,
    super.isAssigned,
    super.role,
    DeliveryTeamModel? deliveryTeamModel,
    TripModel? tripModel,
    super.created,
    super.updated,
    this.tripId,
    this.deliveryTeamId,
  }) : pocketbaseId = id ?? '',
       super(deliveryTeam: deliveryTeamModel, trip: tripModel);

  static UserRole _parseRole(dynamic roleData) {
    if (roleData == null) return UserRole.helper;

    switch (roleData.toString().toLowerCase()) {
      case 'team_leader':
      case 'teamleader':
        return UserRole.teamLeader;
      case 'helper':
        return UserRole.helper;

      default:
        return UserRole.helper;
    }
  }

  factory PersonelModel.fromJson(DataMap json) {
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
      } else if (tripData is Map) {
        tripModel = TripModel.fromJson(tripData as Map<String, dynamic>);
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
      } else if (deliveryTeamData is Map) {
        deliveryTeamModel = DeliveryTeamModel.fromJson(
          deliveryTeamData as Map<String, dynamic>,
        );
      }
    }

    return PersonelModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      name: json['name']?.toString(),
      role: _parseRole(json['role']),
      tripModel: tripModel,
      deliveryTeamModel: deliveryTeamModel,
      tripId: json['trip']?.toString(),
      deliveryTeamId: json['deliveryTeam']?.toString(),
      isAssigned: json['isAssigned'] ?? false,
      created:
          json['created'] != null
              ? DateTime.parse(json['created'].toString())
              : null,
      updated:
          json['updated'] != null
              ? DateTime.parse(json['updated'].toString())
              : null,
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'name': name,
      'role': role?.toString().split('.').last,
      'trip': tripId,
      'deliveryTeam': deliveryTeamId,
      'isAssigned': isAssigned,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  PersonelModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? name,
    UserRole? role,
    TripModel? tripModel,
    bool? isAssigned,
    DeliveryTeamModel? deliveryTeamModel,
    String? tripId,
    String? deliveryTeamId,
    DateTime? created,
    DateTime? updated,
  }) {
    return PersonelModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      name: name ?? this.name,
      role: role ?? this.role,
      isAssigned: isAssigned ?? this.isAssigned,
      tripModel: tripModel ?? trip,
      deliveryTeamModel: deliveryTeamModel ?? deliveryTeam,
      tripId: tripId ?? this.tripId,
      deliveryTeamId: deliveryTeamId ?? this.deliveryTeamId,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  factory PersonelModel.fromEntity(PersonelEntity entity) {
    return PersonelModel(
      id: entity.id,
      collectionId: entity.collectionId,
      collectionName: entity.collectionName,
      name: entity.name,
      role: entity.role,
      isAssigned: entity.isAssigned,
      tripModel: entity.trip,
      deliveryTeamModel: entity.deliveryTeam,
      created: entity.created,
      updated: entity.updated,
    );
  }

  factory PersonelModel.empty() {
    return PersonelModel(
      id: '',
      collectionId: '',
      collectionName: '',
      name: '',
      isAssigned: false,
      role: UserRole.helper,
      tripModel: null,
      deliveryTeamModel: null,
      created: null,
      updated: null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonelModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
