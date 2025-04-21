import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/repo/product_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class ConfirmDeliveryProducts extends UsecaseWithParams<void, (String, double, String)> {
  const ConfirmDeliveryProducts(this._repo);

  final ProductRepo _repo;

  @override
  ResultFuture<void> call((String, double, String) params) async {
    return _repo.confirmDeliveryProducts(params.$1, params.$2, params.$3);
  }
}


