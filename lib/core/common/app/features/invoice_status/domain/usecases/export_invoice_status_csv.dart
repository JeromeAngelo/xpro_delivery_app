import '../../../../../../typedefs/typedefs.dart';
import '../../../../../../usecases/usecase.dart';
import '../repo/invoice_status_repo.dart';

class ExportInvoiceStatusesCsv
    extends UsecaseWithoutParams<List<int>> {
  const ExportInvoiceStatusesCsv(this._repo);

  final InvoiceStatusRepo _repo;

  @override
  ResultFuture<List<int>> call() async {
    return _repo.exportInvoiceStatusesCsvBytes();
  }
}