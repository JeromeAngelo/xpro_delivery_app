
import '../../../../../../usecases/usecase.dart';
import '../../../../../../utils/typedefs.dart';
import '../entity/delivery_status_choices_entity.dart';
import '../repo/delivery_status_choices_repo.dart';

class GetAllBulkDeliveryStatusChoices extends UsecaseWithParams<Map<String, List<DeliveryStatusChoicesEntity>>, List<String>> {
  final DeliveryStatusChoicesRepo repository;

  const GetAllBulkDeliveryStatusChoices(this.repository);

  @override
  ResultFuture<Map<String, List<DeliveryStatusChoicesEntity>>> call(List<String> customerIds) {
    return repository.getAllBulkDeliveryStatusChoices(customerIds);
  }
}