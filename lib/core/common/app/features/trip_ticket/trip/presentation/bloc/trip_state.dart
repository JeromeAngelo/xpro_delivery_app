
import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/presentation/bloc/trip_updates_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_state.dart';


abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {}

class TripLoading extends TripState {}

class TripSearching extends TripState {}

class TripAccepting extends TripState {}

class TripEnding extends TripState {}

class TripAccepted extends TripState {
  final TripEntity trip;
  final String trackingId;
  final String tripId;

  const TripAccepted({
    required this.trip,
    required this.trackingId,
    required this.tripId,
  });

  @override
  List<Object?> get props => [trip, trackingId, tripId];
}

// Add new states
class TripByIdLoaded extends TripState {
  final TripEntity trip;
  final bool isFromLocal;

  const TripByIdLoaded(this.trip, {this.isFromLocal = false});

  @override
  List<Object?> get props => [trip, isFromLocal];
}



class TrackingStarted extends TripState {
  final String tripId;
  
  const TrackingStarted(this.tripId);
  
  @override
  List<Object?> get props => [tripId];
}

class TripLoaded extends TripState {
  final TripEntity trip;
  final DeliveryDataState customerState;
  final TripUpdatesState timelineState;
  final DeliveryDataState deliveryDataState;
  final bool isFromSearch;

  const TripLoaded({
    required this.trip,
    required this.customerState,
    required this.timelineState,
    required this.deliveryDataState,
    this.isFromSearch = false,
  });

  @override
  List<Object?> get props => [trip, customerState, timelineState, isFromSearch];
}

class TripSearchResult extends TripState {
  final TripEntity trip;
  final bool found;

  const TripSearchResult({required this.trip, this.found = true});

  @override
  List<Object?> get props => [trip, found];
}

class TripError extends TripState {
  final String message;
  final bool isSearchError;

  const TripError(this.message, {this.isSearchError = false});

  @override
  List<Object?> get props => [message, isSearchError];
}

class EndTripOtpStatusChecked extends TripState {
  final bool hasEndTripOtp;
  
  const EndTripOtpStatusChecked(this.hasEndTripOtp);
  
  @override
  List<Object?> get props => [hasEndTripOtp];
}

class TripsSearchResults extends TripState {
  final List<TripEntity> trips;
  
  const TripsSearchResults(this.trips);
  
  @override
  List<Object?> get props => [trips];
}

class TripDateRangeResults extends TripState {
  final List<TripEntity> trips;
  
  const TripDateRangeResults(this.trips);
  
  @override
  List<Object?> get props => [trips];
}

class TripDistanceCalculated extends TripState {
  final String totalDistance;
  
  const TripDistanceCalculated(this.totalDistance);
  
  @override
  List<Object?> get props => [totalDistance];
}

class TripQRScanning extends TripState {}

class TripQRScanned extends TripState {
  final TripEntity trip;
  
  const TripQRScanned(this.trip);
  
  @override
  List<Object?> get props => [trip];
}

class TripEnded extends TripState {
  final TripEntity trip;
  
  const TripEnded(this.trip);
  
  @override
  List<Object?> get props => [trip];
}


// Add new state for when trip location is being updated
class TripLocationUpdating extends TripState {}

// Add new state for when trip location has been updated
class TripLocationUpdated extends TripState {
  final TripEntity trip;
  final double latitude;
  final double longitude;
  
  const TripLocationUpdated({
    required this.trip,
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [trip, latitude, longitude];
}

// Add state for when location tracking has started
class LocationTrackingStarted extends TripState {
  final String tripId;
  final Duration updateInterval;
  final double distanceFilter;
  
  const LocationTrackingStarted({
    required this.tripId,
    required this.updateInterval,
    required this.distanceFilter,
  });
  
  @override
  List<Object?> get props => [tripId, updateInterval, distanceFilter];
}

// Add state for when location tracking has paused
class LocationTrackingStarting extends TripState {}

// Add state for when location tracking has stopped
class LocationTrackingStopped extends TripState {
  const LocationTrackingStopped();
  
  @override
  List<Object?> get props => [];
}

// Add state for when there's an error with location tracking
class LocationTrackingError extends TripState {
  final String message;
  
  const LocationTrackingError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Add state for trip personnels check result
class TripPersonnelsChecked extends TripState {
  final List<String> personnelIds;
  
  const TripPersonnelsChecked(this.personnelIds);
  
  @override
  List<Object?> get props => [personnelIds];
}

// Add state for trip personnels checking
class TripPersonnelsChecking extends TripState {
  const TripPersonnelsChecking();
  
  @override
  List<Object?> get props => [];
}

// Add state for trip personnel mismatch
class TripPersonnelMismatch extends TripState {
  final String message;
  final String tripId;
  final String userId;
  
  const TripPersonnelMismatch({
    required this.message,
    required this.tripId,
    required this.userId,
  });
  
  @override
  List<Object?> get props => [message, tripId, userId];
}

// Add state for when mismatched reason is being set
class TripMismatchReasonSetting extends TripState {
  const TripMismatchReasonSetting();
  
  @override
  List<Object?> get props => [];
}

// Add state for when mismatched reason has been set
class TripMismatchReasonSet extends TripState {
  final String tripId;
  final String reasonCode;
  
  const TripMismatchReasonSet({
    required this.tripId,
    required this.reasonCode,
  });
  
  @override
  List<Object?> get props => [tripId, reasonCode];
}




