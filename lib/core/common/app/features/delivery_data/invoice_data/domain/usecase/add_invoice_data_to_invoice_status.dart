import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/repo/invoice_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';


class AddInvoiceDataToInvoiceStatus extends UsecaseWithParams<bool, AddInvoiceDataToInvoiceStatusParams> {
  const AddInvoiceDataToInvoiceStatus(this._repo);

  final InvoiceDataRepo _repo;

  @override
  ResultFuture<bool> call(AddInvoiceDataToInvoiceStatusParams params) async {
    return _repo.addInvoiceDataToInvoiceStatus(
      invoiceId: params.invoiceId,
      invoiceStatusId: params.invoiceStatusId,
    );
  }
}

class AddInvoiceDataToInvoiceStatusParams extends Equatable {
  const AddInvoiceDataToInvoiceStatusParams({
    required this.invoiceId,
    required this.invoiceStatusId,
  });

  final String invoiceId;
  final String invoiceStatusId;

  @override
  List<Object?> get props => [invoiceId, invoiceStatusId];
}
