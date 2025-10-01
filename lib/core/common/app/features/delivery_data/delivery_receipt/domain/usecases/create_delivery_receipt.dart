import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/entity/delivery_receipt_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/repo/delivery_receipt_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CreateDeliveryReceipt
    extends
        UsecaseWithParams<DeliveryReceiptEntity, CreateDeliveryReceiptParams> {
  const CreateDeliveryReceipt(this._repo);

  final DeliveryReceiptRepo _repo;

  @override
  ResultFuture<DeliveryReceiptEntity> call(
    CreateDeliveryReceiptParams params,
  ) async {
    return _repo.createDeliveryReceiptByDeliveryDataId(
      deliveryDataId: params.deliveryDataId,
      status: params.status,
      dateTimeCompleted: params.dateTimeCompleted,
      customerImages: params.customerImages,
      customerSignature: params.customerSignature,
      receiptFile: params.receiptFile,
    );
  }
}

class CreateDeliveryReceiptParams extends Equatable {
  final String deliveryDataId;
  final String? status;
  final DateTime? dateTimeCompleted;
  final List<String>? customerImages;
  final String? customerSignature;
  final String? receiptFile;
  final double? amount;

  const CreateDeliveryReceiptParams({
    required this.deliveryDataId,
    this.status,
    this.dateTimeCompleted,
    this.customerImages,
    this.amount,
    this.customerSignature,
    this.receiptFile,
  });

  @override
  List<Object?> get props => [
    deliveryDataId,
    status,
    dateTimeCompleted,
    customerImages,
    customerSignature,
    receiptFile,
  ];

  @override
  String toString() {
    return 'CreateDeliveryReceiptParams(deliveryDataId: $deliveryDataId, status: $status, dateTimeCompleted: $dateTimeCompleted, customerImages: ${customerImages?.length ?? 0}, customerSignature: $customerSignature, receiptFile: $receiptFile)';
  }
}
