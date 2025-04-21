import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/repo/customer_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CalculateCustomerTotalTime extends UsecaseWithParams<String, String> {
  const CalculateCustomerTotalTime(this._repo);

  final CustomerRepo _repo;

  @override
  ResultFuture<String> call(String params) => _repo.calculateCustomerTotalTime(params);
}
