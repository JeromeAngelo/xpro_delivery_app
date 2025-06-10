

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/entity/customer_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/repo/customer_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetCustomersByDeliveryId extends UsecaseWithParams<List<CustomerDataEntity>, String> {
  final CustomerDataRepo _repo;

  const GetCustomersByDeliveryId(this._repo);

  @override
  ResultFuture<List<CustomerDataEntity>> call(String params) async {
    return _repo.getCustomersByDeliveryId(params);
  }
}
