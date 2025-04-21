import 'package:equatable/equatable.dart';
abstract class TripEvent extends Equatable {
  const TripEvent();
}

class GetTripEvent extends TripEvent {
  const GetTripEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadLocalTripEvent extends TripEvent {
  const LoadLocalTripEvent();
  
  @override
  List<Object?> get props => [];
}

class SearchTripEvent extends TripEvent {
  final String tripNumberId;
  final bool clearSearchResults;
  
  const SearchTripEvent(this.tripNumberId, {this.clearSearchResults = false});
  
  @override
  List<Object?> get props => [tripNumberId, clearSearchResults];
}

class AcceptTripEvent extends TripEvent {
  final String tripId;
  const AcceptTripEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}


class StartTrackingEvent extends TripEvent {
  final String tripId;
  
  const StartTrackingEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class ClearTripSearchEvent extends TripEvent {
  const ClearTripSearchEvent();
  
  @override
  List<Object?> get props => [];
}

class CheckEndTripOtpStatusEvent extends TripEvent {
  final String tripId;
  
  const CheckEndTripOtpStatusEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

// Add new event
class GetTripByIdEvent extends TripEvent {
  final String tripId;
  
  const GetTripByIdEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class LoadLocalTripByIdEvent extends TripEvent {
  final String tripId;
  
  const LoadLocalTripByIdEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}


class SearchTripsAdvancedEvent extends TripEvent {
  final String? tripNumberId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isAccepted;
  final bool? isEndTrip;
  final String? deliveryTeamId;
  final String? vehicleId;
  final String? personnelId;

  const SearchTripsAdvancedEvent({
    this.tripNumberId,
    this.startDate,
    this.endDate,
    this.isAccepted,
    this.isEndTrip,
    this.deliveryTeamId,
    this.vehicleId,
    this.personnelId,
  });

  @override
  List<Object?> get props => [
    tripNumberId,
    startDate,
    endDate,
    isAccepted,
    isEndTrip,
    deliveryTeamId,
    vehicleId,
    personnelId,
  ];
}

class GetTripsByDateRangeEvent extends TripEvent {
  final DateTime startDate;
  final DateTime endDate;

  const GetTripsByDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class CalculateTripDistanceEvent extends TripEvent {
  final String tripId;
  
  const CalculateTripDistanceEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class ScanTripQREvent extends TripEvent {
  final String qrData;
  
  const ScanTripQREvent(this.qrData);
  
  @override
  List<Object?> get props => [qrData];
}

class EndTripEvent extends TripEvent {
  final String tripId;
  
  const EndTripEvent(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}


// Add new event for updating trip location
class UpdateTripLocationEvent extends TripEvent {
  final String tripId;
  final double latitude;
  final double longitude;
  
  const UpdateTripLocationEvent({
    required this.tripId,
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [tripId, latitude, longitude];
}

// Add event for starting location tracking
class StartLocationTrackingEvent extends TripEvent {
  final String tripId;
  final Duration updateInterval;
  final double distanceFilter;
  
  const StartLocationTrackingEvent({
    required this.tripId,
    this.updateInterval = const Duration(minutes: 5),
    this.distanceFilter = 1000.0, // 1000 meters = 1 km
  });
  
  @override
  List<Object?> get props => [tripId, updateInterval, distanceFilter];
}

// Add event for stopping location tracking
class StopLocationTrackingEvent extends TripEvent {
  const StopLocationTrackingEvent();
  
  @override
  List<Object?> get props => [];
}


