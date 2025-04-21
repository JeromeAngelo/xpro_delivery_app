import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/datasource/remote_datasource/product_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/datasource/local_datasource/product_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/entity/product_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/domain/repo/product_repo.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/enums/products_status.dart';
class ProductRepoImpl extends ProductRepo {
  const ProductRepoImpl(this._remoteDataSource, this._localDataSource);

  final ProductRemoteDatasource _remoteDataSource;
  final ProductLocalDatasource _localDataSource;

  @override
  ResultFuture<List<ProductEntity>> getProducts() async {
    try {
      debugPrint('🔄 Fetching products from remote source...');
      final remoteProducts = await _remoteDataSource.getProducts();

      debugPrint('📥 Starting sync for ${remoteProducts.length} remote products');
      await _localDataSource.cleanupInvalidEntries();

      for (var product in remoteProducts) {
        if (product.pocketbaseId.isNotEmpty && product.name != null) {
          debugPrint('💾 Syncing valid product: ${product.name}');
          await _localDataSource.updateProduct(product);
        }
      }

      debugPrint('✅ Sync completed with ${remoteProducts.length} valid products');
      return Right(remoteProducts);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      try {
        final localProducts = await _localDataSource.getProducts();
        debugPrint('📦 Using ${localProducts.length} products from cache');
        return Right(localProducts);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }

  @override
  ResultFuture<void> updateProductStatus(
      String productId, ProductsStatus status) async {
    try {
      await _remoteDataSource.updateProductStatus(productId, status);
      await _localDataSource.updateProductStatus(productId, status);
      return const Right(null);
    } on ServerException catch (_) {
      try {
        await _localDataSource.updateProductStatus(productId, status);
        return const Right(null);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }

  @override
  ResultFuture<void> updateProductQuantities(
    String productId, {
    required int? unloadedProductCase,
    required int? unloadedProductPc,
    required int? unloadedProductPack,
    required int? unloadedProductBox,
  }) async {
    try {
      await _remoteDataSource.updateProductQuantities(
        productId,
        unloadedProductCase: unloadedProductCase ?? 0,
        unloadedProductPc: unloadedProductPc ?? 0,
        unloadedProductPack: unloadedProductPack ?? 0,
        unloadedProductBox: unloadedProductBox ?? 0,
      );
      await _localDataSource.updateProductQuantities(
        productId,
        unloadedProductCase: unloadedProductCase ?? 0,
        unloadedProductPc: unloadedProductPc ?? 0,
        unloadedProductPack: unloadedProductPack ?? 0,
        unloadedProductBox: unloadedProductBox ?? 0,
      );
      return const Right(null);
    } on ServerException catch (_) {
      try {
        await _localDataSource.updateProductQuantities(
          productId,
          unloadedProductCase: unloadedProductCase ?? 0,
          unloadedProductPc: unloadedProductPc ?? 0,
          unloadedProductPack: unloadedProductPack ?? 0,
          unloadedProductBox: unloadedProductBox ?? 0,
        );
        return const Right(null);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }

@override
ResultFuture<void> confirmDeliveryProducts(
  String invoiceId, 
  double confirmTotalAmount,
  String customerId,
) async {
  try {
    await _remoteDataSource.confirmDeliveryProducts(invoiceId, confirmTotalAmount, customerId);
    await _localDataSource.confirmDeliveryProducts(invoiceId, confirmTotalAmount, customerId);
    return const Right(null);
  } on ServerException catch (_) {
    try {
      await _localDataSource.confirmDeliveryProducts(invoiceId, confirmTotalAmount, customerId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}


  @override
  ResultFuture<void> addToReturns(
    String productId, {
    required int? returnProductCase,
    required int? returnProductPc,
    required int? returnProductPack,
    required int? returnProductBox,
    required ProductReturnReason? reason,
  }) async {
    try {
      await _remoteDataSource.addToReturn(
        productId,
        reason: reason ?? ProductReturnReason.none,
        returnProductCase: returnProductCase ?? 0,
        returnProductPc: returnProductPc ?? 0,
        returnProductPack: returnProductPack ?? 0,
        returnProductBox: returnProductBox ?? 0,
      );
      await _localDataSource.addToReturn(
        productId,
        reason: reason ?? ProductReturnReason.none,
        returnProductCase: returnProductCase ?? 0,
        returnProductPc: returnProductPc ?? 0,
        returnProductPack: returnProductPack ?? 0,
        returnProductBox: returnProductBox ?? 0,
      );
      return const Right(null);
    } on ServerException catch (_) {
      try {
        await _localDataSource.addToReturn(
          productId,
          reason: reason ?? ProductReturnReason.none,
          returnProductCase: returnProductCase ?? 0,
          returnProductPc: returnProductPc ?? 0,
          returnProductPack: returnProductPack ?? 0,
          returnProductBox: returnProductBox ?? 0,
        );
        return const Right(null);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }

  @override
  ResultFuture<void> updateReturnReason(
    String productId,
    ProductReturnReason reason, {
    required int returnProductCase,
    required int returnProductPc,
    required int returnProductPack,
    required int returnProductBox,
  }) async {
    try {
      await _remoteDataSource.updateReturnReason(
        productId,
        reason,
        returnProductCase: returnProductCase,
        returnProductPc: returnProductPc,
        returnProductPack: returnProductPack,
        returnProductBox: returnProductBox,
      );
      await _localDataSource.updateReturnReason(
        productId,
        reason,
        returnProductCase: returnProductCase,
        returnProductPc: returnProductPc,
        returnProductPack: returnProductPack,
        returnProductBox: returnProductBox,
      );
      return const Right(null);
    } on ServerException catch (_) {
      try {
        await _localDataSource.updateReturnReason(
          productId,
          reason,
          returnProductCase: returnProductCase,
          returnProductPc: returnProductPc,
          returnProductPack: returnProductPack,
          returnProductBox: returnProductBox,
        );
        return const Right(null);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
      }
    }
  }

  @override
  ResultFuture<void> calculateTotalAmount(String productId) async {
    try {
      final products = await _localDataSource.getProducts();
      final product = products.firstWhere((p) => p.id == productId);
      
      double totalAmount = 0;
      
      if (product.isCase == true) {
        totalAmount += (product.unloadedProductCase ?? 0) * (product.pricePerCase ?? 0);
      }
      if (product.isPc == true) {
        totalAmount += (product.unloadedProductPc ?? 0) * (product.pricePerPc ?? 0);
      }
      
      product.totalAmount = totalAmount;
      await _localDataSource.updateProduct(product);
      
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
@override
ResultFuture<List<ProductEntity>> getProductsByInvoiceId(String invoiceId) async {
  try {
    debugPrint('🔄 Fetching products from remote for invoice: $invoiceId');
    final remoteProducts = await _remoteDataSource.getProductsByInvoiceId(invoiceId);

    debugPrint('📥 Starting sync for ${remoteProducts.length} remote products');
    await _localDataSource.cleanupInvalidEntries();

    for (var product in remoteProducts) {
      if (product.id != null && product.name != null) {
        debugPrint('💾 Syncing valid product: ${product.name}');
        await _localDataSource.updateProduct(product);
      }
    }

    debugPrint('✅ Sync completed with ${remoteProducts.length} valid products');
    return Right(remoteProducts);
  } on ServerException catch (e) {
    debugPrint('⚠️ API Error: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<List<ProductEntity>> getLocalProductsByInvoiceId(String invoiceId) async {
  try {
    debugPrint('📱 Loading local products for invoice: $invoiceId');
    final localProducts = await _localDataSource.getProductsByInvoiceId(invoiceId);
    debugPrint('📦 Found ${localProducts.length} products in local storage');
    return Right(localProducts);
  } on CacheException catch (e) {
    debugPrint('⚠️ Cache Error: ${e.message}');
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

}
