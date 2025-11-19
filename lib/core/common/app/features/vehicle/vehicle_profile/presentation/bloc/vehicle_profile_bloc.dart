import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../domain/usecases/create_vehicle_profile.dart';
import '../../domain/usecases/delete_vehicle_profile.dart';
import '../../domain/usecases/get_all_vehicle_profiles.dart';
import '../../domain/usecases/get_vehicle_profile_by_id.dart';
import '../../domain/usecases/update_vehicle_profile.dart';
import 'vehicle_profile_event.dart';
import 'vehicle_profile_state.dart';

class VehicleProfileBloc extends Bloc<VehicleProfileEvent, VehicleProfileState> {
  // Usecases
  final GetVehicleProfileById _getVehicleProfileById;
  final GetVehicleProfiles _getVehicleProfiles;
  final CreateVehicleProfile _createVehicleProfile;
  final UpdateVehicleProfile _updateVehicleProfile;
  final DeleteVehicleProfile _deleteVehicleProfile;

  VehicleProfileBloc({
    required GetVehicleProfileById getVehicleProfileById,
    required GetVehicleProfiles getVehicleProfiles,
    required CreateVehicleProfile createVehicleProfile,
    required UpdateVehicleProfile updateVehicleProfile,
    required DeleteVehicleProfile deleteVehicleProfile,
  })  : _getVehicleProfileById = getVehicleProfileById,
        _getVehicleProfiles = getVehicleProfiles,
        _createVehicleProfile = createVehicleProfile,
        _updateVehicleProfile = updateVehicleProfile,
        _deleteVehicleProfile = deleteVehicleProfile,
        super(const VehicleProfileInitial()) {
    on<GetVehicleProfilesEvent>(_onGetVehicleProfiles);
    on<GetVehicleProfileByIdEvent>(_onGetVehicleProfileById);
    on<CreateVehicleProfileEvent>(_onCreateVehicleProfile);
    on<UpdateVehicleProfileEvent>(_onUpdateVehicleProfile);
    on<DeleteVehicleProfileEvent>(_onDeleteVehicleProfile);
  }

  // -----------------------------
  // GET ALL VEHICLE PROFILES
  // -----------------------------
  Future<void> _onGetVehicleProfiles(
      GetVehicleProfilesEvent event,
      Emitter<VehicleProfileState> emit,
      ) async {
    emit(const VehicleProfileLoading());
    debugPrint('🔄 Fetching all vehicle profiles');

    final result = await _getVehicleProfiles();
    result.fold(
          (failure) {
        debugPrint('❌ Error fetching vehicle profiles: ${failure.message}');
        emit(VehicleProfileError(failure.message));
      },
          (profiles) {
        debugPrint('✅ Successfully fetched ${profiles.length} vehicle profiles');
        emit(VehicleProfilesLoaded(profiles));
      },
    );
  }

  // -----------------------------
  // GET VEHICLE PROFILE BY ID
  // -----------------------------
  Future<void> _onGetVehicleProfileById(
      GetVehicleProfileByIdEvent event,
      Emitter<VehicleProfileState> emit,
      ) async {
    emit(const VehicleProfileLoading());
    debugPrint('🔄 Fetching vehicle profile with ID: ${event.id}');

    final result = await _getVehicleProfileById(event.id);
    result.fold(
          (failure) {
        debugPrint('❌ Error fetching vehicle profile: ${failure.message}');
        emit(VehicleProfileError(failure.message));
      },
          (profile) {
        debugPrint('✅ Successfully fetched vehicle profile');
        emit(VehicleProfileByIdLoaded(profile));
      },
    );
  }

  // -----------------------------
  // CREATE VEHICLE PROFILE
  // -----------------------------
  Future<void> _onCreateVehicleProfile(
      CreateVehicleProfileEvent event,
      Emitter<VehicleProfileState> emit,
      ) async {
    emit(const VehicleProfileLoading());
    debugPrint('🔄 Creating vehicle profile');

    final result = await _createVehicleProfile(event.vehicleProfile);
    result.fold(
          (failure) {
        debugPrint('❌ Error creating vehicle profile: ${failure.message}');
        emit(VehicleProfileError(failure.message));
      },
          (profile) {
        debugPrint('✅ Successfully created vehicle profile');
        emit(VehicleProfileCreated(profile));
      },
    );
  }

  // -----------------------------
  // UPDATE VEHICLE PROFILE
  // -----------------------------
  Future<void> _onUpdateVehicleProfile(
      UpdateVehicleProfileEvent event,
      Emitter<VehicleProfileState> emit,
      ) async {
    emit(const VehicleProfileLoading());
    debugPrint('🔄 Updating vehicle profile with ID: ${event.id}');

    final result = await _updateVehicleProfile(
      UpdateVehicleProfileParams(
        id: event.id,
        updatedData: event.updatedVehicleProfile,
      ),
    );
    result.fold(
          (failure) {
        debugPrint('❌ Error updating vehicle profile: ${failure.message}');
        emit(VehicleProfileError(failure.message));
      },
          (profile) {
        debugPrint('✅ Successfully updated vehicle profile');
        emit(VehicleProfileUpdated(profile));
      },
    );
  }

  // -----------------------------
  // DELETE VEHICLE PROFILE
  // -----------------------------
  Future<void> _onDeleteVehicleProfile(
      DeleteVehicleProfileEvent event,
      Emitter<VehicleProfileState> emit,
      ) async {
    emit(const VehicleProfileLoading());
    debugPrint('🔄 Deleting vehicle profile with ID: ${event.id}');

    final result = await _deleteVehicleProfile(event.id);
    result.fold(
          (failure) {
        debugPrint('❌ Error deleting vehicle profile: ${failure.message}');
        emit(VehicleProfileError(failure.message));
      },
          (_) {
        debugPrint('✅ Successfully deleted vehicle profile');
        emit(VehicleProfileDeleted(event.id));
      },
    );
  }
}
