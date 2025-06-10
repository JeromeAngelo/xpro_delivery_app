import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/domain/repo/cancelled_invoice_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadCancelledInvoiceById extends UsecaseWithParams<CancelledInvoiceEntity, String> {
  const LoadCancelledInvoiceById(this._repo);

  final CancelledInvoiceRepo _repo;

  @override
  ResultFuture<CancelledInvoiceEntity> call(String tripId) => 
      _repo.loadCancelledInvoicesById(tripId);

  /// Load from local storage
  ResultFuture<CancelledInvoiceEntity> loadFromLocal(String tripId) => 
      _repo.loadLocalCancelledInvoicesById(tripId);
}
