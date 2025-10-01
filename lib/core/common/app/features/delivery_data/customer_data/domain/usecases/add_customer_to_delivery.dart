import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/customer_data/domain/repo/customer_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';


class AddCustomerToDelivery extends UsecaseWithParams<bool, AddCustomerToDeliveryParams> {
  final CustomerDataRepo _repo;

  const AddCustomerToDelivery(this._repo);

  @override
  ResultFuture<bool> call(AddCustomerToDeliveryParams params) async {
    return _repo.addCustomerToDelivery(
      customerId: params.customerId,
      deliveryId: params.deliveryId,
    );
  }
}

class AddCustomerToDeliveryParams extends Equatable {
  final String customerId;
  final String deliveryId;

  const AddCustomerToDeliveryParams({
    required this.customerId,
    required this.deliveryId,
  });

  @override
  List<Object?> get props => [customerId, deliveryId];
}
