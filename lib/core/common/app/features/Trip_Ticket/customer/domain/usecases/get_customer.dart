import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/repo/customer_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetCustomer extends UsecaseWithParams<List<CustomerEntity>, String> {
  const GetCustomer(this._repo);
  final CustomerRepo _repo;

  @override
  ResultFuture<List<CustomerEntity>> call(String params) => _repo.getCustomers(params);
  ResultFuture<List<CustomerEntity>> loadFromLocal(String tripId) => _repo.loadLocalCustomers(tripId);
}

