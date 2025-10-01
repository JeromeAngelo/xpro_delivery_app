import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/presentation/bloc/delivery_vehicle_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/presentation/bloc/delivery_vehicle_state.dart';
import '../../domain/usecases/load_all_delivery_vehicle.dart';
import '../../domain/usecases/load_delivery_vehicle_by_id.dart' show LoadDeliveryVehicleById;
import '../../domain/usecases/load_delivery_vehicle_by_trip_id.dart';

class DeliveryVehicleBloc extends Bloc<DeliveryVehicleEvent, DeliveryVehicleState> {
  final LoadDeliveryVehicleById _loadDeliveryVehicleById;
  final LoadDeliveryVehiclesByTripId _loadDeliveryVehiclesByTripId;
  final LoadAllDeliveryVehicles _loadAllDeliveryVehicles;

  DeliveryVehicleBloc({
    required LoadDeliveryVehicleById loadDeliveryVehicleById,
    required LoadDeliveryVehiclesByTripId loadDeliveryVehiclesByTripId,
    required LoadAllDeliveryVehicles loadAllDeliveryVehicles,
  })  : _loadDeliveryVehicleById = loadDeliveryVehicleById,
        _loadDeliveryVehiclesByTripId = loadDeliveryVehiclesByTripId,
        _loadAllDeliveryVehicles = loadAllDeliveryVehicles,
        super(DeliveryVehicleInitial()) {
    on<LoadDeliveryVehicleByIdEvent>(_onLoadDeliveryVehicleById);
    on<LoadDeliveryVehiclesByTripIdEvent>(_onLoadDeliveryVehiclesByTripId);
    on<LoadAllDeliveryVehiclesEvent>(_onLoadAllDeliveryVehicles);
  }

  Future<void> _onLoadDeliveryVehicleById(
    LoadDeliveryVehicleByIdEvent event,
    Emitter<DeliveryVehicleState> emit,
  ) async {
    emit(DeliveryVehicleLoading());
    debugPrint('🔄 Loading delivery vehicle with ID: ${event.vehicleId}');

    final result = await _loadDeliveryVehicleById(event.vehicleId);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load delivery vehicle: ${failure.message}');
        emit(DeliveryVehicleError(failure.message));
      },
      (vehicle) {
        debugPrint('✅ Successfully loaded delivery vehicle: ${vehicle.id}');
        emit(DeliveryVehicleLoaded(vehicle));
      },
    );
  }

  Future<void> _onLoadDeliveryVehiclesByTripId(
    LoadDeliveryVehiclesByTripIdEvent event,
    Emitter<DeliveryVehicleState> emit,
  ) async {
    emit(DeliveryVehicleLoading());
    debugPrint('🔄 Loading delivery vehicles for trip: ${event.tripId}');

    final result = await _loadDeliveryVehiclesByTripId(event.tripId);
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load delivery vehicles: ${failure.message}');
        emit(DeliveryVehicleError(failure.message));
      },
      (vehicles) {
        debugPrint('✅ Successfully loaded ${vehicles.length} delivery vehicles');
        emit(DeliveryVehiclesLoaded(vehicles));
      },
    );
  }

  Future<void> _onLoadAllDeliveryVehicles(
    LoadAllDeliveryVehiclesEvent event,
    Emitter<DeliveryVehicleState> emit,
  ) async {
    emit(DeliveryVehicleLoading());
    debugPrint('🔄 Loading all delivery vehicles');

    final result = await _loadAllDeliveryVehicles();
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load all delivery vehicles: ${failure.message}');
        emit(DeliveryVehicleError(failure.message));
      },
      (vehicles) {
        debugPrint('✅ Successfully loaded ${vehicles.length} delivery vehicles');
        emit(DeliveryVehiclesLoaded(vehicles));
      },
    );
  }
}
