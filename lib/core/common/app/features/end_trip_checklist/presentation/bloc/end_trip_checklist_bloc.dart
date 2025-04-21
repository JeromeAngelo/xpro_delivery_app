import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/usecase/check_end_trip_checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/usecase/generate_end_trip_checklist.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/usecase/load_end_trip_checklist.dart';

import './end_trip_checklist_event.dart';
import './end_trip_checklist_state.dart';
class EndTripChecklistBloc extends Bloc<EndTripChecklistEvent, EndTripChecklistState> {
  final GenerateEndTripChecklist _generateEndTripChecklist;
  final CheckEndTripChecklist _checkEndTripChecklist;
  final LoadEndTripChecklist _loadEndTripChecklist;
  EndTripChecklistState? _cachedState;

  EndTripChecklistBloc({
    required GenerateEndTripChecklist generateEndTripChecklist,
    required CheckEndTripChecklist checkEndTripChecklist,
    required LoadEndTripChecklist loadEndTripChecklist,
  })  : _generateEndTripChecklist = generateEndTripChecklist,
        _checkEndTripChecklist = checkEndTripChecklist,
        _loadEndTripChecklist = loadEndTripChecklist,
        super(EndTripChecklistInitial()) {
    on<GenerateEndTripChecklistEvent>(_onGenerateEndTripChecklist);
    on<CheckEndTripItemEvent>(_onCheckEndTripItem);
    on<LoadEndTripChecklistEvent>(_onLoadEndTripChecklist);
    on<LoadLocalEndTripChecklistEvent>(_onLoadLocalEndTripChecklist);
  }

Future<void> _onGenerateEndTripChecklist(
  GenerateEndTripChecklistEvent event,
  Emitter<EndTripChecklistState> emit,
) async {
  debugPrint('🔄 Generating checklist for trip: ${event.tripId}');
  emit(EndTripChecklistLoading());

  final result = await _generateEndTripChecklist(event.tripId);
  result.fold(
    (failure) => emit(EndTripChecklistError(failure.message)),
    (checklists) {
      final newState = EndTripChecklistLoaded(checklists);
      _cachedState = newState;
      emit(newState);
      // Load local data immediately
      add(LoadLocalEndTripChecklistEvent(event.tripId));
      // Then refresh with remote data
      add(LoadEndTripChecklistEvent(event.tripId));
    },
  );
}

Future<void> _onCheckEndTripItem(
  CheckEndTripItemEvent event,
  Emitter<EndTripChecklistState> emit,
) async {
  debugPrint('🔄 Bloc: Checking item ${event.id}');
  
  if (_cachedState is EndTripChecklistLoaded) {
    final currentState = _cachedState as EndTripChecklistLoaded;
    emit(EndTripChecklistLoading());

    final result = await _checkEndTripChecklist(event.id);
    result.fold(
      (failure) {
        debugPrint('❌ Bloc: Check failed - ${failure.message}');
        emit(EndTripChecklistError(failure.message));
      },
      (isChecked) {
        final updatedChecklists = currentState.checklists.map((item) {
          if (item.id == event.id) {
            return item..isChecked = isChecked;
          }
          return item;
        }).toList();
        
        final newState = EndTripChecklistLoaded(updatedChecklists);
        _cachedState = newState;
        emit(newState);
        debugPrint('✅ Bloc: Item checked successfully');
      },
    );
  }
}


  Future<void> _onLoadEndTripChecklist(
    LoadEndTripChecklistEvent event,
    Emitter<EndTripChecklistState> emit,
  ) async {
    if (_cachedState != null) {
      emit(_cachedState!);
    } else {
      emit(EndTripChecklistLoading());
    }

    final result = await _loadEndTripChecklist(event.tripId);
    result.fold(
      (failure) {
        debugPrint('❌ Bloc: Load failed - ${failure.message}');
        emit(EndTripChecklistError(failure.message));
      },
      (checklists) {
        debugPrint('✅ Bloc: Loaded ${checklists.length} items');
        final newState = EndTripChecklistLoaded(checklists);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

Future<void> _onLoadLocalEndTripChecklist(
  LoadLocalEndTripChecklistEvent event,
  Emitter<EndTripChecklistState> emit,
) async {
  debugPrint('📱 Loading local end trip checklist');
  if (_cachedState != null) {
    emit(_cachedState!);
  }
  
  emit(EndTripChecklistLoading());
  final result = await _loadEndTripChecklist.loadFromLocal(event.tripId);
  
  result.fold(
    (failure) {
      emit(EndTripChecklistError(failure.message));
      add(LoadEndTripChecklistEvent(event.tripId));
    },
    (checklists) {
      final newState = EndTripChecklistLoaded(checklists);
      _cachedState = newState;
      emit(newState);
      add(LoadEndTripChecklistEvent(event.tripId));
    },
  );
}

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
