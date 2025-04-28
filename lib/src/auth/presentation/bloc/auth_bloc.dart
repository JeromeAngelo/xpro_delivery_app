import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/get_user_by_id.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/get_user_trip.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/load_user.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/refresh_data.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/sign_in.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/sync_trip_data.dart';
import 'package:x_pro_delivery_app/src/auth/domain/usecases/sync_user_data.dart';

import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignIn signIn,
    required RefreshUserData refreshUserData,
    required GetUserById getUserById,
    required LoadUser loadUser,
    required GetUserTrip getUserTrip,
    required SyncUserData syncUserData,
    required SyncUserTripData syncUserTripData,
  }) : _signIn = signIn,
       _refreshUserData = refreshUserData,
       _getUserById = getUserById,
       _loadUser = loadUser,
       _getUserTrip = getUserTrip,
       _syncUserData = syncUserData,
       _syncUserTripData = syncUserTripData,
       super(const AuthInitial()) {
    on<SignInEvent>(_signInHandler);
    on<RefreshUserDataEvent>(_refreshUserDataHandler);
    on<LoadUserByIdEvent>(_onLoadUserById);
    on<LoadLocalUserByIdEvent>(_onLoadLocalUserById);
    on<LoadLocalUserDataEvent>(_onLoadLocalUserData);
    on<LoadRemoteUserDataEvent>(_onLoadRemoteUserData);
    on<GetUserTripEvent>(_onGetUserTrip);
    on<LoadLocalUserTripEvent>(_onLoadLocalUserTrip);
    on<SyncUserDataEvent>(_onSyncUserData);
    on<SyncUserTripDataEvent>(_onSyncUserTripData);
    on<RefreshUserEvent>(_onRefreshUser);
  }

  final SignIn _signIn;
  final RefreshUserData _refreshUserData;
  final GetUserById _getUserById;
  final LoadUser _loadUser;
  final GetUserTrip _getUserTrip;
  final SyncUserData _syncUserData;
  final SyncUserTripData _syncUserTripData;

  // Add this method to the AuthBloc class:
  Future<void> _onRefreshUser(
    RefreshUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Get current user ID
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('user_data');

    if (storedData != null) {
      try {
        final userData = jsonDecode(storedData);
        final userId = userData['id'];

        if (userId != null) {
          debugPrint('🔄 Refreshing user data for ID: $userId');

          // First load from local to ensure we have some data to display
          final localResult = await _getUserById.loadFromLocal(userId);

          await localResult.fold(
            (failure) async {
              debugPrint(
                '⚠️ Failed to load user from local: ${failure.message}',
              );
            },
            (user) async {
              // Emit the local user data first for immediate UI update
              emit(UserByIdLoaded(user));

              // Then try to get fresh data from remote
              final remoteResult = await _getUserById(userId);

              remoteResult.fold(
                (failure) {
                  debugPrint(
                    '⚠️ Failed to refresh user from remote: ${failure.message}',
                  );
                  // We already emitted the local data, so no need to emit an error
                },
                (freshUser) {
                  debugPrint('✅ Successfully refreshed user data from remote');
                  emit(UserByIdLoaded(freshUser));

                  // Also refresh the user's trip data
                  add(GetUserTripEvent(userId));
                },
              );
            },
          );
        } else {
          emit(const AuthError('User ID not found in stored data'));
        }
      } catch (e) {
        emit(AuthError('Error parsing stored user data: $e'));
      }
    } else {
      emit(const AuthError('No stored user data found'));
    }
  }

  Future<void> _onLoadUserById(
    LoadUserByIdEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔍 Loading user by ID: ${event.userId}');
    emit(const AuthLoading());

    final result = await _getUserById(event.userId);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(UserByIdLoaded(user)),
    );
  }

  Future<void> _onLoadLocalUserById(
    LoadLocalUserByIdEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('📱 Loading user by ID: ${event.userId}');
    emit(const AuthLoading());

    final result = await _getUserById.loadFromLocal(event.userId);
    result.fold(
      (failure) {
        debugPrint('⚠️ Local load failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        debugPrint('✅ User loaded successfully');
        debugPrint('   👤 Name: ${user.name}');
        debugPrint('   📧 Email: ${user.email}');
        debugPrint('   🎫 Trip Number: ${user.tripNumberId}');
        emit(UserByIdLoaded(user));
      },
    );
  }

  Future<void> _onLoadLocalUserData(
    LoadLocalUserDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('📱 Loading local user data');
    emit(const AuthLoading());

    final result = await _loadUser.loadFromLocal();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(LocalUserDataLoaded(user)),
    );
  }

  Future<void> _onLoadRemoteUserData(
    LoadRemoteUserDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🌐 Loading remote user data');
    emit(const AuthLoading());

    final result = await _loadUser();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(RemoteUserDataLoaded(user)),
    );
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final result = await _refreshUserData();
      result.fold(
        (failure) => add(const SignOutEvent()),
        (user) => emit(SignedIn(user)),
      );
    }
  }

  Future<void> _signInHandler(
    SignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔄 Processing sign-in request');
    emit(const AuthLoading());

    final result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) {
        debugPrint('❌ Sign-in failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        debugPrint('✅ Sign-in successful');
        debugPrint('   👤 User: ${user.name}');
        debugPrint('   📧 Email: ${user.email}');
        debugPrint('   ID: ${user.id}');

        emit(SignedIn(user));
      },
    );
  }

  Future<void> _refreshUserDataHandler(
    RefreshUserDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _refreshUserData();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(UserDataRefreshed(user)),
    );
  }

  Future<void> _onGetUserTrip(
    GetUserTripEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔍 Loading user trip for ID: ${event.userId}');
    emit(const UserTripLoading());

    final result = await _getUserTrip(event.userId);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (trip) => emit(UserTripLoaded(trip)),
    );
  }

  Future<void> _onLoadLocalUserTrip(
    LoadLocalUserTripEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('📱 Loading local user trip data for ID: ${event.userId}');
    emit(const UserTripLoading());

    final localResult = await _getUserTrip.loadFromLocal(event.userId);

    await localResult.fold(
      (failure) async {
        debugPrint('⚠️ Local trip fetch failed, attempting remote fetch');
        final remoteResult = await _getUserTrip(event.userId);

        remoteResult.fold(
          (failure) {
            debugPrint('❌ Remote fetch also failed: ${failure.message}');
            emit(AuthError(failure.message));
          },
          (trip) {
            debugPrint('✅ Successfully fetched trip from remote');
            debugPrint('   🎫 Trip ID: ${trip.id}');
            debugPrint('   📅 Created: ${trip.created}');
            emit(UserTripLoaded(trip));
          },
        );
      },
      (trip) {
        debugPrint('✅ Successfully loaded trip from local storage');
        debugPrint('   🎫 Trip ID: ${trip.id}');
        emit(UserTripLoaded(trip, isFromLocal: true));
      },
    );
  }

  Future<void> _onSyncUserData(
    SyncUserDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔄 Starting user data sync for ID: ${event.userId}');
    emit(const UserDataSyncing());

    final result = await _syncUserData(event.userId);
    result.fold(
      (failure) {
        debugPrint('❌ User sync failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (_) {
        debugPrint('✅ User data synced successfully');
        emit(const UserDataSynced());
      },
    );
  }

  Future<void> _onSyncUserTripData(
    SyncUserTripDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('🔄 Starting trip data sync for user: ${event.userId}');
    emit(const TripDataSyncing());

    final result = await _syncUserTripData(event.userId);
    result.fold(
      (failure) {
        debugPrint('❌ Trip sync failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (_) {
        debugPrint('✅ Trip data synced successfully');
        emit(const TripDataSynced());
      },
    );
  }
}
