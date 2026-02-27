import '../../../../../../typedefs/typedefs.dart';
import '../../../../../../usecases/usecase.dart';
import '../entity/invoice_status_entity.dart';
import '../repo/invoice_status_repo.dart';

class GetAllInvoiceStatus extends UsecaseWithoutParams<List<InvoiceStatusEntity>> {
  const GetAllInvoiceStatus(this._repo);

  final InvoiceStatusRepo _repo;

  @override
  ResultFuture<List<InvoiceStatusEntity>> call() async {
    return _repo.getAllInvoiceStatuses();
  }
}
