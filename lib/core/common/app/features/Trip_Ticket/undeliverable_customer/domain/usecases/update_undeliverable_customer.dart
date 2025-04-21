import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/entity/undeliverable_customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/domain/repo/undeliverable_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class UpdateUndeliverableCustomerParams {
  final UndeliverableCustomerEntity undeliverableCustomer;
  final String tripId;

  const UpdateUndeliverableCustomerParams({
    required this.undeliverableCustomer,
    required this.tripId,
  });
}

class UpdateUndeliverableCustomer extends UsecaseWithParams<void, UpdateUndeliverableCustomerParams> {
  const UpdateUndeliverableCustomer(this._repo);

  final UndeliverableRepo _repo;

  @override
  ResultFuture<void> call(UpdateUndeliverableCustomerParams params) {
    return _repo.updateUndeliverableCustomer(params.undeliverableCustomer, params.tripId);
  }
}

