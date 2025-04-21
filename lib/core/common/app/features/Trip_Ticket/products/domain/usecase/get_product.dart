import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/entity/product_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/repo/product_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GetProduct extends UsecaseWithoutParams<List<ProductEntity>> {
  const GetProduct(this._repo);

  final ProductRepo _repo;

  @override
  ResultFuture<List<ProductEntity>> call() => _repo.getProducts();
}