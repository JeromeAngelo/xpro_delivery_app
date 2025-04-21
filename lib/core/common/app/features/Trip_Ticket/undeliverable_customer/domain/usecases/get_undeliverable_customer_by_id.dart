import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/entity/undeliverable_customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/repo/undeliverable_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetUndeliverableCustomerById extends UsecaseWithParams<UndeliverableCustomerEntity, String> {
  const GetUndeliverableCustomerById(this._repo);

  final UndeliverableRepo _repo;

  @override
  ResultFuture<UndeliverableCustomerEntity> call(String params) {
    return _repo.getUndeliverableCustomerById(params);
  }
}
