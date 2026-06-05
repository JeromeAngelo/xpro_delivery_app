import 'dart:typed_data' show Uint8List;
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/delivery_receipt_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/get_all_delivery_receipts_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/get_delivery_receipt_by_trip_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/get_delivery_receipt_by_delivery_data_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/get_delivery_receipt_by_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/cache_delivery_receipts_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/generate_delivery_receipt_pdf_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/create_delivery_receipt_by_delivery_data_id_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/update_delivery_receipt_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/delete_delivery_receipt_impl.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/clear_all_delivery_receipts_impl.dart';

abstract class DeliveryReceiptLocalDatasource {
  /// Get all delivery receipts
  Future<List<DeliveryReceiptModel>> getAllDeliveryReceipts();

  /// Get delivery receipt by trip ID
  Future<DeliveryReceiptModel> getDeliveryReceiptByTripId(String tripId);

  /// Get delivery receipt by delivery data ID
  Future<DeliveryReceiptModel> getDeliveryReceiptByDeliveryDataId(
    String deliveryDataId,
  );

  /// Get delivery receipt by ID
  Future<DeliveryReceiptModel> getDeliveryReceiptById(String id);

  /// Cache delivery receipts
  Future<void> cacheDeliveryReceipts(
    List<DeliveryReceiptModel> deliveryReceipts,
  );

  // Add this to the abstract class (around line 15):
  /// Generate delivery receipt PDF
  Future<Uint8List> generateDeliveryReceiptPdf(DeliveryDataEntity deliveryData);

  /// Create delivery receipt
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

  /// Update delivery receipt
  Future<void> updateDeliveryReceipt(DeliveryReceiptModel deliveryReceipt);

  /// Delete delivery receipt
  Future<bool> deleteDeliveryReceipt(String id);

  /// Clear all delivery receipts
  Future<void> clearAllDeliveryReceipts();
}

class DeliveryReceiptLocalDatasourceImpl extends DeliveryReceiptLocalBase
    with
        GetAllDeliveryReceiptsImpl,
        GetDeliveryReceiptByTripIdImpl,
        GetDeliveryReceiptByDeliveryDataIdImpl,
        GetDeliveryReceiptByIdImpl,
        CacheDeliveryReceiptsImpl,
        GenerateDeliveryReceiptPdfImpl,
        CreateDeliveryReceiptByDeliveryDataIdImpl,
        UpdateDeliveryReceiptImpl,
        DeleteDeliveryReceiptImpl,
        ClearAllDeliveryReceiptsImpl
    implements DeliveryReceiptLocalDatasource {
  DeliveryReceiptLocalDatasourceImpl(super.objectBoxStore);
}
