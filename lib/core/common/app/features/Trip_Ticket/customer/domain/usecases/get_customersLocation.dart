import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/repo/customer_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetCustomersLocation extends UsecaseWithParams<CustomerEntity, String> {
  const GetCustomersLocation(this._repo);
  final CustomerRepo _repo;

  @override
  ResultFuture<CustomerEntity> call(String params) => _repo.getCustomerLocation(params);
  ResultFuture<CustomerEntity> loadFromLocal(String params) => _repo.loadLocalCustomerLocation(params);
}
