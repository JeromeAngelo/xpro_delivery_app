import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/repo/invoice_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class SetAllInvoicesCompleted extends UsecaseWithParams<List<InvoiceEntity>, String> {
  final InvoiceRepo _repo;

  const SetAllInvoicesCompleted(this._repo);

  @override
  ResultFuture<List<InvoiceEntity>> call(String tripId) async {
    return _repo.setAllInvoicesCompleted(tripId);
  }
}
