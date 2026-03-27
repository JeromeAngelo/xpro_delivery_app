import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

import '../entity/delivery_data_entity.dart';

class SetInvoiceIntoCancelled
    extends UsecaseWithParams<DeliveryDataEntity, SetInvoiceIntoCancelledParams> {
  const SetInvoiceIntoCancelled(this._repo);

  final DeliveryDataRepo _repo;

  @override
  ResultFuture<DeliveryDataEntity> call(SetInvoiceIntoCancelledParams params) async {
    return _repo.setInvoiceIntoCancelled(params.deliveryDataId, params.invoiceId);
  }
}


class SetInvoiceIntoCancelledParams {
  final String deliveryDataId;
  final String invoiceId;

  const SetInvoiceIntoCancelledParams({
    required this.deliveryDataId,
    required this.invoiceId,
  });
}