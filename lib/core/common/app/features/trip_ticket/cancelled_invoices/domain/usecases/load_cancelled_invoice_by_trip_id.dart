import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/domain/entity/cancelled_invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/domain/repo/cancelled_invoice_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadCancelledInvoicesByTripId extends UsecaseWithParams<List<CancelledInvoiceEntity>, String> {
  const LoadCancelledInvoicesByTripId(this._repo);

  final CancelledInvoiceRepo _repo;

  @override
  ResultFuture<List<CancelledInvoiceEntity>> call(String tripId) => 
      _repo.loadCancelledInvoicesByTripId(tripId);

  /// Load from local storage
  ResultFuture<List<CancelledInvoiceEntity>> loadFromLocal(String tripId) => 
      _repo.loadLocalCancelledInvoicesByTripId(tripId);
}
