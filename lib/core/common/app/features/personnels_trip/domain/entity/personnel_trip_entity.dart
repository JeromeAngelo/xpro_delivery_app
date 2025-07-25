import 'package:xpro_delivery_admin_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:equatable/equatable.dart';

class PersonnelTripEntity extends Equatable {
  final String? id;
  final String? collectionId;
  final String? collectionName;
  final PersonelEntity? personnels;
  final List<TripEntity> assignedTrip;
  final DateTime? created;
  final DateTime? updated;

   PersonnelTripEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.personnels,
    List<TripEntity>? assignedTrip,
    this.created,
    this.updated,
  }) : assignedTrip = assignedTrip ?? [];

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        personnels?.id,
        assignedTrip,
        created,
        updated,
      ];

  factory PersonnelTripEntity.empty() {
    return PersonnelTripEntity(
      id: '',
      collectionId: '',
      collectionName: '',
      personnels: null,
      assignedTrip: [],
      created: null,
      updated: null,
    );
  }

  @override
  String toString() {
    return 'PersonnelTripEntity(id: $id, personnels: ${personnels?.id}, assignedTrip: ${assignedTrip.length}, created: $created, updated: $updated)';
  }
}
