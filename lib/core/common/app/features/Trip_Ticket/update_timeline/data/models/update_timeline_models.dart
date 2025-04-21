import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/update_timeline/domain/entity/update_timeline_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

@Entity()
class UpdateTimelineModel extends UpdateTimelineEntity {
  @override
  @Id()
  int dbId = 0;

  @override
  @Property()
  String? id;
  
  @override
  @Property()
  String? collectionId;
  
  @override
  @Property()
  String? collectionName;

  @override
  @Property(type: PropertyType.date)
  DateTime? created;
  
  @override
  @Property(type: PropertyType.date)
  DateTime? updated;

  UpdateTimelineModel({
    super.id,
    super.collectionId,
    super.collectionName,
    super.created,
    super.updated,
  });

  factory UpdateTimelineModel.fromJson(DataMap json) {
    return UpdateTimelineModel(
      id: json['id']?.toString(),
      collectionId: json['collectionId']?.toString(),
      collectionName: json['collectionName']?.toString(),
      created: json['created'] != null ? DateTime.parse(json['created'].toString()) : null,
      updated: json['updated'] != null ? DateTime.parse(json['updated'].toString()) : null,
    );
  }

  DataMap toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'collectionName': collectionName,
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
    };
  }

  UpdateTimelineModel copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    List<DeliveryUpdateEntity>? updates,
    DateTime? created,
    DateTime? updated,
  }) {
    return UpdateTimelineModel(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
