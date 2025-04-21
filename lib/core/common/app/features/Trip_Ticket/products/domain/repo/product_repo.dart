import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/entity/product_entity.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/enums/products_status.dart';
abstract class ProductRepo {
  const ProductRepo();

  ResultFuture<List<ProductEntity>> getProducts();
  
  ResultFuture<void> updateProductStatus(String productId, ProductsStatus status);

   ResultFuture<List<ProductEntity>> getProductsByInvoiceId(String invoiceId);

    ResultFuture<List<ProductEntity>> getLocalProductsByInvoiceId(String invoiceId);
  
  ResultFuture<void> updateProductQuantities(
    String productId, {
    required int? unloadedProductCase,
    required int? unloadedProductPc,
    required int? unloadedProductPack,
    required int? unloadedProductBox,
  });

ResultFuture<void> confirmDeliveryProducts(
  String invoiceId, 
  double confirmTotalAmount,
  String customerId,
);


  ResultFuture<void> addToReturns(
    String productId, {
    required int? returnProductCase,
    required int? returnProductPc,
    required int? returnProductPack,
    required int? returnProductBox,
    required ProductReturnReason? reason,
  });

  ResultFuture<void> updateReturnReason(
    String productId,
    ProductReturnReason reason, {
    required int returnProductCase,
    required int returnProductPc,
    required int returnProductPack,
    required int returnProductBox,
  });

  ResultFuture<void> calculateTotalAmount(String productId);
}

