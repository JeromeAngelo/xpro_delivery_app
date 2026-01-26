
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/repo/delivery_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

/// Usecase for deleting a delivery data entity by ID
///
/// Takes a delivery data ID and returns a boolean indicating success or failure
class DeleteDeliveryData extends UsecaseWithParams<bool, String> {
  final DeliveryDataRepo _repo;

  const DeleteDeliveryData(this._repo);

  @override
  ResultFuture<bool> call(String params) async {
    return _repo.deleteDeliveryData(params);
  }
}
