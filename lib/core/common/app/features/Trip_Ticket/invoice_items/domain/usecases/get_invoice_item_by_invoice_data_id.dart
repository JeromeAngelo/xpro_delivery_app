

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/entity/invoice_items_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/domain/repo/invoice_items_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetInvoiceItemsByInvoiceDataId extends UsecaseWithParams<List<InvoiceItemsEntity>, String> {
  const GetInvoiceItemsByInvoiceDataId(this._repo);

  final InvoiceItemsRepo _repo;

  @override
  ResultFuture<List<InvoiceItemsEntity>> call(String params) => _repo.getInvoiceItemsByInvoiceDataId(params);
  ResultFuture<List<InvoiceItemsEntity>> loadFromLocal(String params) => _repo.getLocalInvoiceItemsByInvoiceDataId(params);
}
