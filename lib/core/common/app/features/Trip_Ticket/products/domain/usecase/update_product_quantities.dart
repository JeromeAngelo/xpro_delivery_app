import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/repo/product_repo.dart';

// update_product_quantities.dart
class UpdateProductQuantities extends UsecaseWithParams<void, UpdateProductQuantitiesParams> {
  const UpdateProductQuantities(this._repo);

  final ProductRepo _repo;

  @override
  ResultFuture<void> call(UpdateProductQuantitiesParams params) {
    return _repo.updateProductQuantities(
      params.productId,
      unloadedProductCase: params.unloadedProductCase,
      unloadedProductPc: params.unloadedProductPc,
      unloadedProductPack: params.unloadedProductPack,
      unloadedProductBox: params.unloadedProductBox,
    );
  }
}

class UpdateProductQuantitiesParams {
  final String productId;
  final int unloadedProductCase;
  final int unloadedProductPc;
  final int unloadedProductPack;
  final int unloadedProductBox;

  const UpdateProductQuantitiesParams({
    required this.productId,
    required this.unloadedProductCase,
    required this.unloadedProductPc,
    required this.unloadedProductPack,
    required this.unloadedProductBox,
  });
}
