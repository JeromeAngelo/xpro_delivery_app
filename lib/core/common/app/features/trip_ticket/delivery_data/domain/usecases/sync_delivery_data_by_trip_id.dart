import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';

class SyncDeliveryDataByTripId extends UsecaseWithParams<List<DeliveryDataEntity>, String> {
  const SyncDeliveryDataByTripId(this._repo);

  final DeliveryDataRepo _repo;

  @override
  ResultFuture<List<DeliveryDataEntity>> call(String tripId) => 
      _repo.syncDeliveryDataByTripId(tripId);
}
