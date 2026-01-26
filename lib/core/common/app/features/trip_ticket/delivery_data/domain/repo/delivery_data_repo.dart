
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

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

    ResultFuture<List<DeliveryDataEntity>> getLocalDeliveryDataByTripId(String tripId);

  
  /// Load delivery data by ID
  /// 
  /// Takes a delivery data ID and returns the corresponding delivery data entity
  ResultFuture<DeliveryDataEntity> getDeliveryDataById(String id);

    ResultFuture<DeliveryDataEntity> getLocalDeliveryDataById(String id);


  ResultFuture<bool> deleteDeliveryData(String id);

  ResultFuture<int> calculateDeliveryTimeByDeliveryId(String deliveryId);

  ResultFuture<List<DeliveryDataEntity>> syncDeliveryDataByTripId(String tripId);

  ResultFuture<DeliveryDataEntity> setInvoiceIntoUnloading(String deliveryDataId);

  ResultFuture<DeliveryDataEntity> setInvoiceIntoUnloaded(String deliveryDataId);

    ResultFuture<DeliveryDataEntity> setInvoiceIntoCompleted(String deliveryDataId);


  /// Update delivery location by ID
  /// 
  /// Takes a delivery data ID, latitude and longitude and updates the location
  ResultFuture<DeliveryDataEntity> updateDeliveryLocation(String id, double latitude, double longitude);

  /// Emits updates whenever the local delivery data for the given trip changes.
  ResultStream<List<DeliveryDataEntity>> watchLocalDeliveryDataByTripId(String tripId);

    ResultStream<List<DeliveryDataEntity>> watchAllLocalDeliveryData();


   /// Useful for showing live updates for a specific delivery (e.g., in a detail view).
  ResultStream<DeliveryDataEntity?> watchLocalDeliveryDataById(String deliveryId);

}
