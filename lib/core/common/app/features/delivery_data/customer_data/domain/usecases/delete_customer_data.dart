

import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/repo/customer_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class DeleteCustomerData extends UsecaseWithParams<bool, String> {
  final CustomerDataRepo _repo;

  const DeleteCustomerData(this._repo);

  @override
  ResultFuture<bool> call(String params) async {
    return _repo.deleteCustomerData(params);
  }
}
