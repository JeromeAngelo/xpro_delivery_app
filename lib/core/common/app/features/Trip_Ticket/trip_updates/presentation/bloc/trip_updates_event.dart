import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/enums/trip_update_status.dart';

abstract class TripUpdatesEvent extends Equatable {
  const TripUpdatesEvent();
}

class GetTripUpdatesEvent extends TripUpdatesEvent {
  final String tripId;
  const GetTripUpdatesEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class LoadLocalTripUpdatesEvent extends TripUpdatesEvent {
  final String tripId;
  const LoadLocalTripUpdatesEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class CreateTripUpdateEvent extends TripUpdatesEvent {
  final String tripId;
  final String description;
  final String image;
  final String latitude;
  final String longitude;
  final TripUpdateStatus status;

  const CreateTripUpdateEvent({
    required this.tripId,
    required this.description,
    required this.image,
    required this.latitude,
    required this.longitude,
    required this.status
  });

  @override
  List<Object?> get props => [tripId, description, image, latitude, longitude, status];
}
