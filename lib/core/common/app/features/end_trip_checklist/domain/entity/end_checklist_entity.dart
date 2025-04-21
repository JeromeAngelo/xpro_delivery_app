import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
@Entity()
class EndChecklistEntity extends Equatable {
  @Id()
  int dbId = 0;
  EndChecklistEntity({
    required this.id,
    required this.objectName,
    required this.isChecked,
    required this.trip,
    this.status,
    this.timeCompleted,
  });

  final String id;
  final String? objectName;
   bool? isChecked;
  final String? status;
  final String trip;
  DateTime? timeCompleted;

  EndChecklistEntity.empty()
      : id = '',
        objectName = '',
        isChecked = false,
        status = '',
        trip = '';

  @override
  List<Object?> get props => [id, objectName, isChecked, trip, timeCompleted];
}
