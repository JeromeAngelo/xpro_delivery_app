import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/entity/undeliverable_customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/repo/undeliverable_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class SaveUndeliverableCustomerParams {
  final UndeliverableCustomerEntity undeliverableCustomer;
  final String customerId;

  const SaveUndeliverableCustomerParams({
    required this.undeliverableCustomer,
    required this.customerId,
  });
}

class SaveUndeliverableCustomer extends UsecaseWithParams<void, SaveUndeliverableCustomerParams> {
  const SaveUndeliverableCustomer(this._repo);

  final UndeliverableRepo _repo;

  @override
  ResultFuture<void> call(SaveUndeliverableCustomerParams params) {
    return _repo.saveUndeliverableCustomer(params.undeliverableCustomer, params.customerId);
  }
}

