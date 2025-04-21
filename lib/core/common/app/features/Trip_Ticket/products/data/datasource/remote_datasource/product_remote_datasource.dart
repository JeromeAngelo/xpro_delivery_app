import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/enums/product_unit.dart';
import 'package:x_pro_delivery_app/core/enums/products_status.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class ProductRemoteDatasource {
  Future<List<ProductModel>> getProducts();
  Future<void> updateProductStatus(String productId, ProductsStatus status);
  Future<void> confirmDeliveryProducts(
    String invoiceId,
    double confirmTotalAmount,
    String customerId, // Add customer ID parameter
  );
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

class ProductRemoteDatasourceImpl implements ProductRemoteDatasource {
  const ProductRemoteDatasourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<List<ProductModel>> getProductsByInvoiceId(String invoiceId) async {
    try {
      debugPrint('🔄 REMOTE: Fetching products for invoice: $invoiceId');

      final records = await _pocketBaseClient.collection('products').getList(
            filter: 'invoice = "$invoiceId"',
            expand: 'invoice,customer',
          );

      return records.items.map((record) {
        debugPrint('📦 REMOTE: Processing product - ID: ${record.id}');

        final product = ProductModel(
          id: record.id,
          name: record.data['name'],
          description: record.data['description'],
          totalAmount:
              double.tryParse(record.data['totalAmount']?.toString() ?? '0'),
          case_: int.tryParse(record.data['case']?.toString() ?? '0'),
          pcs: int.tryParse(record.data['pcs']?.toString() ?? '0'),
          pack: int.tryParse(record.data['pack']?.toString() ?? '0'),
          box: int.tryParse(record.data['box']?.toString() ?? '0'),
          pricePerCase:
              double.tryParse(record.data['pricePerCase']?.toString() ?? '0'),
          pricePerPc:
              double.tryParse(record.data['pricePerPc']?.toString() ?? '0'),
          primaryUnit: ProductUnit.values.firstWhere(
            (e) => e.name == (record.data['primaryUnit'] ?? 'case'),
            orElse: () => ProductUnit.cases,
          ),
          secondaryUnit: ProductUnit.values.firstWhere(
            (e) => e.name == (record.data['secondaryUnit'] ?? 'pc'),
            orElse: () => ProductUnit.pc,
          ),
          image: record.data['image'],
          isCase: record.data['isCase'] ?? false,
          isPc: record.data['isPc'] ?? false,
          isPack: record.data['isPack'] ?? false,
          isBox: record.data['isBox'] ?? false,
          unloadedProductCase: int.tryParse(
              record.data['unloadedProductCase']?.toString() ?? '0'),
          unloadedProductPc:
              int.tryParse(record.data['unloadedProductPc']?.toString() ?? '0'),
          unloadedProductPack: int.tryParse(
              record.data['unloadedProductPack']?.toString() ?? '0'),
          unloadedProductBox: int.tryParse(
              record.data['unloadedProductBox']?.toString() ?? '0'),
          status: ProductsStatus.values.firstWhere(
            (e) => e.name == (record.data['status'] ?? 'truck'),
            orElse: () => ProductsStatus.truck,
          ),
          returnReason: ProductReturnReason.values.firstWhere(
            (e) => e.name == (record.data['returnReason'] ?? 'none'),
            orElse: () => ProductReturnReason.none,
          ),
        );

        debugPrint('✅ Product mapped successfully: ${product.name}');
        return product;
      }).toList();
    } catch (e) {
      debugPrint('❌ REMOTE: Error fetching products - $e');
      throw ServerException(
        message: 'Failed to fetch products: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      debugPrint('🔄 REMOTE: Fetching products');
      final records = await _pocketBaseClient.collection('products').getList(
            expand: 'invoice,customer',
          );

      return records.items.map((record) {
        debugPrint('📦 REMOTE: Processing product - ID: ${record.id}');

        final product = ProductModel(
          id: record.id,
          name: record.data['name'],
          description: record.data['description'],
          totalAmount:
              double.tryParse(record.data['totalAmount']?.toString() ?? '0'),
          case_: int.tryParse(record.data['case']?.toString() ?? '0'),
          pcs: int.tryParse(record.data['pcs']?.toString() ?? '0'),
          pack: int.tryParse(record.data['pack']?.toString() ?? '0'),
          box: int.tryParse(record.data['box']?.toString() ?? '0'),
          pricePerCase:
              double.tryParse(record.data['pricePerCase']?.toString() ?? '0'),
          pricePerPc:
              double.tryParse(record.data['pricePerPc']?.toString() ?? '0'),
          primaryUnit: ProductUnit.values.firstWhere(
            (e) => e.name == (record.data['primaryUnit'] ?? 'case'),
            orElse: () => ProductUnit.cases,
          ),
          secondaryUnit: ProductUnit.values.firstWhere(
            (e) => e.name == (record.data['secondaryUnit'] ?? 'pc'),
            orElse: () => ProductUnit.pc,
          ),
          image: record.data['image'],
          isCase: record.data['isCase'] ?? false,
          isPc: record.data['isPc'] ?? false,
          isPack: record.data['isPack'] ?? false,
          isBox: record.data['isBox'] ?? false,
          unloadedProductCase: int.tryParse(
              record.data['unloadedProductCase']?.toString() ?? '0'),
          unloadedProductPc:
              int.tryParse(record.data['unloadedProductPc']?.toString() ?? '0'),
          unloadedProductPack: int.tryParse(
              record.data['unloadedProductPack']?.toString() ?? '0'),
          unloadedProductBox: int.tryParse(
              record.data['unloadedProductBox']?.toString() ?? '0'),
          status: ProductsStatus.values.firstWhere(
            (e) => e.name == (record.data['status'] ?? 'truck'),
            orElse: () => ProductsStatus.truck,
          ),
          returnReason: ProductReturnReason.values.firstWhere(
            (e) => e.name == (record.data['returnReason'] ?? 'none'),
            orElse: () => ProductReturnReason.none,
          ),
        );

        debugPrint('✅ Product mapped successfully: ${product.name}');
        return product;
      }).toList();
    } catch (e) {
      debugPrint('❌ REMOTE: Error fetching products - $e');
      throw ServerException(
        message: 'Failed to fetch products: $e',
        statusCode: '500',
      );
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
      debugPrint('🔄 Starting quantity update for product: $productId');
      final product =
          await _pocketBaseClient.collection('products').getOne(productId);

      // Get ordered quantities
      final orderedCase =
          int.tryParse(product.data['case']?.toString() ?? '0') ?? 0;
      final orderedPc =
          int.tryParse(product.data['pcs']?.toString() ?? '0') ?? 0;
      final orderedPack =
          int.tryParse(product.data['pack']?.toString() ?? '0') ?? 0;
      final orderedBox =
          int.tryParse(product.data['box']?.toString() ?? '0') ?? 0;

      debugPrint('📊 Processing quantities:');
      debugPrint(
          'Ordered - Case: $orderedCase, PC: $orderedPc, Pack: $orderedPack, Box: $orderedBox');
      debugPrint(
          'Unloaded - Case: $unloadedProductCase, PC: $unloadedProductPc, Pack: $unloadedProductPack, Box: $unloadedProductBox');

      // Calculate returns
      final returnProductCase = orderedCase - unloadedProductCase;
      final returnProductPc = orderedPc - unloadedProductPc;
      final returnProductPack = orderedPack - unloadedProductPack;
      final returnProductBox = orderedBox - unloadedProductBox;

      final response = await _pocketBaseClient.collection('products').update(
        productId,
        body: {
          'case': unloadedProductCase,
          'pcs': unloadedProductPc,
          'pack': unloadedProductPack,
          'box': unloadedProductBox,
          'unloadedProductCase': unloadedProductCase,
          'unloadedProductPc': unloadedProductPc,
          'unloadedProductPack': unloadedProductPack,
          'unloadedProductBox': unloadedProductBox,
          'returnProductCase': returnProductCase,
          'returnProductPc': returnProductPc,
          'returnProductPack': returnProductPack,
          'returnProductBox': returnProductBox,
        },
      );

      debugPrint('✅ Update successful. Final values:');
      debugPrint(
          'Updated Case: ${response.data['case']}, PC: ${response.data['pcs']}');
      debugPrint(
          'Returns - Case: ${response.data['returnProductCase']}, PC: ${response.data['returnProductPc']}');
    } catch (e) {
      debugPrint('❌ Update failed: $e');
      throw ServerException(
        message: 'Failed to update product quantities: $e',
        statusCode: '500',
      );
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
      debugPrint('🔄 Starting return creation process for product: $productId');

      final product = await _pocketBaseClient.collection('products').getOne(
            productId,
            expand: 'invoice,customer',
          );

      // Get customer record to access trip ID
      final customerRecord =
          await _pocketBaseClient.collection('customers').getOne(
                product.data['customer'],
                expand: 'trip',
              );

      final tripId = customerRecord.expand['trip']?[0].id;
      debugPrint('🚚 Found assigned trip ID: $tripId');

      // Create return record with unit-specific fields
      final returnRecord = await _pocketBaseClient.collection('returns').create(
        body: {
          'productName': product.data['name'],
          'productDescription': product.data['description'],
          'reason': reason.name,
          'productQuantityCase': returnProductCase,
          'productQuantityPcs': returnProductPc,
          'productQuantityPack': returnProductPack,
          'productQuantityBox': returnProductBox,
          'isCase': returnProductCase > 0,
          'isPcs': returnProductPc > 0,
          'isPack': returnProductPack > 0,
          'isBox': returnProductBox > 0,
          'customer': product.data['customer'],
          'invoice': product.data['invoice'],
          'trip': tripId,
          'returnDate': DateTime.now().toIso8601String(),
        },
      );

      // Update product with return information
      await _pocketBaseClient.collection('products').update(
        productId,
        body: {
          'hasReturn': true,
          'returnReason': reason.name,
          'returnRecord': returnRecord.id,
        },
      );

      debugPrint('✅ Return record created successfully');
      debugPrint(
          '📦 Return quantities - Case: $returnProductCase, PC: $returnProductPc');
    } catch (e) {
      debugPrint('❌ Failed to create return: $e');
      throw ServerException(
        message: 'Failed to create return record: $e',
        statusCode: '500',
      );
    }
  }
@override
Future<void> confirmDeliveryProducts(
  String invoiceId,
  double confirmTotalAmount,
  String customerId,
) async {
  try {
    debugPrint('🔄 Starting product confirmation for invoice: $invoiceId');

    // Get current invoice data
    final invoice = await _pocketBaseClient.collection('invoices').getOne(invoiceId);
    final currentInvoiceConfirmedAmount = double.tryParse(
      invoice.data['confirmTotalAmount']?.toString() ?? '0'
    ) ?? 0;

    // Get current customer data
    final customerRecord = await _pocketBaseClient.collection('customers').getOne(customerId);
    final currentCustomerConfirmedTotal = double.tryParse(
      customerRecord.data['confirmedTotalPayment']?.toString() ?? '0'
    ) ?? 0;

    // Only proceed with calculation if both amounts are zero or null
    if (currentInvoiceConfirmedAmount == 0 && currentCustomerConfirmedTotal == 0) {
      debugPrint('💰 Recording confirmed total amount: $confirmTotalAmount');

      // Update invoice with confirmed amount
      await _pocketBaseClient.collection('invoices').update(
        invoiceId,
        body: {
          'status': 'unloaded',
          'confirmTotalAmount': confirmTotalAmount,
        },
      );
      debugPrint('✅ Invoice updated with confirmed total amount: $confirmTotalAmount');

      // Calculate and update customer's confirmedTotalPayment
      final newConfirmedTotal = currentCustomerConfirmedTotal + confirmTotalAmount;
      await _pocketBaseClient.collection('customers').update(
        customerId,
        body: {
          'confirmedTotalPayment': newConfirmedTotal,
        },
      );
      debugPrint('✅ Customer confirmed total payment updated to: $newConfirmedTotal');
    } else {
      debugPrint('⚠️ Skipping calculation - confirmed amounts already exist');
      debugPrint('📊 Invoice confirmed amount: $currentInvoiceConfirmedAmount');
      debugPrint('📊 Customer confirmed total: $currentCustomerConfirmedTotal');
    }

    // Always update products status regardless of payment calculation
    final products = invoice.expand['productList'] as List? ?? [];
    for (var product in products) {
      await _pocketBaseClient.collection('products').update(
        product.id,
        body: {'status': 'unloaded'},
      );
      debugPrint('✓ Product ${product.data['name']} status updated to unloaded');
    }

    debugPrint('✅ Delivery confirmation completed successfully');
  } catch (e) {
    debugPrint('❌ Confirmation failed: ${e.toString()}');
    throw ServerException(
      message: 'Failed to confirm delivery: ${e.toString()}',
      statusCode: '500',
    );
  }
}

  @override
  Future<void> updateProductStatus(
      String productId, ProductsStatus status) async {
    try {
      await _pocketBaseClient.collection('products').update(
        productId,
        body: {
          'status': status.name,
        },
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to update product status: $e',
        statusCode: '500',
      );
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
      await _pocketBaseClient.collection('products').update(
        productId,
        body: {
          'returnReason': reason.name,
          'returnProductCase': returnProductCase,
          'returnProductPc': returnProductPc,
          'returnProductPack': returnProductPack,
          'returnProductBox': returnProductBox,
        },
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to update return reason: $e',
        statusCode: '500',
      );
    }
  }
}
