import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class CustomerDataEntity extends Equatable {
  @Id()
  int dbId = 0;

  final String? id;
  final String? collectionId;
  final String? collectionName;
  final String? name;
  final String? refId;
  final String? paymentMode;
  final String? province;
  final String? ownerName;
  final String? contactNumber;
  final String? municipality;
  final String? barangay;
  final double? longitude;
  final double? latitude;
  final DateTime? created;
  final DateTime? updated;

  CustomerDataEntity({
    this.dbId = 0,
    this.id,
    this.paymentMode,
    this.collectionId,
    this.collectionName,
    this.contactNumber,
    this.ownerName,
    this.name,
    this.refId,
    this.province,
    this.municipality,
    this.barangay,
    this.longitude,
    this.latitude,
    this.created,
    this.updated,
  });

  @override
  List<Object?> get props => [
    id,
    collectionId,
    collectionName,
    name,
    refId,
    province,
    municipality,
    paymentMode,
    barangay,
    longitude,
    latitude,
    created,
    updated,
  ];
}
