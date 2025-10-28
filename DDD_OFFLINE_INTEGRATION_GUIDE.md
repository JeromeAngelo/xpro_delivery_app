# 🏗️ DDD + Offline-First Integration Guide

## Overview

This guide shows how to integrate the **OfflineSyncService** into your Domain-Driven Design (DDD) architecture while maintaining clean architecture principles.

---

## 📐 DDD Architecture Layers

Your app follows Clean Architecture with DDD:

```
lib/core/common/app/features/users/auth/
├── data/
│   ├── datasources/
│   │   ├── local_data_source/      ← ObjectBox operations
│   │   └── remote_data_source/     ← PocketBase operations
│   ├── models/                      ← Data Transfer Objects
│   └── repositories/                ← Repository implementations
├── domain/
│   ├── entities/                    ← Business objects
│   ├── repositories/                ← Repository interfaces
│   └── usecases/                    ← Business logic
└── presentation/
    ├── bloc/                        ← State management
    └── views/                       ← UI components
```

---

## 🔄 Integration Strategy

### **Principle: Offline-First at Repository Layer**

1. **Data Sources** → Handle local/remote operations
2. **Repository** → Orchestrate offline-first logic + queue sync
3. **Use Cases** → Remain clean, unaware of offline details
4. **BLoC** → Handle state, trigger sync when needed

---

## 💡 Example: Auth Module (Complete Implementation)

### **Step 1: Update Repository Interface**

`lib/core/common/app/features/users/auth/domain/repositories/auth_repository.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entities/user.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entities/trip.dart';

abstract class AuthRepository {
  // Core operations (work offline)
  Future<Either<Failure, LocalUser>> signIn({
    required String email,
    required String password,
  });
  
  Future<Either<Failure, LocalUser>> loadUser();
  Future<Either<Failure, LocalUser>> getUserById(String userId);
  Future<Either<Failure, Trip>> getUserTrip(String userId);
  
  // Sync operations (require internet)
  Future<Either<Failure, LocalUser>> syncUserData(String userId);
  Future<Either<Failure, Trip>> syncUserTripData(String userId);
  Future<Either<Failure, Unit>> syncPendingOperations();
}
```

### **Step 2: Implement Offline-First Repository**

`lib/core/common/app/features/users/auth/data/repositories/auth_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/services/offline_sync_service.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_data_source/auth_local_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/auth_remote_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repositories/auth_repository.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entities/user.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entities/trip.dart';
import 'package:uuid/uuid.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSrc _remoteDataSource;
  final AuthLocalDataSrc _localDataSource;
  final OfflineSyncService _offlineSync;

  AuthRepositoryImpl({
    required AuthRemoteDataSrc remoteDataSource,
    required AuthLocalDataSrc localDataSource,
    required OfflineSyncService offlineSync,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _offlineSync = offlineSync;

  @override
  Future<Either<Failure, LocalUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Repository: Signing in user: $email');
      
      // 1. Attempt remote login (requires internet)
      final remoteUser = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );
      
      // 2. Save to local database (ObjectBox)
      await _localDataSource.cacheUser(remoteUser);
      debugPrint('✅ Repository: User cached locally');
      
      // 3. Convert model to entity
      final userEntity = remoteUser.toEntity();
      
      return Right(userEntity);
      
    } on ServerException catch (e) {
      debugPrint('❌ Repository: Remote sign in failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
      
    } on CacheException catch (e) {
      debugPrint('❌ Repository: Cache failed: ${e.message}');
      return Left(CacheFailure(message: e.message));
      
    } catch (e) {
      debugPrint('❌ Repository: Unexpected error: $e');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  Future<Either<Failure, LocalUser>> loadUser() async {
    try {
      debugPrint('📱 Repository: Loading user (offline-first)');
      
      // 1. Try local first (works offline!)
      try {
        final localUser = await _localDataSource.getLastUser();
        debugPrint('✅ Repository: User loaded from local');
        return Right(localUser.toEntity());
      } catch (e) {
        debugPrint('⚠️ Repository: No local user, trying remote...');
      }
      
      // 2. Fall back to remote if local fails
      final remoteUser = await _remoteDataSource.loadUser();
      await _localDataSource.cacheUser(remoteUser);
      
      return Right(remoteUser.toEntity());
      
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  Future<Either<Failure, LocalUser>> getUserById(String userId) async {
    try {
      debugPrint('🔍 Repository: Getting user by ID (offline-first)');
      
      // 1. Try local first
      try {
        final localUser = await _localDataSource.getUserById(userId);
        debugPrint('✅ Repository: User found in local cache');
        return Right(localUser.toEntity());
      } catch (e) {
        debugPrint('⚠️ Repository: Not in cache, fetching from remote...');
      }
      
      // 2. Fetch from remote
      final remoteUser = await _remoteDataSource.getUserById(userId);
      
      // 3. Cache for next time
      await _localDataSource.cacheUser(remoteUser);
      
      return Right(remoteUser.toEntity());
      
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  Future<Either<Failure, Trip>> getUserTrip(String userId) async {
    try {
      debugPrint('🎫 Repository: Getting user trip (offline-first)');
      
      // 1. Try local first
      try {
        final localTrip = await _localDataSource.getCachedTrip(userId);
        debugPrint('✅ Repository: Trip found in local cache');
        return Right(localTrip.toEntity());
      } catch (e) {
        debugPrint('⚠️ Repository: No cached trip, fetching from remote...');
      }
      
      // 2. Fetch from remote
      final remoteTrip = await _remoteDataSource.getUserTrip(userId);
      
      // 3. Cache for offline access
      await _localDataSource.cacheTrip(remoteTrip);
      
      return Right(remoteTrip.toEntity());
      
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  Future<Either<Failure, LocalUser>> syncUserData(String userId) async {
    try {
      debugPrint('🔄 Repository: Syncing user data from remote');
      
      // Fetch fresh data from remote
      final remoteUser = await _remoteDataSource.syncUserData(userId);
      
      // Update local cache
      await _localDataSource.cacheUser(remoteUser);
      
      return Right(remoteUser.toEntity());
      
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  Future<Either<Failure, Trip>> syncUserTripData(String userId) async {
    try {
      debugPrint('🔄 Repository: Syncing trip data from remote');
      
      // Fetch fresh trip data
      final remoteTrip = await _remoteDataSource.syncUserTripData(userId);
      
      // Update local cache
      await _localDataSource.cacheTrip(remoteTrip);
      
      return Right(remoteTrip.toEntity());
      
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  Future<Either<Failure, Unit>> syncPendingOperations() async {
    try {
      debugPrint('🔄 Repository: Syncing pending operations');
      
      final result = await _offlineSync.syncAll();
      
      if (result.success) {
        debugPrint('✅ Repository: Sync completed successfully');
        return const Right(unit);
      } else {
        return Left(ServerFailure(
          message: result.message,
          statusCode: '500',
        ));
      }
      
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }
}
```

### **Step 3: Update Use Cases (Remain Clean!)**

Use cases don't need to know about offline details. They just call the repository:

`lib/core/common/app/features/users/auth/domain/usecases/sign_in.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/usecases/usecases.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entities/user.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repositories/auth_repository.dart';

class SignIn extends UseCaseWithParams<LocalUser, SignInParams> {
  final AuthRepository _repository;

  SignIn(this._repository);

  @override
  Future<Either<Failure, LocalUser>> call(SignInParams params) {
    // Clean! No offline logic here
    return _repository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInParams {
  final String email;
  final String password;

  SignInParams({required this.email, required this.password});
}
```

`lib/core/common/app/features/users/auth/domain/usecases/get_user.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/usecases/usecases.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entities/user.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repositories/auth_repository.dart';

class GetUser extends UseCaseWithParams<LocalUser, String> {
  final AuthRepository _repository;

  GetUser(this._repository);

  @override
  Future<Either<Failure, LocalUser>> call(String userId) {
    // Works offline! Repository handles it
    return _repository.getUserById(userId);
  }
}
```

`lib/core/common/app/features/users/auth/domain/usecases/sync_user_data.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/usecases/usecases.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entities/user.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repositories/auth_repository.dart';

class SyncUserData extends UseCaseWithParams<LocalUser, String> {
  final AuthRepository _repository;

  SyncUserData(this._repository);

  @override
  Future<Either<Failure, LocalUser>> call(String userId) {
    // Explicit sync from remote
    return _repository.syncUserData(userId);
  }
}
```

---

## 📝 Example: Update User Profile (Offline-Capable)

### **Use Case**

`lib/core/common/app/features/users/auth/domain/usecases/update_user_profile.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/usecases/usecases.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entities/user.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repositories/auth_repository.dart';

class UpdateUserProfile extends UseCaseWithParams<LocalUser, UpdateUserParams> {
  final AuthRepository _repository;

  UpdateUserProfile(this._repository);

  @override
  Future<Either<Failure, LocalUser>> call(UpdateUserParams params) {
    return _repository.updateUserProfile(params);
  }
}

class UpdateUserParams {
  final String userId;
  final String? name;
  final String? email;
  final String? phone;

  UpdateUserParams({
    required this.userId,
    this.name,
    this.email,
    this.phone,
  });
}
```

### **Repository Implementation**

```dart
@override
Future<Either<Failure, LocalUser>> updateUserProfile(
  UpdateUserParams params,
) async {
  try {
    debugPrint('📝 Repository: Updating user profile (offline-capable)');
    
    // 1. Update local database FIRST (works offline!)
    final localUser = await _localDataSource.getUserById(params.userId);
    
    // Update fields
    if (params.name != null) localUser.name = params.name!;
    if (params.email != null) localUser.email = params.email!;
    if (params.phone != null) localUser.phone = params.phone!;
    
    // Save to ObjectBox
    await _localDataSource.updateUser(localUser);
    debugPrint('✅ Repository: User updated locally');
    
    // 2. Queue operation for sync
    await _offlineSync.queueOperation(
      OfflineOperation(
        id: const Uuid().v4(),
        type: OperationType.update,
        collection: 'users',
        recordId: params.userId,
        data: {
          if (params.name != null) 'name': params.name,
          if (params.email != null) 'email': params.email,
          if (params.phone != null) 'phone': params.phone,
          'updated_at': DateTime.now().toIso8601String(),
        },
      ),
    );
    debugPrint('✅ Repository: Update queued for sync');
    
    // 3. Return updated entity
    return Right(localUser.toEntity());
    
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message));
  } catch (e) {
    return Left(ServerFailure(message: e.toString(), statusCode: '500'));
  }
}
```

---

## 🎯 Complete Example: Delivery Status Update

### **1. Repository Method**

```dart
@override
Future<Either<Failure, Delivery>> updateDeliveryStatus({
  required String deliveryId,
  required String status,
  String? notes,
  List<String>? photoUrls,
}) async {
  try {
    debugPrint('📦 Repository: Updating delivery status (offline)');
    
    // 1. Get from local cache
    final localDelivery = await _localDataSource.getDeliveryById(deliveryId);
    
    // 2. Update fields
    localDelivery.status = status;
    localDelivery.notes = notes;
    localDelivery.photoUrls = photoUrls;
    localDelivery.updatedAt = DateTime.now();
    
    // 3. Save to ObjectBox
    await _localDataSource.updateDelivery(localDelivery);
    
    // 4. Queue for sync to PocketBase
    await _offlineSync.queueOperation(
      OfflineOperation(
        id: const Uuid().v4(),
        type: OperationType.update,
        collection: 'delivery_data',
        recordId: deliveryId,
        data: {
          'status': status,
          if (notes != null) 'notes': notes,
          if (photoUrls != null) 'photo_urls': photoUrls,
          'updated_at': DateTime.now().toIso8601String(),
        },
      ),
    );
    
    // 5. Also queue history entry
    await _createDeliveryHistory(deliveryId, status);
    
    debugPrint('✅ Repository: Delivery updated offline');
    return Right(localDelivery.toEntity());
    
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message));
  } catch (e) {
    return Left(ServerFailure(message: e.toString(), statusCode: '500'));
  }
}

Future<void> _createDeliveryHistory(String deliveryId, String status) async {
  final historyId = const Uuid().v4();
  
  // Save locally
  await _localDataSource.saveDeliveryHistory(historyId, deliveryId, status);
  
  // Queue for sync
  await _offlineSync.queueOperation(
    OfflineOperation(
      id: const Uuid().v4(),
      type: OperationType.create,
      collection: 'delivery_history',
      recordId: historyId,
      data: {
        'id': historyId,
        'delivery': deliveryId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ),
  );
}
```

### **2. Use Case**

```dart
class UpdateDeliveryStatus extends UseCaseWithParams<Delivery, UpdateDeliveryParams> {
  final DeliveryRepository _repository;

  UpdateDeliveryStatus(this._repository);

  @override
  Future<Either<Failure, Delivery>> call(UpdateDeliveryParams params) {
    return _repository.updateDeliveryStatus(
      deliveryId: params.deliveryId,
      status: params.status,
      notes: params.notes,
      photoUrls: params.photoUrls,
    );
  }
}
```

### **3. BLoC**

```dart
class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final UpdateDeliveryStatus _updateStatus;
  final OfflineSyncService _offlineSync;

  DeliveryBloc({
    required UpdateDeliveryStatus updateStatus,
    required OfflineSyncService offlineSync,
  })  : _updateStatus = updateStatus,
        _offlineSync = offlineSync,
        super(DeliveryInitial()) {
    on<UpdateDeliveryStatusEvent>(_onUpdateStatus);
  }

  Future<void> _onUpdateStatus(
    UpdateDeliveryStatusEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(DeliveryUpdating());
    
    final result = await _updateStatus(UpdateDeliveryParams(
      deliveryId: event.deliveryId,
      status: event.status,
      notes: event.notes,
      photoUrls: event.photoUrls,
    ));
    
    result.fold(
      (failure) => emit(DeliveryError(failure.message)),
      (delivery) {
        emit(DeliveryUpdated(delivery));
        
        // Show sync status
        final syncStatus = _offlineSync.getCurrentStatus();
        if (!syncStatus.isOnline) {
          emit(DeliveryOfflineQueued(
            delivery: delivery,
            queuedOperations: syncStatus.queuedOperations,
          ));
        }
      },
    );
  }
}
```

---

## ✅ Best Practices

### **1. Always Update Local First**
```dart
// ✅ CORRECT
await _localDataSource.update(data);
await _offlineSync.queueOperation(...);

// ❌ WRONG
await _offlineSync.queueOperation(...);
// Missing local update!
```

### **2. Repository Handles Offline Logic**
```dart
// ✅ Repository knows about offline
class AuthRepositoryImpl {
  final OfflineSyncService _offlineSync;
  // ...
}

// ❌ Use case doesn't know
class SignIn {
  // NO reference to OfflineSyncService
}
```

### **3. Use Entities in Domain Layer**
```dart
// ✅ Domain uses entities
Future<Either<Failure, LocalUser>> call(String userId);

// ❌ Don't use models in domain
Future<Either<Failure, LocalUsersModel>> call(String userId);
```

### **4. Queue After Local Save**
```dart
try {
  // 1. Save locally
  await _local.save(data);
  
  // 2. Queue for sync
  await _offlineSync.queueOperation(...);
  
  // 3. Return success
  return Right(entity);
} catch (e) {
  return Left(Failure(...));
}
```

---

## 📋 Checklist for Adding Offline to a Feature

- [ ] **Local Data Source** → Add ObjectBox save/update/get methods
- [ ] **Repository** → Implement offline-first logic
- [ ] **Repository** → Queue operations with OfflineSyncService
- [ ] **Use Cases** → Keep clean, call repository methods
- [ ] **BLoC** → Handle offline states
- [ ] **UI** → Show sync status indicator
- [ ] **Test** → Turn off internet, verify it works!

---

## 🧪 Testing Offline Functionality

```dart
void main() {
  group('Auth Repository Offline Tests', () {
    late AuthRepositoryImpl repository;
    late MockRemoteDataSource mockRemote;
    late MockLocalDataSource mockLocal;
    late MockOfflineSyncService mockSync;

    setUp(() {
      mockRemote = MockRemoteDataSource();
      mockLocal = MockLocalDataSource();
      mockSync = MockOfflineSyncService();
      
      repository = AuthRepositoryImpl(
        remoteDataSource: mockRemote,
        localDataSource: mockLocal,
        offlineSync: mockSync,
      );
    });

    test('should load user from local when offline', () async {
      // Arrange
      when(() => mockLocal.getLastUser())
          .thenAnswer((_) async => tUserModel);
      
      // Act
      final result = await repository.loadUser();
      
      // Assert
      expect(result, Right(tUser));
      verify(() => mockLocal.getLastUser()).called(1);
      verifyNever(() => mockRemote.loadUser());
    });

    test('should queue operation when updating offline', () async {
      // Arrange
      when(() => mockLocal.getUserById(any()))
          .thenAnswer((_) async => tUserModel);
      when(() => mockLocal.updateUser(any()))
          .thenAnswer((_) async => unit);
      when(() => mockSync.queueOperation(any()))
          .thenAnswer((_) async => unit);
      
      // Act
      final result = await repository.updateUserProfile(tParams);
      
      // Assert
      expect(result.isRight(), true);
      verify(() => mockLocal.updateUser(any())).called(1);
      verify(() => mockSync.queueOperation(any())).called(1);
    });
  });
}
```

---

## 🎓 Summary

**Key Principles:**

1. ✅ **Repository** = Offline-first orchestration
2. ✅ **Local First** = Always update ObjectBox before queuing
3. ✅ **Queue Second** = Use OfflineSyncService to queue operations
4. ✅ **Sync Third** = Automatic sync when online
5. ✅ **Clean Use Cases** = No offline logic in domain layer
6. ✅ **Smart BLoC** = Handle offline states in presentation

**Result:** Your app works 100% offline while maintaining clean DDD architecture! 🎉
