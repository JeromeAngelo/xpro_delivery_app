import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class DeliveryVehicleEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  String? collectionId;
  String? collectionName;
  
  // Vehicle information fields
  String? name;
  String? plateNo;
  String? make;
  String? type;
  String? wheels;
  
  // Capacity fields
  double? volumeCapacity;
  double? weightCapacity;
  
  // Timestamps
  DateTime? created;
  DateTime? updated;

  DeliveryVehicleEntity({
    this.dbId = 0,
    this.id,
    this.collectionId,
    this.collectionName,
    this.name,
    this.plateNo,
    this.make,
    this.type,
    this.wheels,
    this.volumeCapacity,
    this.weightCapacity,
    this.created,
    this.updated,
  });

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    name,
    plateNo,
    make,
    type,
    wheels,
    volumeCapacity,
    weightCapacity,
    created,
    updated,
  ];
}
