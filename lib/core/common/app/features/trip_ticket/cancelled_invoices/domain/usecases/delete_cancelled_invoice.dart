import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/domain/repo/cancelled_invoice_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class DeleteCancelledInvoice extends UsecaseWithParams<bool, String> {
  const DeleteCancelledInvoice(this._repo);

  final CancelledInvoiceRepo _repo;

  @override
  ResultFuture<bool> call(String cancelledInvoiceId) => 
      _repo.deleteCancelledInvoice(cancelledInvoiceId);
}
