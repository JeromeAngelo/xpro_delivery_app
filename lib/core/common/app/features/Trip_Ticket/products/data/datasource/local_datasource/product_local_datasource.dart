import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/enums/products_status.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

abstract class ProductLocalDatasource {
  Future<List<ProductModel>> getProducts();
  Future<void> updateProductStatus(String productId, ProductsStatus status);
  Future<void> confirmDeliveryProducts(
      String invoiceId, double confirmTotalAmount, String customerId);
  Future<void> updateProduct(ProductModel product);
  Future<void> cleanupInvalidEntries();
  Future<void> updateProductQuantities(
    String productId, {
    required int unloadedProductCase,
    required int unloadedProductPc,
    required int unloadedProductPack,
    required int unloadedProductBox,
  });
  Future<void> addToReturn(
    String productId, {
    required ProductReturnReason reason,
    required int returnProductCase,
    required int returnProductPc,
    required int returnProductPack,
    required int returnProductBox,
  });
  Future<void> updateReturnReason(
    String productId,
    ProductReturnReason reason, {
    required int returnProductCase,
    required int returnProductPc,
    required int returnProductPack,
    required int returnProductBox,
  });

  Future<List<ProductModel>> getProductsByInvoiceId(String invoiceId);
}

class ProductLocalDatasourceImpl implements ProductLocalDatasource {
  final Box<ProductModel> _productBox;

  ProductLocalDatasourceImpl(this._productBox);

  @override
  Future<List<ProductModel>> getProductsByInvoiceId(String invoiceId) async {
    try {
      debugPrint('📱 LOCAL: Loading products for invoice: $invoiceId');

      // Query products with invoice relationship
      final query =
          _productBox.query(ProductModel_.invoiceId.equals(invoiceId)).build();

      final products = query.find();
      query.close();

      if (products.isEmpty) {
        debugPrint('ℹ️ No products found for invoice: $invoiceId');
        return [];
      }

      debugPrint('✅ Found ${products.length} products for invoice');
      products.forEach((product) {
        debugPrint('   📦 Product: ${product.name} (${product.id})');
      });

      return products.where(_isValidProduct).toList();
    } catch (e) {
      debugPrint('❌ LOCAL: Error loading products - $e');
      throw CacheException(message: e.toString());
    }
  }

  bool _isValidProduct(ProductModel product) {
    return product.pocketbaseId.isNotEmpty && product.name != null;
  }

  Future<void> _autoSave(ProductModel product) async {
    try {
      if (!_isValidProduct(product)) {
        debugPrint('⚠️ Skipping invalid product data');
        return;
      }

      debugPrint(
          '🔍 Processing product: ${product.name} (ID: ${product.pocketbaseId})');

      final existingProduct = _productBox
          .query(ProductModel_.pocketbaseId.equals(product.pocketbaseId))
          .build()
          .findFirst();

      if (existingProduct != null) {
        debugPrint('🔄 Updating existing product: ${product.name}');
        product.dbId = existingProduct.dbId;
      }

      _productBox.put(product);
      debugPrint('✅ Product saved successfully');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cleanupInvalidEntries() async {
    final invalidProducts =
        _productBox.getAll().where((p) => !_isValidProduct(p)).toList();

    if (invalidProducts.isNotEmpty) {
      debugPrint('🧹 Found ${invalidProducts.length} invalid products');
      for (var product in invalidProducts) {
        if (product.dbId > 0) {
          _productBox.remove(product.dbId);
        }
      }
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      await cleanupInvalidEntries();
      final products = _productBox.getAll().where(_isValidProduct).toList();
      debugPrint('📦 Retrieved ${products.length} valid products');
      return products;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _autoSave(product);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateProductStatus(
      String productId, ProductsStatus status) async {
    try {
      final query = _productBox
          .query(ProductModel_.pocketbaseId.equals(productId))
          .build();
      final product = query.findFirst();
      query.close();

      if (product != null) {
        product.status = status;
        await _autoSave(product);
      }
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> confirmDeliveryProducts(
      String invoiceId, double confirmTotalAmount, String customerId) async {
    try {
      final products = _productBox
          .getAll()
          .where((p) => p.invoice.target?.id == invoiceId)
          .toList();

      for (var product in products) {
        product.status = ProductsStatus.completed;
        await _autoSave(product);
      }
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateProductQuantities(
    String productId, {
    required int unloadedProductCase,
    required int unloadedProductPc,
    required int unloadedProductPack,
    required int unloadedProductBox,
  }) async {
    try {
      final query = _productBox
          .query(ProductModel_.pocketbaseId.equals(productId))
          .build();
      final product = query.findFirst();
      query.close();

      if (product != null) {
        product.unloadedProductCase = unloadedProductCase;
        product.unloadedProductPc = unloadedProductPc;
        product.unloadedProductPack = unloadedProductPack;
        product.unloadedProductBox = unloadedProductBox;
        await _autoSave(product);
      }
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> addToReturn(
    String productId, {
    required ProductReturnReason reason,
    required int returnProductCase,
    required int returnProductPc,
    required int returnProductPack,
    required int returnProductBox,
  }) async {
    try {
      final query = _productBox
          .query(ProductModel_.pocketbaseId.equals(productId))
          .build();
      final product = query.findFirst();
      query.close();

      if (product != null) {
        product.returnReason = reason;
        product.status = ProductsStatus.completed;
        await _autoSave(product);
      }
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateReturnReason(
    String productId,
    ProductReturnReason reason, {
    required int returnProductCase,
    required int returnProductPc,
    required int returnProductPack,
    required int returnProductBox,
  }) async {
    try {
      final query = _productBox
          .query(ProductModel_.pocketbaseId.equals(productId))
          .build();
      final product = query.findFirst();
      query.close();

      if (product != null) {
        product.returnReason = reason;
        await _autoSave(product);
      }
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
