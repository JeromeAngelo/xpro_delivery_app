import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delivery_data_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/sync_delivery_data_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/get_all_delivery_data_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/get_delivery_data_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/get_delivery_data_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/delete_delivery_data_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/calculate_delivery_time_by_delivery_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/set_invoice_into_unloading_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/set_invoice_into_unloaded_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/set_invoice_into_completed_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/update_delivery_location_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/remote_datasource/delivery_data_remote_impl/set_invoice_into_cancelled_impl.dart';

abstract class DeliveryDataRemoteDataSource {
  // Add this new method
  Future<List<DeliveryDataModel>> syncDeliveryDataByTripId(String tripId);

  // Get all delivery data
  Future<List<DeliveryDataModel>> getAllDeliveryData();

  // Get all delivery data by trip ID
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId);

  // Get delivery data by ID
  Future<DeliveryDataModel> getDeliveryDataById(String id);

  Future<bool> deleteDeliveryData(String id);

  Future<int> calculateDeliveryTimeByDeliveryId(String deliveryId);

  Future<DeliveryDataModel> setInvoiceIntoUnloading(String deliveryDataId);

  Future<DeliveryDataModel> setInvoiceIntoUnloaded(String deliveryDataId);

  Future<DeliveryDataModel> setInvoiceIntoCompleted(String deliveryDataId);

  Future<DeliveryDataModel> updateDeliveryLocation(
    String id,
    double latitude,
    double longitude,
  );

  Future<DeliveryDataModel> setInvoiceIntoCancelled(
    String deliveryDataId,
    String invoiceId,
  );
}

class DeliveryDataRemoteDataSourceImpl extends DeliveryDataRemoteBase
    with
        SyncDeliveryDataByTripIdImpl,
        GetAllDeliveryDataImpl,
        GetDeliveryDataByTripIdImpl,
        GetDeliveryDataByIdImpl,
        DeleteDeliveryDataImpl,
        CalculateDeliveryTimeByDeliveryIdImpl,
        SetInvoiceIntoUnloadingImpl,
        SetInvoiceIntoUnloadedImpl,
        SetInvoiceIntoCompletedImpl,
        UpdateDeliveryLocationImpl,
        SetInvoiceIntoCancelledImpl
        
    implements DeliveryDataRemoteDataSource {
  const DeliveryDataRemoteDataSourceImpl({required super.pocketBaseClient});
}
