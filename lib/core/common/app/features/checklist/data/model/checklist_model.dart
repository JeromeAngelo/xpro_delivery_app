import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/entity/checklist_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
@Entity()
class ChecklistModel extends ChecklistEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String? tripId;

   @Property()
  String? pocketBaseId;

  @override
  @Property()
  bool? isChecked;

  ChecklistModel({
    String? id,
    String? objectName,
    bool? isChecked,
    String? status,
    super.timeCompleted,
    super.tripModel,
    this.tripId,
  }) : super(
         id: id ?? '',
         objectName: objectName ?? '',
         isChecked: isChecked ?? false,
         status: status ?? '',
       );

  // Update fromJson to handle trip data
  factory ChecklistModel.fromJson(DataMap json) {
    final model = ChecklistModel(
      id: json['id']?.toString() ?? '',
      objectName: json['objectName']?.toString() ?? '',
      isChecked: json['isChecked'] as bool? ?? false,
      status: json['status']?.toString() ?? '',
      timeCompleted: json['timeCompleted'] != null 
          ? DateTime.tryParse(json['timeCompleted'].toString())?.toUtc() 
          : null,
      tripId: json['trip']?.toString(),
    );
    return model;
  }

  // Update toJson to include trip data
  DataMap toJson() {
    return {
      'id': id,
      'objectName': objectName,
      'isChecked': isChecked,
      'status': status,
      'timeCompleted': timeCompleted?.toIso8601String(),
      'trip': tripId,
    };
  }
}
