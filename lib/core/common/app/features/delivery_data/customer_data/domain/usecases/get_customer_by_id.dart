import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/entity/customer_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/repo/customer_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';


class GetCustomerDataById extends UsecaseWithParams<CustomerDataEntity, String> {
  final CustomerDataRepo _repo;

  const GetCustomerDataById(this._repo);

  @override
  ResultFuture<CustomerDataEntity> call(String params) async {
    return _repo.getCustomerDataById(params);
  }
}
