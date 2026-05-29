import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/watch_delivery_data_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/get_delivery_data_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/force_reload_delivery_updates_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/save_delivery_data_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/get_all_delivery_data_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/get_delivery_data_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/cache_delivery_data_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/update_delivery_data_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delete_delivery_data_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/calculate_delivery_time_by_delivery_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/set_invoice_into_unloaded_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/set_invoice_into_unloading_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/set_invoice_into_cancelled_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/watch_delivery_data_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/watch_all_delivery_data_impl.dart';

abstract class DeliveryDataLocalDataSource {
  Future<void> saveDeliveryDataByTripId(
    String tripId,
    List<DeliveryDataModel> deliveryData,
  ); // Get all delivery data
  Future<List<DeliveryDataModel>> getAllDeliveryData();

  // Get all delivery data by trip ID
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId);

  /// Force reload latest delivery updates for all deliveries in a trip.
  ///
  /// This will re-query the `deliveryUpdate` box for each delivery using
  /// the `deliveryDataPbId` foreign-key and replace the `deliveryUpdates`
  /// collection on the `DeliveryDataModel` instances. Returns the refreshed
  /// delivery models.
  Future<List<DeliveryDataModel>> forceReloadDeliveryUpdatesByTripId(
    String tripId,
  );

  // Get delivery data by ID
  Future<DeliveryDataModel?> getDeliveryDataById(String id);

  // Cache delivery data
  Future<void> cacheDeliveryData(List<DeliveryDataModel> deliveryData);

  // Update delivery data
  Future<void> updateDeliveryData(DeliveryDataModel deliveryData);

  // Delete delivery data
  Future<bool> deleteDeliveryData(String id);

  Future<int> calculateDeliveryTimeByDeliveryId(String deliveryId);

  Future<DeliveryDataModel> setInvoiceIntoUnloaded(String deliveryDataId);

  Future<DeliveryDataModel> setInvoiceIntoUnloading(String deliveryDataId);

  Future<DeliveryDataModel> setInvoiceIntoCancelled(
    String deliveryDataId,
    String invoiceId,
  );

  Stream<List<DeliveryDataModel>> watchDeliveryDataByTripId(String tripId);
  Stream<List<DeliveryDataModel>> watchAllDeliveryData();

  // 👀 Watch a single delivery data by its ID (immediate updates)
  Stream<DeliveryDataModel?> watchDeliveryDataById(String deliveryId);
}

class DeliveryDataLocalDataSourceImpl extends DeliveryDataLocalBase
    with
        WatchDeliveryDataByTripIdImpl,
        GetDeliveryDataByTripIdImpl,
        ForceReloadDeliveryUpdatesByTripIdImpl,
        SaveDeliveryDataByTripIdImpl,
        GetAllDeliveryDataImpl,
        GetDeliveryDataByIdImpl,
        CacheDeliveryDataImpl,
        UpdateDeliveryDataImpl,
        DeleteDeliveryDataImpl,
        CalculateDeliveryTimeByDeliveryIdImpl,
        SetInvoiceIntoUnloadedImpl,
        SetInvoiceIntoUnloadingImpl,
        SetInvoiceIntoCancelledImpl,
        WatchDeliveryDataByIdImpl,
        WatchAllDeliveryDataImpl
    implements DeliveryDataLocalDataSource {
  DeliveryDataLocalDataSourceImpl(super.objectBoxStore);
}
