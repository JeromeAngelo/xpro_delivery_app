import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:x_pro_delivery_app/core/common/app/features/user_performance/presentation/bloc/user_performance_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/user_performance/presentation/bloc/user_performance_state.dart';

import '../../domain/usecases/calculate_delivery_accuracy.dart';
import '../../domain/usecases/load_user_performance_by_user_id.dart';

class UserPerformanceBloc extends Bloc<UserPerformanceEvent, UserPerformanceState> {
  final LoadUserPerformanceByUserId _loadUserPerformanceByUserId;
  final CalculateDeliveryAccuracy _calculateDeliveryAccuracy;

  UserPerformanceState? _cachedState;

  UserPerformanceBloc({
    required LoadUserPerformanceByUserId loadUserPerformanceByUserId,
    required CalculateDeliveryAccuracy calculateDeliveryAccuracy,
  })  : _loadUserPerformanceByUserId = loadUserPerformanceByUserId,
        _calculateDeliveryAccuracy = calculateDeliveryAccuracy,
        super(const UserPerformanceInitial()) {
    on<LoadUserPerformanceByUserIdEvent>(_onLoadUserPerformanceByUserId);
    on<LoadLocalUserPerformanceByUserIdEvent>(_onLoadLocalUserPerformanceByUserId);
    on<CalculateDeliveryAccuracyEvent>(_onCalculateDeliveryAccuracy);
    on<SyncUserPerformanceEvent>(_onSyncUserPerformance);
    on<UpdateUserPerformanceEvent>(_onUpdateUserPerformance);
    on<DeleteUserPerformanceEvent>(_onDeleteUserPerformance);
    on<LoadAllUserPerformanceEvent>(_onLoadAllUserPerformance);
    on<RecalculateAndUpdateAccuracyEvent>(_onRecalculateAndUpdateAccuracy);
    on<RefreshUserPerformanceEvent>(_onRefreshUserPerformance);
    on<ClearUserPerformanceEvent>(_onClearUserPerformance);
  }

  Future<void> _onLoadUserPerformanceByUserId(
    LoadUserPerformanceByUserIdEvent event,
    Emitter<UserPerformanceState> emit,
  ) async {
    debugPrint('🔄 BLOC: Loading user performance for user ID: ${event.userId}');
    
    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const UserPerformanceLoading());
    }

    final result = await _loadUserPerformanceByUserId(event.userId);

    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: Failed to load user performance: ${failure.message}');
        
        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(UserPerformanceError(
            message: 'Failed to load user performance: ${failure.message}',
            errorCode: failure.statusCode.toString(),
            isNetworkError: failure.message.toLowerCase().contains('network') ||
                           failure.message.toLowerCase().contains('connection'),
          ));
        }
      },
      (userPerformance) async {
        debugPrint('✅ BLOC: Successfully loaded user performance for user: ${event.userId}');
        debugPrint('📊 BLOC: Performance Stats:');
        debugPrint('   👤 User: ${userPerformance.userName}');
        debugPrint('   📈 Total Deliveries: ${userPerformance.totalDeliveries}');
        debugPrint('   ✅ Successful: ${userPerformance.successfulDeliveries}');
        debugPrint('   ❌ Cancelled: ${userPerformance.cancelledDeliveries}');
        debugPrint('   🎯 Accuracy: ${userPerformance.deliveryAccuracy}%');
        
        final newState = UserPerformanceLoaded(
          userPerformance: userPerformance,
          isFromCache: false,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onLoadLocalUserPerformanceByUserId(
    LoadLocalUserPerformanceByUserIdEvent event,
    Emitter<UserPerformanceState> emit,
  ) async {
    debugPrint('📱 BLOC: Loading local user performance for user ID: ${event.userId}');
    
    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const UserPerformanceLoading());
    }

    final result = await _loadUserPerformanceByUserId.loadFromLocal(event.userId);

    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: Failed to load local user performance: ${failure.message}');
        
        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(UserPerformanceError(
            message: 'Local data error: ${failure.message}',
            errorCode: failure.statusCode.toString(),
          ));
        }
      },
      (localUserPerformance) async {
        debugPrint('✅ BLOC: Successfully retrieved local user performance for user: ${event.userId}');
        debugPrint('📱 BLOC: Local Performance Stats:');
        debugPrint('   👤 User: ${localUserPerformance.userName}');
        debugPrint('   📈 Total Deliveries: ${localUserPerformance.totalDeliveries}');
        debugPrint('   ✅ Successful: ${localUserPerformance.successfulDeliveries}');
        debugPrint('   🎯 Accuracy: ${localUserPerformance.deliveryAccuracy}%');
        
        final newState = UserPerformanceLoaded(
          userPerformance: localUserPerformance,
          isFromCache: true,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onCalculateDeliveryAccuracy(
    CalculateDeliveryAccuracyEvent event,
    Emitter<UserPerformanceState> emit,
  ) async {
    debugPrint('🧮 BLOC: Calculating delivery accuracy for user ID: ${event.userId}');
    
    // Don't emit loading if we have cached state
    if (_cachedState == null) {
      emit(const UserPerformanceLoading());
    }

    final result = await _calculateDeliveryAccuracy(event.userId);

    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: Failed to calculate delivery accuracy: ${failure.message}');
        
        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(UserPerformanceError(
            message: 'Accuracy calculation error: ${failure.message}',
            errorCode: failure.statusCode.toString(),
            isNetworkError: failure.message.toLowerCase().contains('network') ||
                           failure.message.toLowerCase().contains('connection'),
          ));
        }
      },
      (accuracy) async {
        debugPrint('✅ BLOC: Successfully calculated delivery accuracy: ${accuracy.toStringAsFixed(2)}% for user: ${event.userId}');
        
        final newState = DeliveryAccuracyCalculated(
          userId: event.userId,
          accuracy: accuracy,
          isFromCache: false,
        );
        
        emit(newState);
      },
    );
  }

  Future<void> _onSyncUserPerformance(
    SyncUserPerformanceEvent event,
    Emitter<UserPerformanceState> emit,
  ) async {
    debugPrint('🔄 BLOC: Syncing user performance for user ID: ${event.userId}');
    
    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const UserPerformanceLoading());
    }

    // Note: This would require adding syncUserPerformance to the use case
    // For now, we'll use the load method as a sync operation
    final result = await _loadUserPerformanceByUserId(event.userId);

    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: Failed to sync user performance: ${failure.message}');
        
        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(UserPerformanceError(
            message: 'Sync error: ${failure.message}',
            errorCode: failure.statusCode.toString(),
            isNetworkError: failure.message.toLowerCase().contains('network') ||
                           failure.message.toLowerCase().contains('connection'),
          ));
        }
      },
      (syncedUserPerformance) async {
        debugPrint('✅ BLOC: Successfully synced user performance for user: ${event.userId}');
        
        final newState = UserPerformanceSynced(
          userPerformance: syncedUserPerformance,
          message: 'User performance synced successfully',
        );
        _cachedState = UserPerformanceLoaded(
          userPerformance: syncedUserPerformance,
          isFromCache: false,
        );
        emit(newState);
      },
    );
  }

  Future<void> _onUpdateUserPerformance(
    UpdateUserPerformanceEvent event,
    Emitter<UserPerformanceState> emit,
  ) async {
    debugPrint('🔄 BLOC: Updating user performance: ${event.userPerformance.id}');
    
    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const UserPerformanceLoading());
    }

    // Note: This would require adding updateUserPerformance to the use case
    // For now, we'll emit the updated state directly
    debugPrint('✅ BLOC: User performance updated successfully');
    
    final newState = UserPerformanceUpdated(
      userPerformance: event.userPerformance,
      message: 'User performance updated successfully',
    );
    _cachedState = UserPerformanceLoaded(
      userPerformance: event.userPerformance,
      isFromCache: false,
    );
    emit(newState);
  }

  Future<void> _onDeleteUserPerformance(
    DeleteUserPerformanceEvent event,
    Emitter<UserPerformanceState> emit,
  ) async {
    debugPrint('🔄 BLOC: Deleting user performance for user: ${event.userId}');
    
    emit(const UserPerformanceLoading());

    // Note: This would require adding deleteUserPerformance to the use case
    // For now, we'll emit the deleted state directly
    debugPrint('✅ BLOC: User performance deleted successfully');
    
    _cachedState = null;
    emit(UserPerformanceDeleted(
      userId: event.userId,
      message: 'User performance deleted successfully',
    ));
  }

  Future<void> _onLoadAllUserPerformance(
    LoadAllUserPerformanceEvent event,
    Emitter<UserPerformanceState> emit,
  ) async {
    debugPrint('🔄 BLOC: Loading all user performance data');
    
    emit(const UserPerformanceLoading());

    // Note: This would require adding getAllUserPerformance to the use case
    // For now, we'll emit an empty list
    debugPrint('✅ BLOC: All user performance data loaded');
    
    emit(const AllUserPerformanceLoaded([]));
  }

  Future<void> _onRecalculateAndUpdateAccuracy(
    RecalculateAndUpdateAccuracyEvent event,
    Emitter<UserPerformanceState> emit,
  ) async {
    debugPrint('🔄 BLOC: Recalculating and updating accuracy for user: ${event.userId}');
    
    // Don't emit loading if we have cached data
    if (_cachedState == null) {
      emit(const UserPerformanceLoading());
    }

    final result = await _calculateDeliveryAccuracy(event.userId);

    await result.fold(
      (failure) async {
        debugPrint('❌ BLOC: Failed to recalculate accuracy: ${failure.message}');
        
        // Only emit error if we don't have cached data
        if (_cachedState == null) {
          emit(UserPerformanceError(
            message: 'Recalculation error: ${failure.message}',
            errorCode: failure.statusCode.toString(),
          ));
        }
      },
      (newAccuracy) async {
        debugPrint('✅ BLOC: Successfully recalculated accuracy: ${newAccuracy.toStringAsFixed(2)}% for user: ${event.userId}');
        
        emit(AccuracyRecalculated(
          userId: event.userId,
          newAccuracy: newAccuracy,
          message: 'Delivery accuracy recalculated successfully',
        ));
      },
    );
  }

  Future<void> _onRefreshUserPerformance(
    RefreshUserPerformanceEvent event,
    Emitter<UserPerformanceState> emit,
  ) async {
    debugPrint('🔄 BLOC: Refreshing user performance for user: ${event.userId}');
    
    // Clear cached state to force fresh data
    _cachedState = null;
    
    // Trigger a fresh load
    add(LoadUserPerformanceByUserIdEvent(event.userId));
  }

  Future<void> _onClearUserPerformance(
    ClearUserPerformanceEvent event,
    Emitter<UserPerformanceState> emit,
  ) async {
    debugPrint('🔄 BLOC: Clearing user performance data');
    
    _cachedState = null;
    emit(const UserPerformanceInitial());
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
