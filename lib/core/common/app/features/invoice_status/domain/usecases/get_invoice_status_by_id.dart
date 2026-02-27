import '../../../../../../typedefs/typedefs.dart';
import '../../../../../../usecases/usecase.dart';
import '../entity/invoice_status_entity.dart';
import '../repo/invoice_status_repo.dart';

class GetInvoiceStatusById extends UsecaseWithParams<InvoiceStatusEntity, String> {
  const GetInvoiceStatusById(this._repo);

  final InvoiceStatusRepo _repo;

  @override
  ResultFuture<InvoiceStatusEntity> call(String params) async {
    return _repo.getInvoiceStatusById(params);
  }
}
