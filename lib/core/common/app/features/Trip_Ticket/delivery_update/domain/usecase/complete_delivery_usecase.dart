import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/transaction/data/model/transaction_model.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CompleteDeliveryParams {
  final String customerId;
  final List<InvoiceModel> invoices;
  final List<TransactionModel> transactions;
  final List<ReturnModel> returns;
  final List<DeliveryUpdateModel> deliveryStatus;

  const CompleteDeliveryParams({
    required this.customerId,
    required this.invoices,
    required this.transactions,
    required this.returns,
    required this.deliveryStatus,
  });
}

class CompleteDelivery extends UsecaseWithParams<void, CompleteDeliveryParams> {
  const CompleteDelivery(this._repo);

  final DeliveryUpdateRepo _repo;

  @override
  ResultFuture<void> call(CompleteDeliveryParams params) => _repo.completeDelivery(
    params.customerId,
    invoices: params.invoices,
    transactions: params.transactions,
    returns: params.returns,
    deliveryStatus: params.deliveryStatus,
  );
}
