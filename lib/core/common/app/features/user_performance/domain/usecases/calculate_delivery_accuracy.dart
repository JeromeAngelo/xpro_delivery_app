import 'package:x_pro_delivery_app/core/common/app/features/user_performance/domain/repo/user_performance_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CalculateDeliveryAccuracy extends UsecaseWithParams<double, String> {
  const CalculateDeliveryAccuracy(this._repo);

  final UserPerformanceRepo _repo;

  @override
  ResultFuture<double> call(String params) async {
    return _repo.calculateDeliveryAccuracy(params);
  }
}
