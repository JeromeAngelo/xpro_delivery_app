import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_status/domain/entity/invoice_status_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_status/domain/repo/invoice_status_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetInvoiceStatusByInvoiceId extends UsecaseWithParams<List<InvoiceStatusEntity>, String> {
  const GetInvoiceStatusByInvoiceId(this._repo);

  final InvoiceStatusRepo _repo;

  @override
  ResultFuture<List<InvoiceStatusEntity>> call(String invoiceId) async {
    return _repo.getInvoiceStatusByInvoiceId(invoiceId);
  }
}
