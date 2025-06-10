import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/usecase/get_vehicle.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/usecase/load_vehicle_by_delivery_team_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/domain/usecase/load_vehicle_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/presentation/bloc/vehicle_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/presentation/bloc/vehicle_state.dart';
class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final GetVehicle _getVehicle;
  final LoadVehicleByTripId _loadVehicleByTripId;
  final LoadVehicleByDeliveryTeam _loadVehicleByDeliveryTeam;

  VehicleBloc({
    required GetVehicle getVehicle,
    required LoadVehicleByTripId loadVehicleByTripId,
    required LoadVehicleByDeliveryTeam loadVehicleByDeliveryTeam,
  }) : _getVehicle = getVehicle,
       _loadVehicleByTripId = loadVehicleByTripId,
       _loadVehicleByDeliveryTeam = loadVehicleByDeliveryTeam,
       super(const VehicleInitial()) {
    on<GetVehicleEvent>(_onGetVehicleHandler);
    on<LoadVehicleByTripIdEvent>(_onLoadVehicleByTripId);
    on<LoadVehicleByDeliveryTeamEvent>(_onLoadVehicleByDeliveryTeam);
    on<LoadLocalVehicleByTripIdEvent>(_onLoadLocalVehicleByTripId);
    on<LoadLocalVehicleByDeliveryTeamEvent>(_onLoadLocalVehicleByDeliveryTeam);
  }

  Future<void> _onGetVehicleHandler(
    GetVehicleEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(const VehicleLoading());
    final result = await _getVehicle();
    result.fold(
      (failure) => emit(VehicleError(failure.message)),
      (vehicle) => emit(VehicleLoaded(vehicle)),
    );
  }

  Future<void> _onLoadVehicleByTripId(
    LoadVehicleByTripIdEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(const VehicleLoading());
    final result = await _loadVehicleByTripId(event.tripId);
    result.fold(
      (failure) => emit(VehicleError(failure.message)),
      (vehicle) => emit(VehicleByTripLoaded(vehicle)),
    );
  }

  Future<void> _onLoadVehicleByDeliveryTeam(
    LoadVehicleByDeliveryTeamEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(const VehicleLoading());
    final result = await _loadVehicleByDeliveryTeam(event.deliveryTeamId);
    result.fold(
      (failure) => emit(VehicleError(failure.message)),
      (vehicle) => emit(VehicleByDeliveryTeamLoaded(vehicle)),
    );
  }

  Future<void> _onLoadLocalVehicleByTripId(
    LoadLocalVehicleByTripIdEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(const VehicleLoading());
    final result = await _loadVehicleByTripId.loadFromLocal(event.tripId);
    result.fold(
      (failure) => emit(VehicleError(failure.message)),
      (vehicle) => emit(VehicleByTripLoaded(vehicle, isFromLocal: true)),
    );
  }

  Future<void> _onLoadLocalVehicleByDeliveryTeam(
    LoadLocalVehicleByDeliveryTeamEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(const VehicleLoading());
    final result = await _loadVehicleByDeliveryTeam.loadFromLocal(event.deliveryTeamId);
    result.fold(
      (failure) => emit(VehicleError(failure.message)),
      (vehicle) => emit(VehicleByDeliveryTeamLoaded(vehicle, isFromLocal: true)),
    );
  }
}
