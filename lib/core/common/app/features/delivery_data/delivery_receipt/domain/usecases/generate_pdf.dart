import 'dart:typed_data';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/repo/delivery_receipt_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GenerateDeliveryReceiptPdf extends UsecaseWithParams<Uint8List, DeliveryDataEntity> {
  const GenerateDeliveryReceiptPdf(this._repo);

  final DeliveryReceiptRepo _repo;

  @override
  ResultFuture<Uint8List> call(DeliveryDataEntity params) => 
      _repo.generateDeliveryReceiptPdf(params);
}
