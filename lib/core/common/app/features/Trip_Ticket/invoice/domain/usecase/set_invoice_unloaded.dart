import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/repo/invoice_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

/// Sets an individual invoice to unloaded status by its ID
///
/// Takes an invoice ID as a parameter and returns the updated [InvoiceEntity]
class SetInvoiceUnloaded extends UsecaseWithParams<InvoiceEntity, String> {
  final InvoiceRepo _repo;

  const SetInvoiceUnloaded(this._repo);

  @override
  ResultFuture<InvoiceEntity> call(String invoiceId) async {
    return await _repo.setInvoiceUnloaded(invoiceId);
  }
}
