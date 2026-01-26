import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import '../entity/delivery_status_choices_entity.dart';
import '../repo/delivery_status_choices_repo.dart';

class GetAssignedDeliveryStatusChoices
    implements UsecaseWithParams<List<DeliveryStatusChoicesEntity>, String> {
  const GetAssignedDeliveryStatusChoices(this._repo);

  final DeliveryStatusChoicesRepo _repo;

  @override
  ResultFuture<List<DeliveryStatusChoicesEntity>> call(String customerId) async =>
      _repo.getAllAssignedDeliveryStatusChoices(customerId);
}
