import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';

@Entity()
class ChecklistEntity extends Equatable {
  @Id()
  int dbId = 0;

  final ToOne<TripModel> trip = ToOne<TripModel>();

  ChecklistEntity({
    required this.id,
    required this.objectName,
    required this.isChecked,
    this.status,
    this.timeCompleted,
    TripModel? tripModel,
  }) {
    if (tripModel != null) trip.target = tripModel;
  }

  final String id;
  final String? objectName;
  bool? isChecked;
  final String? status;
  DateTime? timeCompleted;

  ChecklistEntity.empty()
      : id = '',
        objectName = '',
        isChecked = false,
        status = '';

  @override
  List<Object?> get props => [
        id,
        objectName,
        isChecked,
        timeCompleted,
        trip.target?.id,
      ];

  @override
  String toString() {
    return 'ChecklistEntity(id: $id, objectName: $objectName, isChecked: $isChecked, tripId: ${trip.target?.id})';
  }
}
