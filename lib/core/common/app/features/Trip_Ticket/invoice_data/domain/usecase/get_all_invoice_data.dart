

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/entity/invoice_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/repo/invoice_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetAllInvoiceData extends UsecaseWithoutParams<List<InvoiceDataEntity>> {
  const GetAllInvoiceData(this._repo);

  final InvoiceDataRepo _repo;

  @override
  ResultFuture<List<InvoiceDataEntity>> call() async {
    return _repo.getAllInvoiceData();
  }
}
