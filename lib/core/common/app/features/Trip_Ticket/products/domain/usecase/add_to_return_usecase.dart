import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/repo/product_repo.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
class AddToReturnUsecase extends UsecaseWithParams<void, AddToReturnParams> {
  const AddToReturnUsecase(this._repo);

  final ProductRepo _repo;

  @override
  ResultFuture<void> call(AddToReturnParams params) => _repo.addToReturns(
        params.productId,
        returnProductCase: params.returnProductCase,
        returnProductPc: params.returnProductPc,
        returnProductPack: params.returnProductPack,
        returnProductBox: params.returnProductBox,
        reason: params.reason,
      );
}

class AddToReturnParams {
  final String productId;
  final ProductReturnReason reason;
  final int returnProductCase;
  final int returnProductPc;
  final int returnProductPack;
  final int returnProductBox;

  const AddToReturnParams({
    required this.productId,
    required this.reason,
    required this.returnProductCase,
    required this.returnProductPc,
    required this.returnProductPack,
    required this.returnProductBox,
  });
}
