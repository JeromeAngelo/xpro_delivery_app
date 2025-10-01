

import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/domain/entity/invoice_items_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/domain/repo/invoice_items_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class UpdateInvoiceItemById extends UsecaseWithParams<InvoiceItemsEntity, InvoiceItemsEntity> {
  const UpdateInvoiceItemById(this._repo);

  final InvoiceItemsRepo _repo;

  @override
  ResultFuture<InvoiceItemsEntity> call(InvoiceItemsEntity params) async {
    return _repo.updateInvoiceItemById(params);
  }
}
