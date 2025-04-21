import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/entity/completed_customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/repo/completed_customer_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetCompletedCustomerById extends UsecaseWithParams<CompletedCustomerEntity, String> {
  const GetCompletedCustomerById(this._repo);

  final CompletedCustomerRepo _repo;

  @override
  ResultFuture<CompletedCustomerEntity> call(String params) =>
      _repo.getCompletedCustomerById(params);
      
  ResultFuture<CompletedCustomerEntity> loadFromLocal(String customerId) =>
      _repo.loadLocalCompletedCustomerById(customerId);
}

