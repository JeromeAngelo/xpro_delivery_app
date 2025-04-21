import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/repo/invoice_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetInvoice extends UsecaseWithoutParams<List<InvoiceEntity>> {
  const GetInvoice(this._repo);

  final InvoiceRepo _repo;

  @override
  ResultFuture<List<InvoiceEntity>> call() => _repo.getInvoices();
  
  ResultFuture<List<InvoiceEntity>> loadFromLocal() => _repo.loadLocalInvoices();
}
