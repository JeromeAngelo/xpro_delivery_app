import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/usecase/check_Item.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/usecase/load_Checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/usecase/load_checklist_by_trip_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_state.dart';
class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  ChecklistBloc({
    required LoadChecklist loadChecklist,
    required CheckItem checkItem,
    required LoadChecklistByTripId loadChecklistByTripId,
  })  : _loadChecklist = loadChecklist,
        _checkItem = checkItem,
        _loadChecklistByTripId = loadChecklistByTripId,
        super(ChecklistInitial()) {
    on<LoadChecklistEvent>(_onLoadChecklistHandler);
    on<CheckItemEvent>(_onCheckItemHandler);
    on<LoadChecklistByTripIdEvent>(_onLoadChecklistByTripIdHandler);
    on<LoadLocalChecklistByTripIdEvent>(_onLoadLocalChecklistByTripIdHandler);
  }

  final LoadChecklist _loadChecklist;
  final CheckItem _checkItem;
  final LoadChecklistByTripId _loadChecklistByTripId;
  ChecklistState? _cachedState;

  Future<void> _onLoadChecklistHandler(
    LoadChecklistEvent event,
    Emitter<ChecklistState> emit,
  ) async {
    debugPrint('Loading checklist...');
    emit(ChecklistLoading());
    final result = await _loadChecklist();
    debugPrint('Checklist load result received');

    result.fold(
      (failure) {
        debugPrint('Checklist load failed: ${failure.message}');
        emit(ChecklistError(failure.message));
      },
      (checklist) {
        debugPrint('Checklist loaded successfully');
        final mappedChecklist = checklist.map((item) => ChecklistModel(
              id: item.id,
              objectName: item.objectName,
              isChecked: item.isChecked,
              status: item.status,
            )).toList();
        _cachedState = ChecklistLoaded(mappedChecklist);
        emit(_cachedState!);
      },
    );
  }

  Future<void> _onLoadChecklistByTripIdHandler(
    LoadChecklistByTripIdEvent event,
    Emitter<ChecklistState> emit,
  ) async {
    debugPrint('🔄 Loading checklist for trip: ${event.tripId}');
    emit(ChecklistLoading());

    final result = await _loadChecklistByTripId(event.tripId);
    result.fold(
      (failure) {
        debugPrint('❌ Checklist load failed: ${failure.message}');
        emit(ChecklistError(failure.message));
      },
      (checklist) {
        debugPrint('✅ Checklist loaded successfully');
        _cachedState = ChecklistLoaded(checklist);
        emit(_cachedState!);
      },
    );
  }
Future<void> _onLoadLocalChecklistByTripIdHandler(
  LoadLocalChecklistByTripIdEvent event,
  Emitter<ChecklistState> emit,
) async {
  debugPrint('📱 Loading local checklist for trip: ${event.tripId}');
  if (_cachedState != null) {
    emit(_cachedState!);
  }
  
  emit(ChecklistLoading());
  final result = await _loadChecklistByTripId.loadFromLocal(event.tripId);
  
  result.fold(
    (failure) {
      emit(ChecklistError(failure.message));
      add(LoadChecklistByTripIdEvent(event.tripId));
    },
    (checklist) {
      final newState = ChecklistLoaded(checklist);
      _cachedState = newState;
      emit(newState);
      add(LoadChecklistByTripIdEvent(event.tripId));
    },
  );
}



Future<void> _onCheckItemHandler(
  CheckItemEvent event,
  Emitter<ChecklistState> emit,
) async {
  debugPrint('🔄 Checking item: ${event.id}');
  
  if (_cachedState is ChecklistLoaded) {
    final currentState = _cachedState as ChecklistLoaded;
    emit(ChecklistLoading());

    final result = await _checkItem(event.id);
    result.fold(
      (failure) => emit(ChecklistError(failure.message)),
      (isChecked) {
        final updatedChecklist = currentState.checklist.map((item) {
          if (item.id == event.id) {
            return item..isChecked = isChecked;
          }
          return item;
        }).toList();
        
        final newState = ChecklistLoaded(updatedChecklist);
        _cachedState = newState;
        emit(newState);
      },
    );
  }
}



  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
