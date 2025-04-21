import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class UpdateTimelineEntity extends Equatable {

  @Id()
  int dbId = 0;
   UpdateTimelineEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.created,
    this.updated,
  });

  final String? id;
  final String? collectionId;
  final String? collectionName;

  final DateTime? created;
  final DateTime? updated;

   UpdateTimelineEntity.empty()
      : id = '',
        collectionId = '',
        collectionName = '',
        created = null,
        updated = null;

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        created,
        updated,
      ];

  @override
  String toString() {
    return 'UpdateTimelineEntity(id: $id,  created: $created, updated: $updated)';
  }
}
