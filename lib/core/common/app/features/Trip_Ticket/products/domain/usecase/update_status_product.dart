import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/repo/product_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/enums/products_status.dart';

class UpdateStatusProduct extends UsecaseWithParams<void, UpdateStatusParams> {
  const UpdateStatusProduct(this._repo);

  final ProductRepo _repo;
  
  @override
  ResultFuture<void> call(UpdateStatusParams params) =>
      _repo.updateProductStatus(params.productId, params.status);
}

class UpdateStatusParams {
  final String productId;
  final ProductsStatus status;

  const UpdateStatusParams({
    required this.productId,
    required this.status,
  });
}
