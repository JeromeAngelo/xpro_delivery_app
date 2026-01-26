import 'package:equatable/equatable.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';

@Entity()
class TripUpdateEntity extends Equatable {
  @Id()
  int dbId = 0;

  String? id;
  String? collectionId;
  String? collectionName;
  TripUpdateStatus? status;
  DateTime? date;
  String? image;
  String? description;
  String? latitude;
  String? longitude;
  final ToOne<TripModel> trip = ToOne<TripModel>();

  TripUpdateEntity({
    this.id,
    this.collectionId,
    this.collectionName,
    this.status,
    this.date,
    this.image,
    this.description,
    this.latitude,
    this.longitude,
    TripModel? tripModel,
  }) {
    if (tripModel != null) trip.target = tripModel;
  }

  @override
  List<Object?> get props => [
        id,
        collectionId,
        collectionName,
        status,
        date,
        image,
        description,
        latitude,
        longitude,
        trip.target?.id,
      ];
}
