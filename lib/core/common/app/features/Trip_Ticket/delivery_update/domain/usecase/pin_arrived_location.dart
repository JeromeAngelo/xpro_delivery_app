import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/domain/repo/delivery_update_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class PinArrivedLocation extends UsecaseWithParams<void, PinArrivedLocationParams> {
  const PinArrivedLocation(this._repository);

  final DeliveryUpdateRepo _repository;

  @override
  ResultFuture<void> call(PinArrivedLocationParams params) async {
    return _repository.pinArrivedLocation(params.deliveryId);
  }
}

class PinArrivedLocationParams {
  const PinArrivedLocationParams({
    required this.deliveryId,
  });

  final String deliveryId;
}
