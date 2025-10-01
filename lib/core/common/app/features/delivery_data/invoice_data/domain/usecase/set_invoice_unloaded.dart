import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/domain/repo/invoice_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class SetInvoiceUnloaded extends UsecaseWithParams<bool, String> {
  const SetInvoiceUnloaded(this._repo);

  final InvoiceDataRepo _repo;

  @override
  ResultFuture<bool> call(String invoiceDataId) async {
    return _repo.setInvoiceUnloadedById(invoiceDataId);
  }
}
