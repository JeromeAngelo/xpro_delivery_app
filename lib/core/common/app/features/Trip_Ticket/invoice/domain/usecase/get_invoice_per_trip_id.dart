import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/repo/invoice_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetInvoicesByTrip extends UsecaseWithParams<List<InvoiceEntity>, String> {
  const GetInvoicesByTrip(this._repo);
  final InvoiceRepo _repo;

  @override
  ResultFuture<List<InvoiceEntity>> call(String params) => _repo.getInvoicesByTripId(params);
  ResultFuture<List<InvoiceEntity>> loadFromLocal(String tripId) => _repo.loadLocalInvoicesByTripId(tripId);
}
