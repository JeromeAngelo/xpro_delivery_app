import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';

@Entity()
class ChecklistEntity extends Equatable {
  @Id()
  int dbId = 0;

  final ToOne<TripModel> trip = ToOne<TripModel>();

  ChecklistEntity({
 this.id,
    required this.objectName,
    required this.isChecked,
    this.description,
    this.status,
    this.timeCompleted,
    TripModel? tripModel,
  }) {
    if (tripModel != null) trip.target = tripModel;
  }

  String? id;
   String? objectName;
  String? description;
  bool? isChecked;
   String? status;
  DateTime? timeCompleted;

  ChecklistEntity.empty()
      : id = '',
        objectName = '',
        isChecked = false,
        status = '',
        description = '';

  @override
  List<Object?> get props => [
        id,
        objectName,
        isChecked,
        timeCompleted,
        trip.target?.id,
        description
      ];

  @override
  String toString() {
    return 'ChecklistEntity(id: $id, objectName: $objectName, isChecked: $isChecked, tripModel: ${trip.target?.id})';
  }
}
