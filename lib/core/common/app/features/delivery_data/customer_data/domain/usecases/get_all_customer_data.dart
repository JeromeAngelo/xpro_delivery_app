

import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/entity/customer_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/repo/customer_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetAllCustomerData extends UsecaseWithoutParams<List<CustomerDataEntity>> {
  final CustomerDataRepo _repo;

  const GetAllCustomerData(this._repo);

  @override
  ResultFuture<List<CustomerDataEntity>> call() async {
    return _repo.getAllCustomerData();
  }
}
