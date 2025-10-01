// sync_user_trip_data.dart
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repo/auth_repo.dart';

class SyncUserTripData extends UsecaseWithParams<void, String> {
  const SyncUserTripData(this._repo);
  final AuthRepo _repo;

  @override
  ResultFuture<void> call(String params) => _repo.syncUserTripData(params);
}