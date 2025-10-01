import 'package:x_pro_delivery_app/core/common/app/features/users/user_performance/domain/entity/user_performance_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class UserPerformanceRepo {
  const UserPerformanceRepo();

  // Load user performance by user ID from remote
  ResultFuture<UserPerformanceEntity> loadUserPerformanceByUserId(String userId);

  // Load user performance by user ID from local storage
  ResultFuture<UserPerformanceEntity> loadLocalUserPerformanceByUserId(String userId);

  // Calculate delivery accuracy for a user
  ResultFuture<double> calculateDeliveryAccuracy(String userId);
}
