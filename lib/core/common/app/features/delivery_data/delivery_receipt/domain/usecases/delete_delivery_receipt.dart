import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/domain/repo/delivery_receipt_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class DeleteDeliveryReceipt extends UsecaseWithParams<bool, String> {
  const DeleteDeliveryReceipt(this._repo);

  final DeliveryReceiptRepo _repo;

  @override
  ResultFuture<bool> call(String receiptId) async {
    return _repo.deleteDeliveryReceipt(receiptId);
  }
}
