import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';

import '../../../../trip_ticket/trip/data/models/trip_models.dart';

@Entity()
class EndChecklistEntity extends Equatable {
  @Id()
  int dbId = 0;
  EndChecklistEntity({
   this.id,
    required this.objectName,
    required this.isChecked,
    this.tripId,
    this.description,
    this.status,
    this.timeCompleted,
    this.tripModel,
  });

  String? id;
  String? objectName;
  bool? isChecked;
  String? status;
  String? description;
  String? tripId;
  DateTime? timeCompleted;
  TripModel? tripModel;
  EndChecklistEntity.empty()
    : id = '',
      objectName = '',
      isChecked = false,
      description = '',
      status = '',
      tripModel = null,
      tripId = '';


  @override
  List<Object?> get props => [
    id,
    objectName,
    isChecked,
    tripId,
    timeCompleted,
    description,
    status,
    tripModel?.id,
  ];
}
