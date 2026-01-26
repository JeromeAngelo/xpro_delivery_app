import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_status_choices/domain/repo/delivery_status_choices_repo.dart';

import '../../../../../../usecases/usecase.dart';
import '../../../../../../utils/typedefs.dart';

class SyncAllDeliveryStatusChoices implements UsecaseWithoutParams<List<DeliveryStatusChoicesEntity>> {
  const SyncAllDeliveryStatusChoices(this._repo);

  final DeliveryStatusChoicesRepo _repo;

  @override
  ResultFuture<List<DeliveryStatusChoicesEntity>> call()  => 
      _repo.syncAllDeliveryStatusChoices();

  
}