import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/entity/undeliverable_customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/repo/undeliverable_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CreateUndeliverableCustomerParams {
  final UndeliverableCustomerEntity undeliverableCustomer;
  final String customerId;

  const CreateUndeliverableCustomerParams({
    required this.undeliverableCustomer,
    required this.customerId,
  });
}

class CreateUndeliverableCustomer extends UsecaseWithParams<UndeliverableCustomerEntity, CreateUndeliverableCustomerParams> {
  const CreateUndeliverableCustomer(this._repo);

  final UndeliverableRepo _repo;

  @override
  ResultFuture<UndeliverableCustomerEntity> call(CreateUndeliverableCustomerParams params) async {
    return _repo.createUndeliverableCustomer(params.undeliverableCustomer, params.customerId);
  }
}
