import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';

import '../../../../../../../usecases/usecase.dart';
import '../repo/delivery_data_repo.dart';

class WatchLocalDeliveryDataById
    extends StreamUsecaseWithParams<DeliveryDataEntity?, String> {
  final DeliveryDataRepo _repo;

  WatchLocalDeliveryDataById(this._repo);

  @override
  ResultStream<DeliveryDataEntity?> call(String deliveryId) {
    return _repo.watchLocalDeliveryDataById(deliveryId);
  }
}
