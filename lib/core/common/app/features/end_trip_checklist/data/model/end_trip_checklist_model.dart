import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/entity/end_checklist_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
@Entity()
class EndTripChecklistModel extends EndChecklistEntity {
  @override
  @Id()
  int dbId = 0;

  @Property()
  @override
  String id;

  @Property()
  @override
  String objectName;

  @Property()
  @override
  bool? isChecked;

  @Property()
  @override
  String status;

  @Property()
  @override
  String trip;

  EndTripChecklistModel({
    String? id,
    String? objectName,
    bool? isChecked,
    String? status,
    String? description,
    String? trip,
    super.timeCompleted,
  }) : id = id ?? '',
       objectName = objectName ?? '',
       isChecked = isChecked ?? false,
       status = status ?? '',
       trip = trip ?? '',
       super(
         id: id ?? '',
         objectName: objectName ?? '',
         isChecked: isChecked ?? false,
         description: description ?? '',
         status: status ?? '',
         trip: trip ?? '',
       );

  factory EndTripChecklistModel.fromJson(DataMap json) {
    return EndTripChecklistModel(
      id: json['id']?.toString() ?? '',
      objectName: json['objectName']?.toString() ?? '',
      isChecked: json['isChecked'] as bool? ?? false,
      status: json['status']?.toString() ?? '',
      trip: json['trip']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      timeCompleted: json['timeCompleted'] != null 
          ? DateTime.tryParse(json['timeCompleted'].toString())?.toUtc() 
          : null,
    );
  }

  DataMap toJson() {
    return {
      'id': id,
      'objectName': objectName,
      'isChecked': isChecked,
      'status': status,
      'trip': trip,
      'description': description,
      'timeCompleted': timeCompleted?.toIso8601String(),
    };
  }
}
