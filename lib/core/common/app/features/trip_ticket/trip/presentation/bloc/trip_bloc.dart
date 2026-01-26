import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/mixins/offline_first_mixin.dart';

import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/accept_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/calculate_total_distance.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/check_end_trip_status.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/check_trip_personnels.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/end_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/get_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/get_trip_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/get_trips_by_date_range.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/scan_qr_usecase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/search_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/search_trip_by_details.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/update_trip_location.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/domain/usecase/set_mismatched_reason.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/presentation/bloc/trip_updates_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip_updates/presentation/bloc/trip_updates_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/services/location_services.dart';

import '../../../../../../../services/foreground_location_service.dart';

class TripBloc extends Bloc<TripEvent, TripState>
    with OfflineFirstMixin<TripEvent, TripState> {
  TripState? _cachedState;
  final GetTrip _getTrip;
  final GetTripById _getTripById;
  final SearchTrip _searchTrip;
  final AcceptTrip _acceptTrip;
  final DeliveryDataBloc _deliveryDataBloc;
  final CheckEndTripStatus _checkEndTripStatus;
  final TripUpdatesBloc _updateTimelineBloc;
  final UpdateTripLocation _updateTripLocation;
  final ConnectivityProvider _connectivity;

  final SearchTrips _searchTrips;
  final GetTripsByDateRange _getTripsByDateRange;
  final CalculateTotalTripDistance _calculateTotalTripDistance;
  final ScanQRUsecase _scanQRUsecase;
  final EndTrip _endTrip;
  final CheckTripPersonnels _checkTripPersonnels;
  final SetMismatchedReason _setMismatchedReason;

  // Field to store the subscription to the location updates
  StreamSubscription<double>? _locationSubscription;

  // Field to store the current tracked trip ID
  String? _trackedTripId;

  TripBloc({
    required GetTrip getTrip,
    required GetTripById getTripById,
    required DeliveryDataBloc deliveryDataBloc,
    required CalculateTotalTripDistance calculateTotalTripDistance,
    required SearchTrip searchTrip,
    required AcceptTrip acceptTrip,
    required TripUpdatesBloc updateTimelineBloc,
    required CheckEndTripStatus checkEndTripStatus,
    required SearchTrips searchTrips,
    required GetTripsByDateRange getTripsByDateRange,
    required ScanQRUsecase scanQRUsecase,
    required UpdateTripLocation updateTripLocation,
    required EndTrip endTrip,
    required CheckTripPersonnels checkTripPersonnels,
    required SetMismatchedReason setMismatchedReason,
    required ConnectivityProvider connectivity,
  }) : _getTrip = getTrip,
       _getTripById = getTripById,
       _searchTrip = searchTrip,
       _acceptTrip = acceptTrip,
       _deliveryDataBloc = deliveryDataBloc,
       _updateTimelineBloc = updateTimelineBloc,
       _checkEndTripStatus = checkEndTripStatus,
       _searchTrips = searchTrips,
       _getTripsByDateRange = getTripsByDateRange,
       _calculateTotalTripDistance = calculateTotalTripDistance,
       _scanQRUsecase = scanQRUsecase,
       _updateTripLocation = updateTripLocation,
       _endTrip = endTrip,
       _checkTripPersonnels = checkTripPersonnels,
       _setMismatchedReason = setMismatchedReason,
       _connectivity = connectivity,

       super(TripInitial()) {
    on<CalculateTripDistanceEvent>(_onCalculateTripDistance);
    on<LoadLocalTripByIdEvent>(_onLoadLocalTripById);
    on<GetTripEvent>(_onGetTrip);
    on<SearchTripEvent>(_onSearchTrip);
    on<AcceptTripEvent>(_onAcceptTrip);
    on<ClearTripSearchEvent>(_onClearSearch);
    on<LoadLocalTripEvent>(_onLoadLocalTrip);
    on<CheckEndTripOtpStatusEvent>(_onCheckEndTripOtpStatus);
    on<SearchTripsAdvancedEvent>(_onSearchTripsAdvanced);
    on<GetTripsByDateRangeEvent>(_onGetTripsByDateRange);
    on<GetTripByIdEvent>(_onGetTripById);
    on<ScanTripQREvent>(_onScanTripQR);
    on<EndTripEvent>(_onEndTrip);
    on<UpdateTripLocationEvent>(_onUpdateTripLocation);
    on<StartLocationTrackingEvent>(_onStartLocationTracking);
    on<StopLocationTrackingEvent>(_onStopLocationTracking);
    on<CheckTripPersonnelsEvent>(_onCheckTripPersonnels);
    on<SetMismatchedReasonEvent>(_onSetMismatchedReason);
  }

  Future<void> _onGetTripById(
    GetTripByIdEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint('🔍 OFFLINE-FIRST: Loading trip by ID: ${event.tripId}');
    emit(TripLoading());

    await executeOfflineFirst(
      localOperation: () async {
        final result = await _getTripById.loadFromLocal(event.tripId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (trip) => emit(TripByIdLoaded(trip, isFromLocal: true)),
        );
      },
      remoteOperation: () async {
        final result = await _getTripById(event.tripId);
        result.fold(
          (failure) => throw Exception(failure.message),
          (trip) => emit(TripByIdLoaded(trip)),
        );
      },
      onLocalSuccess: (data) {
        debugPrint('✅ Trip loaded from local cache');
      },
      onRemoteSuccess: (data) {
        debugPrint('✅ Trip synced from remote');
      },
      onError: (error) => emit(TripError(error)),
      connectivity: _connectivity,
    );
  }

  /// Legacy method - use GetTripByIdEvent with offline-first pattern instead
  Future<void> _onLoadLocalTripById(
    LoadLocalTripByIdEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());
    debugPrint('📱 Loading local trip by ID: ${event.tripId}');

    final result = await _getTripById.loadFromLocal(event.tripId);

    result.fold((failure) => emit(TripError(failure.message)), (trip) {
      emit(TripByIdLoaded(trip, isFromLocal: true));

      // Background remote sync
      _onGetTripById(GetTripByIdEvent(event.tripId), emit);
    });
  }

  Future<void> _onScanTripQR(
    ScanTripQREvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripQRScanning());
    debugPrint('🔍 Processing QR scan: ${event.qrData}');

    final result = await _scanQRUsecase(event.qrData);

    result.fold((failure) => emit(TripError(failure.message)), (trip) {
      debugPrint('✅ QR scan successful');
      emit(TripQRScanned(trip));

      if (trip.id != null) {
        _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(trip.id ?? ''));
      }
      _updateTimelineBloc.add(LoadLocalTripUpdatesEvent(trip.id ?? ''));
    });
  }

  Future<void> _onLoadLocalTrip(
    LoadLocalTripEvent event,
    Emitter<TripState> emit,
  ) async {
    if (_cachedState != null) {
      emit(_cachedState!);
      return;
    }

    final result = await _getTrip.loadFromLocal();
    result.fold((failure) => emit(TripError(failure.message)), (trip) {
      if (trip.id != null) {
        _deliveryDataBloc.add(GetLocalDeliveryDataByIdEvent(trip.id!));
      }
      _updateTimelineBloc.add(LoadLocalTripUpdatesEvent(trip.id!));

      final newState = TripLoaded(
        trip: trip,
        customerState: _deliveryDataBloc.state,
        timelineState: _updateTimelineBloc.state,
        deliveryDataState: _deliveryDataBloc.state,
      );
      _cachedState = newState;
      emit(newState);
    });
  }

  Future<void> _onSearchTripsAdvanced(
    SearchTripsAdvancedEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripSearching());

    final result = await _searchTrips(
      SearchTripsParams(
        tripNumberId: event.tripNumberId,
        startDate: event.startDate,
        endDate: event.endDate,
        isAccepted: event.isAccepted,
        isEndTrip: event.isEndTrip,
        deliveryTeamId: event.deliveryTeamId,
        vehicleId: event.vehicleId,
        personnelId: event.personnelId,
      ),
    );

    result.fold(
      (failure) => emit(TripError(failure.message)),
      (trips) => emit(TripsSearchResults(trips)),
    );
  }

  Future<void> _onGetTripsByDateRange(
    GetTripsByDateRangeEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripSearching());

    final result = await _getTripsByDateRange(
      DateRangeParams(startDate: event.startDate, endDate: event.endDate),
    );

    result.fold(
      (failure) => emit(TripError(failure.message)),
      (trips) => emit(TripDateRangeResults(trips)),
    );
  }

  Future<void> _onGetTrip(GetTripEvent event, Emitter<TripState> emit) async {
    if (_cachedState != null) {
      emit(_cachedState!);
    }

    emit(TripLoading());

    debugPrint('Loading trip data...');
    final result = await _getTrip();

    result.fold(
      (failure) {
        debugPrint('Trip loading failed: ${failure.message}');
        emit(TripError(failure.message));
      },
      (trip) {
        debugPrint('Trip loaded successfully');
        if (trip.id != null) {
          _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(trip.id!));
        }
        _updateTimelineBloc.add(LoadLocalTripUpdatesEvent(trip.id!));

        final newState = TripLoaded(
          trip: trip,
          customerState: _deliveryDataBloc.state,
          timelineState: _updateTimelineBloc.state,
          deliveryDataState: _deliveryDataBloc.state,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onSearchTrip(
    SearchTripEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripSearching());

    if (event.clearSearchResults) {
      emit(TripInitial());
      return;
    }

    final result = await _searchTrip(event.tripNumberId);

    result.fold(
      (failure) => emit(TripError(failure.message, isSearchError: true)),
      (trip) {
        debugPrint('🔍 Found trip with ID: ${trip.id}');
        if (trip.id != null) {
          _deliveryDataBloc.add(GetDeliveryDataByTripIdEvent(trip.id!));
          _updateTimelineBloc.add(LoadLocalTripUpdatesEvent(trip.id!));

          emit(TripSearchResult(trip: trip, found: true));
          final newState = TripLoaded(
            trip: trip,
            customerState: _deliveryDataBloc.state,
            timelineState: _updateTimelineBloc.state,
            deliveryDataState: _deliveryDataBloc.state,
          );
          _cachedState = newState;
          emit(newState);
        } else {
          emit(const TripError('Invalid trip data: Missing ID'));
        }
      },
    );
  }
Future<void> _onAcceptTrip(
  AcceptTripEvent event,
  Emitter<TripState> emit,
) async {
  emit(TripAccepting());
  debugPrint('🔄 BLOC: Starting trip acceptance process for ID: ${event.tripId}');

  final result = await _acceptTrip(event.tripId);

  // ✅ Avoid async closure inside fold -> handle explicitly
  if (result.isLeft()) {
    final failure = result.swap().getOrElse(() => throw StateError('No failure'));
    debugPrint('❌ BLOC: Trip acceptance failed: ${failure.message}');
    if (emit.isDone) return;
    emit(TripError(failure.message));
    return;
  }

  final tripData = result.getOrElse(() => throw StateError('No trip data'));
  final (trip, trackingId) = tripData;

  debugPrint('✅ BLOC: Trip accepted successfully');
  debugPrint('   📋 Trip ID: ${trip.id}');
  _cachedState = null;

  if (emit.isDone) return;
  emit(
    TripAccepted(
      trip: trip,
      trackingId: trackingId,
      tripId: event.tripId,
    ),
  );

  // ✅ START FOREGROUND LOCATION TRACKING IMMEDIATELY
  final tripId = (trip.id ?? '').toString().trim();
  if (tripId.isEmpty) return;

  debugPrint('🚀 BLOC: Starting foreground location tracking for trip: $tripId');

  final started = await ForegroundLocationService.startTracking(
    tripId: tripId,
    pocketBaseUrl: 'https://delivery-app.winganmarketing.com',
  );

  if (emit.isDone) return;

  if (started) {
    debugPrint('✅ BLOC: Foreground location tracking started successfully');
    emit(
      LocationTrackingStarted(
        tripId: tripId,
        updateInterval: const Duration(minutes: 1),
        distanceFilter: 2.0,
      ),
    );
  } else {
    debugPrint('⚠️ BLOC: Failed to start foreground location tracking');
    emit(const LocationTrackingError('Failed to start background tracking'));
  }
}


  Future<void> _onCheckEndTripOtpStatus(
    CheckEndTripOtpStatusEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint('🔍 Checking end trip OTP status for trip: ${event.tripId}');

    final result = await _checkEndTripStatus();

    result.fold(
      (failure) {
        debugPrint('❌ Failed to check end trip OTP status: ${failure.message}');
        emit(TripError(failure.message));
      },
      (hasEndTripOtp) {
        debugPrint('✅ End trip OTP status checked: $hasEndTripOtp');
        emit(EndTripOtpStatusChecked(hasEndTripOtp));
      },
    );
  }

  Future<void> _onCalculateTripDistance(
    CalculateTripDistanceEvent event,
    Emitter<TripState> emit,
  ) async {
    emit(TripLoading());

    final result = await _calculateTotalTripDistance(event.tripId);

    result.fold(
      (failure) => emit(TripError(failure.message)),
      (totalDistance) => emit(TripDistanceCalculated(totalDistance)),
    );
  }

  Future<void> _onEndTrip(EndTripEvent event, Emitter<TripState> emit) async {
    debugPrint('🔄 BLOC: Starting trip end process for ID: ${event.tripId}');
    emit(TripEnding());

    final result = await _endTrip(event.tripId);

    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: Trip end failed: ${failure.message}');
        if (!emit.isDone) emit(TripError(failure.message));
      },
      (trip) async {
        debugPrint('✅ BLOC: Trip ended successfully');

        // Clear cached states
        _cachedState = null;

        // ✅ STOP ALL LOCATION TRACKING
        try {
          await ForegroundLocationService.stopTracking();
          await _stopTracking();
          debugPrint('🛑 BLOC: All location tracking stopped');
        } catch (e, st) {
          debugPrint('⚠️ Error stopping tracking: $e');
          debugPrint('Stack trace: $st');
        }

        // Emit trip ended state (ensure not closed)
        if (!emit.isDone) emit(TripEnded(trip));

        // Clear preferences and reset state after short delay
        await Future.delayed(const Duration(seconds: 2));

        if (!emit.isDone) {
          await _clearTripDataFromPreferences();
          add(const GetTripEvent());
        }
      },
    );
  }

  // Helper method to clear trip data from shared preferences
  Future<void> _clearTripDataFromPreferences() async {
    try {
      debugPrint('🧹 BLOC: Clearing trip data from preferences');
      final prefs = await SharedPreferences.getInstance();

      // Get current user data
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final userJson = jsonDecode(userData);

        // Remove trip-related fields
        userJson['tripNumberId'] = null;
        userJson['trip'] = null;

        // Save updated user data
        await prefs.setString('user_data', jsonEncode(userJson));
      }

      // Remove other trip-related preferences
      await prefs.remove('user_trip_data');
      await prefs.remove('trip_cache');
      await prefs.remove('delivery_status_cache');
      await prefs.remove('customer_cache');
      await prefs.remove('active_trip');
      await prefs.remove('last_trip_id');
      await prefs.remove('last_trip_number');

      debugPrint('✅ BLOC: Successfully cleared trip data from preferences');
    } catch (e) {
      debugPrint('❌ BLOC: Error clearing trip data from preferences: $e');
    }
  }

  Future<void> _onUpdateTripLocation(
    UpdateTripLocationEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint('🔄 BLOC: Updating trip location for ID: ${event.tripId}');
    debugPrint(
      '📍 Coordinates: Lat: ${event.latitude}, Long: ${event.longitude}',
    );
    debugPrint(
      '🎯 Accuracy: ${event.accuracy?.toStringAsFixed(2) ?? 'Unknown'} meters',
    );
    debugPrint('📡 Source: ${event.source ?? 'GPS_Enhanced'}');

    // Get current total distance from LocationService (for in-app tracking)
    final currentTotalDistance = LocationService.getTotalDistance();
    debugPrint(
      '📏 BLOC: Current total distance from LocationService: ${currentTotalDistance.toStringAsFixed(3)} km',
    );

    emit(TripLocationUpdating());

    final params = UpdateTripLocationParams(
      tripId: event.tripId,
      latitude: event.latitude,
      longitude: event.longitude,
      accuracy: event.accuracy,
      source: event.source ?? 'GPS_Enhanced',
      totalDistance: currentTotalDistance,
    );

    final result = await _updateTripLocation(params);

    result.fold(
      (failure) {
        debugPrint(
          '❌ BLOC: Failed to update trip location: ${failure.message}',
        );
        emit(LocationTrackingError(failure.message));
      },
      (trip) {
        debugPrint('✅ BLOC: Trip location updated successfully');
        debugPrint(
          '   📏 Total distance: ${currentTotalDistance.toStringAsFixed(3)} km',
        );
        emit(
          TripLocationUpdated(
            trip: trip,
            latitude: event.latitude,
            longitude: event.longitude,
          ),
        );
      },
    );
  }

  Future<void> _onStartLocationTracking(
    StartLocationTrackingEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint('🔄 BLOC: Starting location tracking for trip: ${event.tripId}');

    emit(LocationTrackingStarting());
    // Stop any existing tracking
    await _stopTracking();
    await ForegroundLocationService.stopTracking();

    try {
      // Check if location services are enabled and permissions are granted
      bool serviceEnabled = await LocationService.enableLocationService();
      if (!serviceEnabled) {
        debugPrint('❌ BLOC: Location services are disabled');
        emit(const LocationTrackingError('Location services are disabled'));
        return;
      }

      bool permissionGranted = await LocationService.requestPermission();
      if (!permissionGranted) {
        debugPrint('❌ BLOC: Location permissions are denied');
        emit(const LocationTrackingError('Location permissions are denied'));
        return;
      }

      // ✅ START FOREGROUND SERVICE (primary tracking method)
      debugPrint('🚀 BLOC: Starting foreground location service');
      final foregroundStarted = await ForegroundLocationService.startTracking(
        tripId: event.tripId,
        pocketBaseUrl: 'https://delivery-app.winganmarketing.com',
      );

      if (!foregroundStarted) {
        debugPrint('⚠️ BLOC: Foreground service failed to start');
        emit(
          const LocationTrackingError('Failed to start foreground tracking'),
        );
        return;
      }

      // ✅ ALSO START WORKMANAGER (backup tracking)
      // await Workmanager().initialize(callbackDispatcher);
      // await BackgroundLocationTracker.startTracking(tripId: event.tripId);
      // debugPrint('🚀 BLOC: WorkManager backup tracking started');

      // Store the trip ID being tracked
      _trackedTripId = event.tripId;

      // ✅ START FOREGROUND LOCATIONSERVICE TRACKING (for in-app distance calculation)
      debugPrint('📍 BLOC: Getting initial position...');
      final initialPosition = await LocationService.getCurrentLocation();

      debugPrint('✅ BLOC: Initial position obtained - updating trip location');
      add(
        UpdateTripLocationEvent(
          tripId: event.tripId,
          latitude: initialPosition.latitude,
          longitude: initialPosition.longitude,
          accuracy: initialPosition.accuracy,
          source: 'GPS_Initial_Validated',
        ),
      );

      // Start tracking distance using LocationService (for in-app updates)
      _locationSubscription = LocationService.trackDistance().listen((
        distance,
      ) async {
        try {
          debugPrint(
            '📍 BLOC: Distance update triggered (${distance.toStringAsFixed(2)} km)',
          );

          final position = await LocationService.getCurrentLocation();

          if (_trackedTripId == event.tripId) {
            debugPrint('🔄 BLOC: Updating trip location with current position');
            add(
              UpdateTripLocationEvent(
                tripId: event.tripId,
                latitude: position.latitude,
                longitude: position.longitude,
                accuracy: position.accuracy,
                source: 'GPS_Tracking_Validated',
              ),
            );

            debugPrint('📍 BLOC: Location updated successfully');
          }
        } catch (e) {
          debugPrint('❌ BLOC: Error getting current location: $e');
        }
      });

      emit(
        LocationTrackingStarted(
          tripId: event.tripId,
          updateInterval: const Duration(
            minutes: 1,
          ), // Foreground service interval
          distanceFilter: 2.0,
        ),
      );

      debugPrint('✅ BLOC: All location tracking services started successfully');
    } catch (e) {
      debugPrint('❌ BLOC: Error starting location tracking: $e');
      emit(LocationTrackingError('Error starting location tracking: $e'));
    }
  }

  Future<void> _onStopLocationTracking(
    StopLocationTrackingEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint('🔄 BLOC: Stopping all location tracking');

    // Stop foreground tracking
    await ForegroundLocationService.stopTracking();
    debugPrint('🛑 Foreground location tracking stopped');

    // Stop WorkManager backup tracking
    // await BackgroundLocationTracker.stopTracking();
    // debugPrint('🛑 WorkManager tracking stopped');

    // Stop LocationService tracking
    await _stopTracking();
    debugPrint('🛑 LocationService tracking stopped');

    emit(const LocationTrackingStopped());
    debugPrint('✅ BLOC: All location tracking stopped successfully');
  }

  // Helper method to stop tracking
  Future<void> _stopTracking() async {
    _trackedTripId = null;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    LocationService.stopTracking();
  }

  void _onClearSearch(ClearTripSearchEvent event, Emitter<TripState> emit) {
    _cachedState = null;
    emit(TripInitial());
    add(const GetTripEvent());
  }

  Future<void> _onCheckTripPersonnels(
    CheckTripPersonnelsEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint(
      '🔍 BLOC: Checking trip personnels for trip: ${event.tripId}, user: ${event.userId}',
    );
    emit(const TripPersonnelsChecking());

    final result = await _checkTripPersonnels(event.tripId);

    result.fold(
      (failure) {
        debugPrint(
          '❌ BLOC: Failed to check trip personnels: ${failure.message}',
        );

        // Check if this is a personnel authorization error (403 status)
        if (failure.statusCode == '403' &&
            (failure.message.contains('not authorized') ||
                failure.message.contains('not assigned') ||
                failure.message.contains('is not assigned as personnel'))) {
          debugPrint('🚫 BLOC: Detected personnel authorization error');
          debugPrint('   Status Code: ${failure.statusCode}');
          debugPrint('   Error Message: ${failure.message}');
          emit(
            TripPersonnelMismatch(
              message: failure.message,
              tripId: event.tripId,
              userId: event.userId,
            ),
          );
        } else {
          // Other errors (network, server, etc.)
          debugPrint('❌ BLOC: Non-authorization error detected');
          debugPrint('   Status Code: ${failure.statusCode}');
          debugPrint('   Error Message: ${failure.message}');
          emit(TripError(failure.message));
        }
      },
      (personnelIds) {
        debugPrint('✅ BLOC: Found ${personnelIds.length} personnels');
        debugPrint('   Personnel IDs: $personnelIds');
        debugPrint('   User ${event.userId} is authorized for this trip');
        emit(TripPersonnelsChecked(personnelIds));
      },
    );
  }

  Future<void> _onSetMismatchedReason(
    SetMismatchedReasonEvent event,
    Emitter<TripState> emit,
  ) async {
    debugPrint(
      '📝 BLOC: Setting mismatched personnel reason for trip: ${event.tripId}',
    );
    debugPrint('   📋 Reason Code: ${event.reasonCode}');

    emit(const TripMismatchReasonSetting());

    final result = await _setMismatchedReason(
      SetMismatchedReasonParams(
        tripId: event.tripId,
        reasonCode: event.reasonCode,
      ),
    );

    result.fold(
      (failure) {
        debugPrint(
          '❌ BLOC: Failed to set mismatched reason: ${failure.message}',
        );
        emit(TripError(failure.message));
      },
      (success) {
        debugPrint('✅ BLOC: Mismatched reason set successfully');
        emit(
          TripMismatchReasonSet(
            tripId: event.tripId,
            reasonCode: event.reasonCode,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    _stopTracking();
    return super.close();
  }
}
