import 'package:objectbox/objectbox.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/entity/personel_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';
@Entity()
class PersonelModel extends PersonelEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  String? tripId;

  @Property()
  String? deliveryTeamId;

  PersonelModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.name,
    super.role,
    super.deliveryTeamModel,
    super.tripModel,
    super.created,
    super.updated,
    this.tripId,
    this.deliveryTeamId,
  }) : pocketbaseId = id ?? '';

  static UserRole _parseRole(dynamic roleData) {
    if (roleData == null) return UserRole.helper;
    
    switch(roleData.toString().toLowerCase()) {
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
        deliveryTeamModel = DeliveryTeamModel.fromJson(deliveryTeamData as Map<String, dynamic>);
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
      created: json['created'] != null ? DateTime.parse(json['created'].toString()) : null,
      updated: json['updated'] != null ? DateTime.parse(json['updated'].toString()) : null,
    );
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'name': name,
      'role': role.toString(),
      'trip': tripId,
      'deliveryTeam': deliveryTeamId,
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
      tripModel: tripModel ?? trip.target,
      deliveryTeamModel: deliveryTeamModel ?? deliveryTeam.target,
      tripId: tripId ?? this.tripId,
      deliveryTeamId: deliveryTeamId ?? this.deliveryTeamId,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
