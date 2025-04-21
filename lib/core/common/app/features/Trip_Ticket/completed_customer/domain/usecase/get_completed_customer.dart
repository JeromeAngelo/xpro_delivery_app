import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/entity/completed_customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/completed_customer/domain/repo/completed_customer_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetCompletedCustomer extends UsecaseWithParams<List<CompletedCustomerEntity>, String> {
  final CompletedCustomerRepo _repo;
  const GetCompletedCustomer(this._repo);

  @override
  ResultFuture<List<CompletedCustomerEntity>> call(String params) => 
      _repo.getCompletedCustomers(params);
      
  ResultFuture<List<CompletedCustomerEntity>> loadFromLocal(String tripId) =>
      _repo.loadLocalCompletedCustomers(tripId);
}




 



