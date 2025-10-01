

import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/repo/invoice_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class AddInvoiceDataToDelivery extends UsecaseWithParams<bool, AddInvoiceDataToDeliveryParams> {
  const AddInvoiceDataToDelivery(this._repo);

  final InvoiceDataRepo _repo;

  @override
  ResultFuture<bool> call(AddInvoiceDataToDeliveryParams params) async {
    return _repo.addInvoiceDataToDelivery(
      invoiceId: params.invoiceId,
      deliveryId: params.deliveryId,
    );
  }
}

class AddInvoiceDataToDeliveryParams extends Equatable {
  const AddInvoiceDataToDeliveryParams({
    required this.invoiceId,
    required this.deliveryId,
  });

  final String invoiceId;
  final String deliveryId;

  @override
  List<Object?> get props => [invoiceId, deliveryId];
}
