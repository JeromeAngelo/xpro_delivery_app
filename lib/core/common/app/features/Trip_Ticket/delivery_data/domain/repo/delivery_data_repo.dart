import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

abstract class DeliveryDataRepo {
  const DeliveryDataRepo();

  /// Load all delivery data
  /// 
  /// Returns a list of all delivery data entities
  ResultFuture<List<DeliveryDataEntity>> getAllDeliveryData();
  
  /// Load all delivery data by trip ID
  /// 
  /// Takes a trip ID and returns all delivery data entities associated with that trip
  ResultFuture<List<DeliveryDataEntity>> getDeliveryDataByTripId(String tripId);
  
  /// Load delivery data by ID
  /// 
  /// Takes a delivery data ID and returns the corresponding delivery data entity
  ResultFuture<DeliveryDataEntity> getDeliveryDataById(String id);

  ResultFuture<bool> deleteDeliveryData(String id);

  ResultFuture<List<DeliveryDataEntity>> getAllDeliveryDataWithTrips();
  
  /// Add delivery data to existing trip
  /// 
  /// Takes a trip ID and adds delivery data to that trip
  ResultFuture<bool> addDeliveryDataToTrip(String tripId);
}
