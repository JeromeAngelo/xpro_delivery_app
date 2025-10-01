import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/domain/entity/user_performance_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/domain/repo/user_performance_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadUserPerformanceByUserId extends UsecaseWithParams<UserPerformanceEntity, String> {
  const LoadUserPerformanceByUserId(this._repo);

  final UserPerformanceRepo _repo;

  @override
  ResultFuture<UserPerformanceEntity> call(String params) async {
    return _repo.loadUserPerformanceByUserId(params);
  }

  // Method to load from local storage
  ResultFuture<UserPerformanceEntity> loadFromLocal(String userId) async {
    return _repo.loadLocalUserPerformanceByUserId(userId);
  }
}
