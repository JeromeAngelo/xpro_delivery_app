import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/domain/entity/invoice_items_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/domain/repo/invoice_items_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetAllInvoiceItems
    extends UsecaseWithoutParams<List<InvoiceItemsEntity>> {
  const GetAllInvoiceItems(this._repo);

  final InvoiceItemsRepo _repo;

  @override
  ResultFuture<List<InvoiceItemsEntity>> call() => _repo.getAllInvoiceItems();
    ResultFuture<List<InvoiceItemsEntity>> loadFromLocal() => _repo.getAllLocalInvoiceItems();

}
