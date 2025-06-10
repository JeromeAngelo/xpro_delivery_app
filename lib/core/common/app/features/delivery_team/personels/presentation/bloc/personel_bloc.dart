import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/usecase/get_personels.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/usecase/load_personels_by_delivery_team.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/usecase/load_personels_by_trip_Id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/domain/usecase/set_role.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/presentation/bloc/personel_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/presentation/bloc/personel_state.dart';
class PersonelBloc extends Bloc<PersonelEvent, PersonelState> {
  final GetPersonels _getPersonels;
  final SetRole _setRole;
  final LoadPersonelsByTripId _loadPersonelsByTripId;
  final LoadPersonelsByDeliveryTeam _loadPersonelsByDeliveryTeam;

  PersonelBloc({
    required GetPersonels getPersonels,
    required SetRole setRole,
    required LoadPersonelsByTripId loadPersonelsByTripId,
    required LoadPersonelsByDeliveryTeam loadPersonelsByDeliveryTeam,
  })  : _getPersonels = getPersonels,
        _setRole = setRole,
        _loadPersonelsByTripId = loadPersonelsByTripId,
        _loadPersonelsByDeliveryTeam = loadPersonelsByDeliveryTeam,
        super(PersonelInitial()) {
    on<GetPersonelEvent>(_onGetPersonelsHandler);
    on<SetRoleEvent>(_onSetRoleHandler);
    on<LoadPersonelsByTripIdEvent>(_onLoadPersonelsByTripId);
    on<LoadPersonelsByDeliveryTeamEvent>(_onLoadPersonelsByDeliveryTeam);
    on<LoadLocalPersonelsByTripIdEvent>(_onLoadLocalPersonelsByTripId);
    on<LoadLocalPersonelsByDeliveryTeamEvent>(_onLoadLocalPersonelsByDeliveryTeam);
  }

  Future<void> _onGetPersonelsHandler(
    GetPersonelEvent event,
    Emitter<PersonelState> emit,
  ) async {
    emit( PersonelLoading());
    final result = await _getPersonels();
    result.fold(
      (failure) => emit(PersonelError(failure.message)),
      (personels) => emit(PersonelLoaded(personels)),
    );
  }

  Future<void> _onSetRoleHandler(
    SetRoleEvent event,
    Emitter<PersonelState> emit,
  ) async {
    emit( PersonelLoading());
    final result = await _setRole(
      SetRoleParams(id: event.id, newRole: event.newRole),
    );
    result.fold(
      (failure) => emit(PersonelError(failure.message)),
      (_) => emit(SetRoleState(event.newRole)),
    );
  }

  Future<void> _onLoadPersonelsByTripId(
    LoadPersonelsByTripIdEvent event,
    Emitter<PersonelState> emit,
  ) async {
    emit( PersonelLoading());
    final result = await _loadPersonelsByTripId(event.tripId);
    result.fold(
      (failure) => emit(PersonelError(failure.message)),
      (personels) => emit(PersonelsByTripLoaded(personels)),
    );
  }

  Future<void> _onLoadPersonelsByDeliveryTeam(
    LoadPersonelsByDeliveryTeamEvent event,
    Emitter<PersonelState> emit,
  ) async {
    emit( PersonelLoading());
    final result = await _loadPersonelsByDeliveryTeam(event.deliveryTeamId);
    result.fold(
      (failure) => emit(PersonelError(failure.message)),
      (personels) => emit(PersonelsByDeliveryTeamLoaded(personels)),
    );
  }

  Future<void> _onLoadLocalPersonelsByTripId(
    LoadLocalPersonelsByTripIdEvent event,
    Emitter<PersonelState> emit,
  ) async {
    emit( PersonelLoading());
    final result = await _loadPersonelsByTripId.loadFromLocal(event.tripId);
    result.fold(
      (failure) => emit(PersonelError(failure.message)),
      (personels) => emit(PersonelsByTripLoaded(personels, isFromLocal: true)),
    );
  }

  Future<void> _onLoadLocalPersonelsByDeliveryTeam(
    LoadLocalPersonelsByDeliveryTeamEvent event,
    Emitter<PersonelState> emit,
  ) async {
    emit( PersonelLoading());
    final result = await _loadPersonelsByDeliveryTeam.loadFromLocal(event.deliveryTeamId);
    result.fold(
      (failure) => emit(PersonelError(failure.message)),
      (personels) => emit(PersonelsByDeliveryTeamLoaded(personels, isFromLocal: true)),
    );
  }
}
