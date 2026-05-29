import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/auth_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/sign_in_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/refresh_user_data_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/load_user_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/get_user_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/get_user_trip_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/sync_user_data_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/remote_impl/sync_user_trip_data_impl.dart';

abstract class AuthRemoteDataSrc {
  const AuthRemoteDataSrc();

  Future<LocalUsersModel> signIn({
    required String email,
    required String password,
  });
  Future<LocalUsersModel> refreshUserData();
  Future<LocalUsersModel> loadUser();
  Future<LocalUsersModel> getUserById(String userId);
  Future<TripModel> getUserTrip(String userId);

  // New sync methods
  Future<LocalUsersModel> syncUserData(String userId);
  Future<TripModel> syncUserTripData(String userId);
}

class AuthRemoteDataSrcImpl extends AuthRemoteBase
    with
        SignInImpl,
        RefreshUserDataImpl,
        LoadUserImpl,
        GetUserByIdImpl,
        GetUserTripImpl,
        SyncUserDataImpl,
        SyncUserTripDataImpl
    implements AuthRemoteDataSrc {
  const AuthRemoteDataSrcImpl({required super.pocketBaseClient});
}
