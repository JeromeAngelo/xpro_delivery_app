import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/usecases/sign_in.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/usecases/get_user_by_id.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/usecases/load_user.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/usecases/refresh_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/usecases/get_user_trip.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/usecases/sync_user_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/usecases/sync_trip_data.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/repo/auth_repo_impl.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../../fixtures/auth_fixture.dart' show AuthFixture;
import '../../../../../../mocks/mocktail_mocks.dart';

/// Mock test functions for Auth functionality
///
/// This file contains comprehensive mock tests for the authentication system,
/// covering use cases, repository, data sources, and BLoC.
void main() {
  // ============================================================================
  // FALLBACK VALUES SETUP
  // ============================================================================

  setUpAll(() {
    // Register fallback values for mocktail matchers
    registerFallbackValue('');
    registerFallbackValue(AuthFixture.tUser);
    registerFallbackValue(AuthFixture.tTrip);
  });

  // ============================================================================
  // MOCKS SETUP
  // ============================================================================

  late MockAuthRemoteDataSrc mockRemoteDataSrc;
  late MockAuthLocalDataSrc mockLocalDataSrc;
  late MockAuthRepo mockAuthRepo;
  late MockOfflineSyncService mockOfflineSyncService;
  late MockConnectivityProvider mockConnectivityProvider;

  setUp(() {
    mockRemoteDataSrc = MockAuthRemoteDataSrc();
    mockLocalDataSrc = MockAuthLocalDataSrc();
    mockAuthRepo = MockAuthRepo();
    mockOfflineSyncService = MockOfflineSyncService();
    mockConnectivityProvider = MockConnectivityProvider();
  });

  // ============================================================================
  // USE CASE TESTS
  // ============================================================================

  group('SignIn UseCase Tests', () {
    late SignIn signIn;

    setUp(() {
      signIn = SignIn(mockAuthRepo);
    });

    test('should call repository signIn with correct parameters', () async {
      // Arrange
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(AuthFixture.tUser));

      // Act
      final result = await signIn(
        SignInParams(
          email: AuthFixture.tEmail,
          password: AuthFixture.tPassword,
        ),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not return failure'), (user) {
        expect(user.email, AuthFixture.tEmail);
        expect(user.name, 'Test User');
      });
      verify(
        () => mockAuthRepo.signIn(
          email: AuthFixture.tEmail,
          password: AuthFixture.tPassword,
        ),
      ).called(1);
    });

    test('should return failure when repository signIn fails', () async {
      // Arrange
      when(
        () => mockAuthRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => Left(
          ServerFailure(
            message: AuthFixture.tServerErrorMessage,
            statusCode: AuthFixture.tServerErrorCode,
          ),
        ),
      );

      // Act
      final result = await signIn(
        SignInParams(email: AuthFixture.tEmail, password: 'wrong_password'),
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure.message, AuthFixture.tServerErrorMessage);
        expect(failure.statusCode, AuthFixture.tServerErrorCode);
      }, (_) => fail('Should not return user'));
    });
  });

  group('GetUserById UseCase Tests', () {
    late GetUserById getUserById;

    setUp(() {
      getUserById = GetUserById(mockAuthRepo);
    });

    test('should call repository getUserById and return user', () async {
      // Arrange
      when(
        () => mockAuthRepo.getUserById(AuthFixture.tUserId),
      ).thenAnswer((_) async => Right(AuthFixture.tUser));

      // Act
      final result = await getUserById(AuthFixture.tUserId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not return failure'), (user) {
        expect(user.id, AuthFixture.tUserId);
        expect(user.email, AuthFixture.tEmail);
      });
      verify(() => mockAuthRepo.getUserById(AuthFixture.tUserId)).called(1);
    });

    test('should call loadFromLocal for offline-first operation', () async {
      // Arrange
      when(
        () => mockAuthRepo.loadLocalUserById(AuthFixture.tUserId),
      ).thenAnswer((_) async => Right(AuthFixture.tUser));

      // Act
      final result = await getUserById.loadFromLocal(AuthFixture.tUserId);

      // Assert
      expect(result.isRight(), true);
      verify(
        () => mockAuthRepo.loadLocalUserById(AuthFixture.tUserId),
      ).called(1);
    });
  });

  group('LoadUser UseCase Tests', () {
    late LoadUser loadUser;

    setUp(() {
      loadUser = LoadUser(mockAuthRepo);
    });

    test('should call repository loadUser', () async {
      // Arrange
      when(
        () => mockAuthRepo.loadUser(),
      ).thenAnswer((_) async => Right(AuthFixture.tUser));

      // Act
      final result = await loadUser();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockAuthRepo.loadUser()).called(1);
    });

    test('should call loadFromLocal for local data', () async {
      // Arrange
      when(
        () => mockAuthRepo.loadLocalUserData(),
      ).thenAnswer((_) async => Right(AuthFixture.tUser));

      // Act
      final result = await loadUser.loadFromLocal();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockAuthRepo.loadLocalUserData()).called(1);
    });
  });

  group('RefreshUserData UseCase Tests', () {
    late RefreshUserData refreshUserData;

    setUp(() {
      refreshUserData = RefreshUserData(mockAuthRepo);
    });

    test('should call repository refreshUserData', () async {
      // Arrange
      when(
        () => mockAuthRepo.refreshUserData(),
      ).thenAnswer((_) async => Right(AuthFixture.tUser));

      // Act
      final result = await refreshUserData();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockAuthRepo.refreshUserData()).called(1);
    });
  });

  group('GetUserTrip UseCase Tests', () {
    late GetUserTrip getUserTrip;

    setUp(() {
      getUserTrip = GetUserTrip(mockAuthRepo);
    });

    test('should call repository getUserTrip and return trip', () async {
      // Arrange
      when(
        () => mockAuthRepo.getUserTrip(AuthFixture.tUserId),
      ).thenAnswer((_) async => Right(AuthFixture.tTrip));

      // Act
      final result = await getUserTrip(AuthFixture.tUserId);

      // Assert
      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not return failure'), (trip) {
        expect(trip.id, 'trip-id-123');
        expect(trip.tripNumberId, 'trip-123');
      });
      verify(() => mockAuthRepo.getUserTrip(AuthFixture.tUserId)).called(1);
    });

    test('should call loadFromLocal for offline-first operation', () async {
      // Arrange
      when(
        () => mockAuthRepo.loadLocalUserTrip(AuthFixture.tUserId),
      ).thenAnswer((_) async => Right(AuthFixture.tTrip));

      // Act
      final result = await getUserTrip.loadFromLocal(AuthFixture.tUserId);

      // Assert
      expect(result.isRight(), true);
      verify(
        () => mockAuthRepo.loadLocalUserTrip(AuthFixture.tUserId),
      ).called(1);
    });
  });

  group('SyncUserData UseCase Tests', () {
    late SyncUserData syncUserData;

    setUp(() {
      syncUserData = SyncUserData(mockAuthRepo);
    });

    test('should call repository syncUserData', () async {
      // Arrange
      when(
        () => mockAuthRepo.syncUserData(AuthFixture.tUserId),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await syncUserData(AuthFixture.tUserId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockAuthRepo.syncUserData(AuthFixture.tUserId)).called(1);
    });
  });

  group('SyncUserTripData UseCase Tests', () {
    late SyncUserTripData syncUserTripData;

    setUp(() {
      syncUserTripData = SyncUserTripData(mockAuthRepo);
    });

    test('should call repository syncUserTripData', () async {
      // Arrange
      when(
        () => mockAuthRepo.syncUserTripData(AuthFixture.tUserId),
      ).thenAnswer((_) async => const Right(null));

      // Act
      final result = await syncUserTripData(AuthFixture.tUserId);

      // Assert
      expect(result.isRight(), true);
      verify(
        () => mockAuthRepo.syncUserTripData(AuthFixture.tUserId),
      ).called(1);
    });
  });

  // ============================================================================
  // REPOSITORY TESTS
  // ============================================================================

  group('AuthRepoImpl Tests', () {
    late AuthRepoImpl authRepoImpl;

    setUp(() {
      authRepoImpl = AuthRepoImpl(
        mockRemoteDataSrc,
        mockLocalDataSrc,
        mockOfflineSyncService,
      );
    });

    group('signIn', () {
      test('should return user when remote sign-in is successful', () async {
        // Arrange
        when(
          () => mockRemoteDataSrc.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => AuthFixture.tUser);
        when(() => mockLocalDataSrc.saveUser(any())).thenAnswer((_) async {});

        // Act
        final result = await authRepoImpl.signIn(
          email: AuthFixture.tEmail,
          password: AuthFixture.tPassword,
        );

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockRemoteDataSrc.signIn(
            email: AuthFixture.tEmail,
            password: AuthFixture.tPassword,
          ),
        ).called(1);
        verify(() => mockLocalDataSrc.saveUser(any())).called(1);
      });

      test(
        'should return cached user when remote fails but local has data',
        () async {
          // Arrange
          when(
            () => mockRemoteDataSrc.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(
            const ServerException(
              message: AuthFixture.tServerErrorMessage,
              statusCode: AuthFixture.tServerErrorCode,
            ),
          );
          when(() => mockLocalDataSrc.hasUser()).thenAnswer((_) async => true);
          when(
            () => mockLocalDataSrc.getLocalUser(),
          ).thenAnswer((_) async => AuthFixture.tUser);

          // Act
          final result = await authRepoImpl.signIn(
            email: AuthFixture.tEmail,
            password: 'wrong_password',
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should not return failure'),
            (user) => expect(user.email, AuthFixture.tEmail),
          );
        },
      );

      test('should return failure when both remote and local fail', () async {
        // Arrange
        when(
          () => mockRemoteDataSrc.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          const ServerException(
            message: AuthFixture.tServerErrorMessage,
            statusCode: AuthFixture.tServerErrorCode,
          ),
        );
        when(() => mockLocalDataSrc.hasUser()).thenAnswer((_) async => false);

        // Act
        final result = await authRepoImpl.signIn(
          email: AuthFixture.tEmail,
          password: 'wrong_password',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, AuthFixture.tServerErrorMessage);
        }, (_) => fail('Should not return user'));
      });
    });

    group('getUserById', () {
      test('should return user from local cache first', () async {
        // Arrange
        when(
          () => mockLocalDataSrc.forceReloadLocalUserById(AuthFixture.tUserId),
        ).thenAnswer((_) async => AuthFixture.tUser);

        // Act
        final result = await authRepoImpl.getUserById(AuthFixture.tUserId);

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockLocalDataSrc.forceReloadLocalUserById(AuthFixture.tUserId),
        ).called(1);
        // Remote should not be called if local succeeds
        verifyNever(() => mockRemoteDataSrc.getUserById(any()));
      });

      test('should fetch from remote when local cache fails', () async {
        // Arrange
        when(
          () => mockLocalDataSrc.forceReloadLocalUserById(AuthFixture.tUserId),
        ).thenThrow(const CacheException(message: 'User not found in cache'));
        when(
          () => mockRemoteDataSrc.getUserById(AuthFixture.tUserId),
        ).thenAnswer((_) async => AuthFixture.tUser);
        when(() => mockLocalDataSrc.saveUser(any())).thenAnswer((_) async {});

        // Act
        final result = await authRepoImpl.getUserById(AuthFixture.tUserId);

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockRemoteDataSrc.getUserById(AuthFixture.tUserId),
        ).called(1);
        verify(() => mockLocalDataSrc.saveUser(any())).called(1);
      });
    });

    group('loadLocalUserData', () {
      test('should return user from local storage', () async {
        // Arrange
        when(
          () => mockLocalDataSrc.getLocalUser(),
        ).thenAnswer((_) async => AuthFixture.tUser);

        // Act
        final result = await authRepoImpl.loadLocalUserData();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (user) => expect(user.id, AuthFixture.tUserId),
        );
      });

      test('should return CacheFailure when local data not found', () async {
        // Arrange
        when(() => mockLocalDataSrc.getLocalUser()).thenThrow(
          const CacheException(
            message: AuthFixture.tCacheErrorMessage,
            statusCode: 400,
          ),
        );

        // Act
        final result = await authRepoImpl.loadLocalUserData();

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, AuthFixture.tCacheErrorMessage);
        }, (_) => fail('Should not return user'));
      });
    });

    group('getUserTrip', () {
      test('should return trip from local cache first', () async {
        // Arrange
        when(
          () => mockLocalDataSrc.forceReloadLocalUserTrip(AuthFixture.tUserId),
        ).thenAnswer((_) async => AuthFixture.tTrip);

        // Act
        final result = await authRepoImpl.getUserTrip(AuthFixture.tUserId);

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockLocalDataSrc.forceReloadLocalUserTrip(AuthFixture.tUserId),
        ).called(1);
        verifyNever(() => mockRemoteDataSrc.getUserTrip(any()));
      });

      test('should fetch from remote when local cache fails', () async {
        // Arrange
        when(
          () => mockLocalDataSrc.forceReloadLocalUserTrip(AuthFixture.tUserId),
        ).thenThrow(const CacheException(message: 'Trip not found in cache'));
        when(
          () => mockRemoteDataSrc.getUserTrip(AuthFixture.tUserId),
        ).thenAnswer((_) async => AuthFixture.tTrip);

        // Act
        final result = await authRepoImpl.getUserTrip(AuthFixture.tUserId);

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockRemoteDataSrc.getUserTrip(AuthFixture.tUserId),
        ).called(1);
      });
    });

    group('syncUserData', () {
      test('should sync user data from remote and save locally', () async {
        // Arrange
        when(
          () => mockRemoteDataSrc.syncUserData(AuthFixture.tUserId),
        ).thenAnswer((_) async => AuthFixture.tUser);
        when(() => mockLocalDataSrc.saveUser(any())).thenAnswer((_) async {});

        // Act
        final result = await authRepoImpl.syncUserData(AuthFixture.tUserId);

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockRemoteDataSrc.syncUserData(AuthFixture.tUserId),
        ).called(1);
        verify(() => mockLocalDataSrc.saveUser(AuthFixture.tUser)).called(1);
      });
    });

    group('syncUserTripData', () {
      test('should sync trip data from remote and save locally', () async {
        // Arrange
        when(
          () => mockRemoteDataSrc.syncUserTripData(AuthFixture.tUserId),
        ).thenAnswer((_) async => AuthFixture.tTrip);
        when(
          () =>
              mockLocalDataSrc.saveUserTripByUserId(AuthFixture.tUserId, any()),
        ).thenAnswer((_) async {});

        // Act
        final result = await authRepoImpl.syncUserTripData(AuthFixture.tUserId);

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockRemoteDataSrc.syncUserTripData(AuthFixture.tUserId),
        ).called(1);
        verify(
          () =>
              mockLocalDataSrc.saveUserTripByUserId(AuthFixture.tUserId, any()),
        ).called(1);
      });
    });
  });

  // ============================================================================
  // BLoC TESTS
  // ============================================================================

  group('AuthBloc Tests', () {
    late AuthBloc authBloc;
    late SignIn signIn;
    late RefreshUserData refreshUserData;
    late GetUserById getUserById;
    late LoadUser loadUser;
    late GetUserTrip getUserTrip;
    late SyncUserData syncUserData;
    late SyncUserTripData syncUserTripData;

    setUp(() {
      signIn = SignIn(mockAuthRepo);
      refreshUserData = RefreshUserData(mockAuthRepo);
      getUserById = GetUserById(mockAuthRepo);
      loadUser = LoadUser(mockAuthRepo);
      getUserTrip = GetUserTrip(mockAuthRepo);
      syncUserData = SyncUserData(mockAuthRepo);
      syncUserTripData = SyncUserTripData(mockAuthRepo);

      authBloc = AuthBloc(
        signIn: signIn,
        refreshUserData: refreshUserData,
        getUserById: getUserById,
        loadUser: loadUser,
        getUserTrip: getUserTrip,
        syncUserData: syncUserData,
        syncUserTripData: syncUserTripData,
        connectivity: mockConnectivityProvider,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      // Assert
      expect(authBloc.state, const AuthInitial());
    });

    group('SignInEvent', () {
      test('emits [AuthLoading, SignedIn] when sign-in is successful', () {
        // Arrange
        when(
          () => mockAuthRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(AuthFixture.tUser));

        // Act & Assert
        expect(
          authBloc.stream,
          emitsInOrder([const AuthLoading(), isA<SignedIn>()]),
        );

        authBloc.add(
          SignInEvent(
            email: AuthFixture.tEmail,
            password: AuthFixture.tPassword,
          ),
        );
      });

      test('emits [AuthLoading, AuthError] when sign-in fails', () {
        // Arrange
        when(
          () => mockAuthRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => Left(
            ServerFailure(
              message: AuthFixture.tServerErrorMessage,
              statusCode: AuthFixture.tServerErrorCode,
            ),
          ),
        );

        // Act & Assert
        expect(
          authBloc.stream,
          emitsInOrder([const AuthLoading(), isA<AuthError>()]),
        );

        authBloc.add(
          SignInEvent(email: AuthFixture.tEmail, password: 'wrong_password'),
        );
      });
    });

    group('LoadUserByIdEvent', () {
      test(
        'emits [AuthLoading, UserByIdLoaded] when loading user by ID succeeds',
        () {
          // Arrange
          when(
            () => mockAuthRepo.getUserById(AuthFixture.tUserId),
          ).thenAnswer((_) async => Right(AuthFixture.tUser));

          // Act & Assert
          expect(
            authBloc.stream,
            emitsInOrder([const AuthLoading(), isA<UserByIdLoaded>()]),
          );

          authBloc.add(LoadUserByIdEvent(AuthFixture.tUserId));
        },
      );

      test('emits [AuthLoading, AuthError] when loading user by ID fails', () {
        // Arrange
        when(() => mockAuthRepo.getUserById(AuthFixture.tUserId)).thenAnswer(
          (_) async => Left(
            ServerFailure(
              message: 'User not found',
              statusCode: AuthFixture.tNotFoundErrorCode,
            ),
          ),
        );

        // Act & Assert
        expect(
          authBloc.stream,
          emitsInOrder([const AuthLoading(), isA<AuthError>()]),
        );

        authBloc.add(LoadUserByIdEvent(AuthFixture.tUserId));
      });
    });

    group('GetUserTripEvent', () {
      test(
        'emits [UserTripLoading, UserTripLoaded] when getting user trip succeeds',
        () {
          // Arrange
          when(
            () => mockAuthRepo.getUserTrip(AuthFixture.tUserId),
          ).thenAnswer((_) async => Right(AuthFixture.tTrip));

          // Act & Assert
          expect(
            authBloc.stream,
            emitsInOrder([const UserTripLoading(), isA<UserTripLoaded>()]),
          );

          authBloc.add(GetUserTripEvent(AuthFixture.tUserId));
        },
      );

      test(
        'emits [UserTripLoading, AuthError] when getting user trip fails',
        () {
          // Arrange
          when(() => mockAuthRepo.getUserTrip(AuthFixture.tUserId)).thenAnswer(
            (_) async => Left(
              ServerFailure(
                message: 'Trip not found',
                statusCode: AuthFixture.tNotFoundErrorCode,
              ),
            ),
          );

          // Act & Assert
          expect(
            authBloc.stream,
            emitsInOrder([const UserTripLoading(), isA<AuthError>()]),
          );

          authBloc.add(GetUserTripEvent(AuthFixture.tUserId));
        },
      );
    });

    group('SyncUserDataEvent', () {
      test('emits [UserDataSyncing, UserDataSynced] when sync succeeds', () {
        // Arrange
        when(
          () => mockAuthRepo.syncUserData(AuthFixture.tUserId),
        ).thenAnswer((_) async => const Right(null));

        // Act & Assert
        expect(
          authBloc.stream,
          emitsInOrder([const UserDataSyncing(), const UserDataSynced()]),
        );

        authBloc.add(SyncUserDataEvent(AuthFixture.tUserId));
      });

      test('emits [UserDataSyncing, AuthError] when sync fails', () {
        // Arrange
        when(() => mockAuthRepo.syncUserData(AuthFixture.tUserId)).thenAnswer(
          (_) async => Left(
            ServerFailure(
              message: 'Sync failed',
              statusCode: AuthFixture.tServerErrorCode,
            ),
          ),
        );

        // Act & Assert
        expect(
          authBloc.stream,
          emitsInOrder([const UserDataSyncing(), isA<AuthError>()]),
        );

        authBloc.add(SyncUserDataEvent(AuthFixture.tUserId));
      });
    });

    group('SyncUserTripDataEvent', () {
      test(
        'emits [TripDataSyncing, TripDataSynced] when trip sync succeeds',
        () {
          // Arrange
          when(
            () => mockAuthRepo.syncUserTripData(AuthFixture.tUserId),
          ).thenAnswer((_) async => const Right(null));

          // Act & Assert
          expect(
            authBloc.stream,
            emitsInOrder([const TripDataSyncing(), const TripDataSynced()]),
          );

          authBloc.add(SyncUserTripDataEvent(AuthFixture.tUserId));
        },
      );

      test('emits [TripDataSyncing, AuthError] when trip sync fails', () {
        // Arrange
        when(
          () => mockAuthRepo.syncUserTripData(AuthFixture.tUserId),
        ).thenAnswer(
          (_) async => Left(
            ServerFailure(
              message: 'Trip sync failed',
              statusCode: AuthFixture.tServerErrorCode,
            ),
          ),
        );

        // Act & Assert
        expect(
          authBloc.stream,
          emitsInOrder([const TripDataSyncing(), isA<AuthError>()]),
        );

        authBloc.add(SyncUserTripDataEvent(AuthFixture.tUserId));
      });
    });
  });

  // ============================================================================
  // CONNECTIVITY TESTS
  // ============================================================================

  group('Connectivity Provider Mock Tests', () {
    test('should mock connectivity check', () {
      // Arrange
      when(() => mockConnectivityProvider.isOnline).thenReturn(true);

      // Act
      final isOnline = mockConnectivityProvider.isOnline;

      // Assert
      expect(isOnline, true);
    });

    test('should mock no connectivity', () {
      // Arrange
      when(() => mockConnectivityProvider.isOnline).thenReturn(false);

      // Act
      final isOnline = mockConnectivityProvider.isOnline;

      // Assert
      expect(isOnline, false);
    });
  });
}
