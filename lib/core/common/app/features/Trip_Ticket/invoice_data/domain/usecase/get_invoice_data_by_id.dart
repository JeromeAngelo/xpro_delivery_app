

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/entity/invoice_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/domain/repo/invoice_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetInvoiceDataById extends UsecaseWithParams<InvoiceDataEntity, String> {
  const GetInvoiceDataById(this._repo);

  final InvoiceDataRepo _repo;

  @override
  ResultFuture<InvoiceDataEntity> call(String params) async {
    return _repo.getInvoiceDataById(params);
  }
}
