

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/enitity/delivery_vehicle_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/repo/delivery_vehicle_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadDeliveryVehiclesByTripId extends UsecaseWithParams<List<DeliveryVehicleEntity>, String> {
  final DeliveryVehicleRepo _repo;

  const LoadDeliveryVehiclesByTripId(this._repo);

  @override
  ResultFuture<List<DeliveryVehicleEntity>> call(String tripId) {
    return _repo.loadDeliveryVehiclesByTripId(tripId);
  }
}
