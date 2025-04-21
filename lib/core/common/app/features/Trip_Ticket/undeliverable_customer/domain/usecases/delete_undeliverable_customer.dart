import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/repo/undeliverable_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class DeleteUndeliverableCustomer extends UsecaseWithParams<void, String> {
  const DeleteUndeliverableCustomer(this._repo);

  final UndeliverableRepo _repo;

  @override
  ResultFuture<void> call(String params) async {
    return _repo.deleteUndeliverableCustomer(params);
  }
}
