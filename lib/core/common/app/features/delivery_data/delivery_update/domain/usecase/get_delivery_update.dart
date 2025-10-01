import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/entity/delivery_update_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetDeliveryStatusChoices implements UsecaseWithParams<List<DeliveryUpdateEntity>, String> {
  const GetDeliveryStatusChoices(this._repo);

  final DeliveryUpdateRepo _repo;

  @override
  ResultFuture<List<DeliveryUpdateEntity>> call(String customerId) async => 
      _repo.getDeliveryStatusChoices(customerId);

      ResultFuture<List<DeliveryUpdateEntity>> loadFromLocal(String customerId) => 
      _repo.getLocalDeliveryStatusChoices(customerId);
}
