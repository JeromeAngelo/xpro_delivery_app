import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';
import 'package:xpro_delivery_admin_app/core/usecases/usecase.dart';

class AddDeliveryDataToTrip extends UsecaseWithParams<bool, String> {
  const AddDeliveryDataToTrip(this._repo);

  final DeliveryDataRepo _repo;

  @override
  ResultFuture<bool> call(String tripId) async {
    return _repo.addDeliveryDataToTrip(tripId);
  }
}
