

import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_vehicle_data/domain/enitity/delivery_vehicle_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class DeliveryVehicleRepo {
  /// Loads a specific delivery vehicle by its ID
  /// 
  /// [id] - The unique identifier of the delivery vehicle
  /// 
  /// Returns a [ResultFuture] containing either the [DeliveryVehicleEntity] or a failure
  ResultFuture<DeliveryVehicleEntity> loadDeliveryVehicleById(String id);
  
  /// Loads all delivery vehicles associated with a specific trip
  /// 
  /// [tripId] - The unique identifier of the trip
  /// 
  /// Returns a [ResultFuture] containing either a list of [DeliveryVehicleEntity] or a failure
  ResultFuture<List<DeliveryVehicleEntity>> loadDeliveryVehiclesByTripId(String tripId);
  
  /// Loads all delivery vehicles in the system
  /// 
  /// Returns a [ResultFuture] containing either a list of [DeliveryVehicleEntity] or a failure
  ResultFuture<List<DeliveryVehicleEntity>> loadAllDeliveryVehicles();
  
  /// Creates a new delivery vehicle
  /// 
  /// [vehicle] - The delivery vehicle entity to create
  /// 
 
}
