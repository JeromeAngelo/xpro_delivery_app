import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/entity/trip_entity.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/auth_local_data_source.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/auth_remote_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entity/users_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repo/auth_repo.dart';
class AuthRepoImpl implements AuthRepo {
  final AuthRemoteDataSrc _remoteDataSrc;
  final AuthLocalDataSrc _localDataSrc;

  const AuthRepoImpl(this._remoteDataSrc, this._localDataSrc);

 @override
ResultFuture<LocalUser> signIn({
  required String email,
  required String password,
}) async {
  try {
    debugPrint('🔄 Starting sign-in process');
    
    // Get user from remote
    final remoteUser = await _remoteDataSrc.signIn(
      email: email,
      password: password,
    );
    
    debugPrint('✅ Remote authentication successful');
    debugPrint('   👤 User: ${remoteUser.name}');
    debugPrint('   📧 Email: ${remoteUser.email}');
    
    // Save to local storage
    await _localDataSrc.saveUser(remoteUser);
    debugPrint('💾 User data cached locally');
    
    return Right(remoteUser);
  } on ServerException catch (e) {
    debugPrint('⚠️ Remote authentication failed, checking local cache');
    if (await _localDataSrc.hasUser()) {
      final localUser = await _localDataSrc.getLocalUser();
      debugPrint('📱 Using cached user data');
      return Right(localUser);
    }
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}


  @override
  ResultFuture<LocalUser> refreshUserData() async {
    try {
      final result = await _remoteDataSrc.refreshUserData();
      await _localDataSrc.saveUser(result);
      return Right(result);
    } on ServerException catch (e) {
      if (await _localDataSrc.hasUser()) {
        return Right(await _localDataSrc.getLocalUser());
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  @override
ResultFuture<LocalUser> getUserById(String userId) async {
  try {
    debugPrint('🔍 Getting user by ID: $userId');
    final result = await _remoteDataSrc.getUserById(userId);
    await _localDataSrc.saveUser(result);
    return Right(result);
  } on ServerException catch (e) {
    debugPrint('⚠️ Remote fetch failed, attempting local cache retrieval');
    try {
      final localResult = await _localDataSrc.loadLocalUserById(userId);
      return Right(localResult);
    } catch (_) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

@override
ResultFuture<LocalUser> loadLocalUserById(String userId) async {
  try {
    debugPrint('📱 Loading local user data by ID: $userId');
    final result = await _localDataSrc.loadLocalUserById(userId);
    debugPrint('✅ User found in local storage');
    return Right(result);
  } on CacheException catch (_) {
    debugPrint('⚠️ Local data not found, attempting remote fetch');
    try {
      final remoteUser = await _remoteDataSrc.getUserById(userId);
      await _localDataSrc.saveUser(remoteUser);
      debugPrint('✅ Remote data fetched and cached locally');
      return Right(remoteUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}


@override
ResultFuture<LocalUser> loadLocalUserData() async {
  try {
    debugPrint('📱 Loading local user data');
    final result = await _localDataSrc.getLocalUser();
    return Right(result);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<LocalUser> loadUser() async {
  try {
    debugPrint('🌐 Loading remote user data');
    final result = await _remoteDataSrc.loadUser();
    await _localDataSrc.saveUser(result);
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}
@override
ResultFuture<TripEntity> getUserTrip(String userId) async {
  try {
    debugPrint('🔍 Getting user trip by ID: $userId');
    final result = await _remoteDataSrc.getUserTrip(userId);
    return Right(result);
  } on ServerException catch (e) {
    debugPrint('⚠️ Remote fetch failed, attempting local cache retrieval');
    try {
      final localResult = await _localDataSrc.loadLocalUserTrip(userId);
      return Right(localResult);
    } catch (_) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

@override
ResultFuture<TripEntity> loadLocalUserTrip(String userId) async {
  try {
    debugPrint('📱 Loading local user trip data by ID: $userId');
    final result = await _localDataSrc.loadLocalUserTrip(userId);
    return Right(result);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

 @override
ResultFuture<void> syncUserData(String userId) async {
  try {
    debugPrint('🔄 Starting user data sync');
    final remoteUser = await _remoteDataSrc.syncUserData(userId);
    await _localDataSrc.cacheUserData(remoteUser);
    debugPrint('✅ User data synced and cached successfully');
    return const Right(null);
  } on ServerException catch (e) {
    debugPrint('❌ Remote sync failed: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } on CacheException catch (e) {
    debugPrint('❌ Local cache failed: ${e.message}');
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<void> syncUserTripData(String userId) async {
  try {
    debugPrint('🔄 Starting trip data sync');
    final remoteTrip = await _remoteDataSrc.syncUserTripData(userId);
    await _localDataSrc.cacheUserTripData(remoteTrip);
    debugPrint('✅ Trip data synced and cached successfully');
    return const Right(null);
  } on ServerException catch (e) {
    debugPrint('❌ Remote sync failed: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  } on CacheException catch (e) {
    debugPrint('❌ Local cache failed: ${e.message}');
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

  @override
  ResultFuture<void> signOut() {
    // TODO: implement signOut
    throw UnimplementedError();
  }



}

