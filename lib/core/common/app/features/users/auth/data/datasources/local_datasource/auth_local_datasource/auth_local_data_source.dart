import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/auth_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/get_local_user_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/load_local_user_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/save_user_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/clear_user_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/has_user_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/load_local_user_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/cache_user_data_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/cache_user_trip_data_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/save_user_trip_by_user_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/force_reload_local_user_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/local_impl/force_reload_local_user_by_id_impl.dart';

abstract class AuthLocalDataSrc {
  Future<LocalUsersModel> getLocalUser();
  Future<LocalUsersModel> loadLocalUserById(String userId);
  Future<void> saveUser(LocalUsersModel user);
  Future<void> clearUser();
  Future<bool> hasUser();
  Future<TripModel> loadLocalUserTrip(String userId);
  // New sync methods
  Future<void> cacheUserData(LocalUsersModel user);
  Future<void> cacheUserTripData(TripModel trip);
  Future<void> saveUserTripByUserId(String userId, TripModel trip);
  Future<TripModel> forceReloadLocalUserTrip(String userId);
  Future<LocalUsersModel> forceReloadLocalUserById(String userId);
}

class AuthLocalDataSrcImpl extends AuthLocalBase
    with
        GetLocalUserImpl,
        LoadLocalUserByIdImpl,
        SaveUserImpl,
        ClearUserImpl,
        HasUserImpl,
        LoadLocalUserTripImpl,
        CacheUserDataImpl,
        CacheUserTripDataImpl,
        SaveUserTripByUserIdImpl,
        ForceReloadLocalUserTripImpl,
        ForceReloadLocalUserByIdImpl
    implements AuthLocalDataSrc {
  AuthLocalDataSrcImpl({required super.objectBoxStore, required super.prefs});
}
