import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_impl/delivery_receipt_remote_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_impl/get_delivery_receipt_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_impl/get_delivery_receipt_by_delivery_data_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_impl/create_delivery_receipt_by_delivery_data_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/remote_datasource/delivery_receipt_remote_impl/delete_delivery_receipt_impl.dart';

abstract class DeliveryReceiptRemoteDatasource {
  /// Get delivery receipt by trip ID
  Future<DeliveryReceiptModel> getDeliveryReceiptByTripId(String tripId);

  /// Get delivery receipt by delivery data ID
  Future<DeliveryReceiptModel> getDeliveryReceiptByDeliveryDataId(
    String deliveryDataId,
  );

  /// Create delivery receipt by delivery data ID
  Future<DeliveryReceiptModel> createDeliveryReceiptByDeliveryDataId({
    required String deliveryDataId,
    required String? status,
    required DateTime? dateTimeCompleted,
    required List<String>? customerImages,
    required String? customerSignature,
    required String? receiptFile,
    required double? amount,
    required String? mop,
    String? chequeNumber,
    String? transactionNumber,
    String? bankName,
    String? refNumber,
    String? bankAccountNumber,
  });

  /// Delete delivery receipt by ID
  Future<bool> deleteDeliveryReceipt(String id);
}

class DeliveryReceiptRemoteDatasourceImpl extends DeliveryReceiptRemoteBase
    with
        GetDeliveryReceiptByTripIdImpl,
        GetDeliveryReceiptByDeliveryDataIdImpl,
        CreateDeliveryReceiptByDeliveryDataIdImpl,
        DeleteDeliveryReceiptImpl
    implements DeliveryReceiptRemoteDatasource {
  const DeliveryReceiptRemoteDatasourceImpl({required super.pocketBaseClient});
}
