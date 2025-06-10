
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/enitity/delivery_vehicle_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_vehicle_data/domain/repo/delivery_vehicle_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadAllDeliveryVehicles extends UsecaseWithoutParams<List<DeliveryVehicleEntity>> {
  final DeliveryVehicleRepo _repo;

  const LoadAllDeliveryVehicles(this._repo);

  @override
  ResultFuture<List<DeliveryVehicleEntity>> call() {
    return _repo.loadAllDeliveryVehicles();
  }
}
