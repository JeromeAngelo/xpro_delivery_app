import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/repo/customer_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';


class DeleteAllCustomerData extends UsecaseWithParams<bool, List<String>> {
  final CustomerDataRepo _repo;

  const DeleteAllCustomerData(this._repo);

  @override
  ResultFuture<bool> call(List<String> params) async {
    return _repo.deleteAllCustomerData(params);
  }
}
