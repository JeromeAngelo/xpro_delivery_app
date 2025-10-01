import '../../../../../../../usecases/usecase.dart';
import '../../../../../../../utils/typedefs.dart';
import '../entity/delivery_update_entity.dart';
import '../repo/delivery_update_repo.dart';

class GetBulkDeliveryStatusChoices extends UsecaseWithParams<Map<String, List<DeliveryUpdateEntity>>, List<String>> {
  final DeliveryUpdateRepo repository;

  const GetBulkDeliveryStatusChoices(this.repository);

  @override
  ResultFuture<Map<String, List<DeliveryUpdateEntity>>> call(List<String> customerIds) {
    return repository.getBulkDeliveryStatusChoices(customerIds);
  }
}
