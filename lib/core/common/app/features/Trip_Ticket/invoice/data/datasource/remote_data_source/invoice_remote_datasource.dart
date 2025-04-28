import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';
import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
import 'package:x_pro_delivery_app/core/enums/product_unit.dart';
import 'package:x_pro_delivery_app/core/enums/products_status.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class InvoiceRemoteDatasource {
  Future<List<InvoiceModel>> getInvoices();
  Future<List<InvoiceModel>> getInvoicesByTripId(String tripId);
  Future<List<InvoiceModel>> getInvoicesByCustomerId(String customerId);
  Future<List<InvoiceModel>> setAllInvoicesCompleted(String tripId);
  Future<InvoiceModel> setInvoiceUnloaded(String invoiceId);
}

class InvoiceRemoteDatasourceImpl implements InvoiceRemoteDatasource {
  InvoiceRemoteDatasourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;
  @override
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      debugPrint('🔄 Fetching all invoices');

      // Get invoices with expanded relations
      final result = await _pocketBaseClient
          .collection('invoices')
          .getFullList(
            filter: '',
            expand: 'customer,customer.deliveryStatus,productsList,trip',
          );

      debugPrint('✅ Retrieved ${result.length} invoices from API');

      List<InvoiceModel> invoices = [];

      for (var record in result) {
        final mappedData = {
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          'invoiceNumber': record.data['invoiceNumber'],
          'customerId': record.data['customer'],
          'tripId': record.data['trip'],
          'status': record.data['status'],
          'totalAmount': record.data['totalAmount'],
          'expand': {
            'customer': record.expand['customer']?[0].data,
            'productsList':
                record.expand['productsList']
                    ?.map(
                      (product) => {
                        'id': product.id,
                        'collectionId': product.collectionId,
                        'collectionName': product.collectionName,
                        ...product.data,
                      },
                    )
                    .toList() ??
                [],
            'trip': record.expand['trip']?[0].data,
          },
        };

        invoices.add(InvoiceModel.fromJson(mappedData));
        await Future.delayed(const Duration(milliseconds: 300));
      }

      return invoices;
    } catch (e) {
      debugPrint('❌ Error fetching invoices: $e');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByTripId(String tripId) async {
    try {
      debugPrint('🔄 Fetching invoices for trip: $tripId');
      final invoiceRecords = await _pocketBaseClient
          .collection('invoices')
          .getFullList(
            filter: 'trip = "$tripId"',
            expand: 'customer,customer.deliveryStatus,productsList,trip',
            fields: '*,expand.productsList.*,expand.trip.*',
            sort: '-created',
          );
      return _processInvoiceRecords(invoiceRecords);
    } catch (e) {
      debugPrint('❌ Error fetching trip invoices: $e');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByCustomerId(String customerId) async {
    try {
      debugPrint('🔄 Fetching invoices for customer: $customerId');

      // Get invoices with expanded product relationships
      final result = await _pocketBaseClient
          .collection('invoices')
          .getFullList(
            filter: 'customer = "$customerId"',
            expand: 'productsList',
          );

      debugPrint('📦 Raw API Response: ${result.length} records');
      List<InvoiceModel> invoices = [];

      for (var record in result) {
        debugPrint('🔍 Processing invoice: ${record.id}');
        debugPrint(
          '📦 Products in record: ${record.data['productsList']?.length ?? 0}',
        );

        // Get full product details
        final productIds = record.data['productsList'] as List? ?? [];
        final products = await Future.wait(
          productIds.map((productId) async {
            final productRecord = await _pocketBaseClient
                .collection('products')
                .getOne(productId.toString());
            return {
              'id': productRecord.id,
              'collectionId': productRecord.collectionId,
              'collectionName': productRecord.collectionName,
              ...productRecord.data,
            };
          }),
        );

        final mappedData = {
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          'invoiceNumber': record.data['invoiceNumber'],
          'customer': record.data['customer'],
          'trip': record.data['trip'],
          'status': record.data['status'],
          'totalAmount': record.data['totalAmount'],
          'confirmTotalAmount': record.data['confirmTotalAmount'],
          'productsList': products,
          'isCompleted': record.data['isCompleted'],
          'created': DateTime.now().toIso8601String(),
          'updated': DateTime.now().toIso8601String(),
        };

        debugPrint('📄 Raw product data: ${record.data['productsList']}');
        debugPrint(
          '🔍 Product IDs type: ${record.data['productsList'].runtimeType}',
        );

        debugPrint('📦 Mapped products count: ${products.length}');
        invoices.add(InvoiceModel.fromJson(mappedData));
      }

      return invoices;
    } catch (e) {
      debugPrint('❌ Error fetching customer invoices: $e');
      rethrow;
    }
  }

  List<InvoiceModel> _processInvoiceRecords(List<RecordModel> records) {
    List<InvoiceModel> invoices = [];

    for (var record in records) {
      double totalAmount = 0.0;
      List<ProductModel> products = [];

      final productsExpand = record.expand['productsList'];
      if (productsExpand != null) {
        for (var productData in productsExpand) {
          final product = ProductModel(
            id: productData.id,
            name: productData.data['name'],
            description: productData.data['description'],
            totalAmount: double.tryParse(
              productData.data['totalAmount']?.toString() ?? '0',
            ),
            case_: int.tryParse(productData.data['case']?.toString() ?? '0'),
            pcs: int.tryParse(productData.data['pcs']?.toString() ?? '0'),
            pack: int.tryParse(productData.data['pack']?.toString() ?? '0'),
            box: int.tryParse(productData.data['box']?.toString() ?? '0'),
            pricePerCase: double.tryParse(
              productData.data['pricePerCase']?.toString() ?? '0',
            ),
            pricePerPc: double.tryParse(
              productData.data['pricePerPc']?.toString() ?? '0',
            ),
            primaryUnit: ProductUnit.values.firstWhere(
              (e) => e.name == (productData.data['primaryUnit'] ?? 'case'),
              orElse: () => ProductUnit.cases,
            ),
            secondaryUnit: ProductUnit.values.firstWhere(
              (e) => e.name == (productData.data['secondaryUnit'] ?? 'pc'),
              orElse: () => ProductUnit.pc,
            ),
            image: productData.data['image'],
            isCase: productData.data['isCase'] ?? false,
            isPc: productData.data['isPc'] ?? false,
            isPack: productData.data['isPack'] ?? false,
            isBox: productData.data['isBox'] ?? false,
            unloadedProductCase: int.tryParse(
              productData.data['unloadedProductCase']?.toString() ?? '0',
            ),
            unloadedProductPc: int.tryParse(
              productData.data['unloadedProductPc']?.toString() ?? '0',
            ),
            unloadedProductPack: int.tryParse(
              productData.data['unloadedProductPack']?.toString() ?? '0',
            ),
            unloadedProductBox: int.tryParse(
              productData.data['unloadedProductBox']?.toString() ?? '0',
            ),
            status: _getProductStatus(productData.data['status']),
            returnReason: ProductReturnReason.values.firstWhere(
              (e) => e.name == (productData.data['returnReason'] ?? 'none'),
              orElse: () => ProductReturnReason.none,
            ),
          );
          products.add(product);
          totalAmount += product.totalAmount ?? 0.0;
        }
      }

      final model = InvoiceModel(
        id: record.id,
        collectionId: record.collectionId,
        collectionName: record.collectionName,
        invoiceNumber: record.data['invoiceNumber'],
        customerId: record.data['customer'],
        tripId: record.data['trip'],
        productsList: products,
        status: _getInvoiceStatus(record.data['status']),
        totalAmount: totalAmount,
        customerDeliveryStatus: _getLatestDeliveryStatus(record),
        created: DateTime.tryParse(record.created),
        updated: DateTime.tryParse(record.updated),
      );

      invoices.add(model);
    }

    return invoices;
  }

  // Existing helper methods remain unchanged
  InvoiceStatus _getInvoiceStatus(dynamic status) {
    if (status == null) return InvoiceStatus.truck;
    final statusStr = status.toString().toLowerCase();
    return InvoiceStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr,
      orElse: () => InvoiceStatus.truck,
    );
  }

  ProductsStatus _getProductStatus(dynamic status) {
    if (status == null) return ProductsStatus.truck;
    final statusStr = status.toString().toLowerCase();
    return ProductsStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr,
      orElse: () => ProductsStatus.truck,
    );
  }

  String _getLatestDeliveryStatus(RecordModel invoiceRecord) {
    final customerExpand = invoiceRecord.expand['customer'];
    final deliveryStatusExpand = customerExpand?[0].expand['deliveryStatus'];

    final latestStatus =
        deliveryStatusExpand?.isNotEmpty == true
            ? deliveryStatusExpand![deliveryStatusExpand.length - 1]
                    .data['title']
                    ?.toString()
                    .toLowerCase() ??
                'pending'
            : 'pending';

    return latestStatus;
  }

  @override
  Future<List<InvoiceModel>> setAllInvoicesCompleted(String tripId) async {
    try {
      debugPrint(
        '🔄 REMOTE: Setting all invoices to completed for trip: $tripId',
      );

      // Extract trip ID if we received a JSON object (similar to customer_remote_data_source.dart)
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      debugPrint('🎯 Using trip ID: $actualTripId');

      // Get all invoices for the trip
      final invoiceRecords = await _pocketBaseClient
          .collection('invoices')
          .getFullList(
            filter: 'trip = "$actualTripId"',
            expand: 'productsList,customer',
          );

      debugPrint(
        '📦 Found ${invoiceRecords.length} invoices for trip: $actualTripId',
      );

      if (invoiceRecords.isEmpty) {
        return [];
      }

      List<InvoiceModel> updatedInvoices = [];

      // Update each invoice to completed status
      for (var record in invoiceRecords) {
        // Update the invoice status to completed
        await _pocketBaseClient
            .collection('invoices')
            .update(
              record.id,
              body: {
                'status': 'completed',
                'isCompleted': true,
                'customerDeliveryStatus': 'completed',
              },
            );

        // Get the updated record
        final updatedRecord = await _pocketBaseClient
            .collection('invoices')
            .getOne(record.id, expand: 'productsList,customer');

        // Process the updated record
        final mappedData = {
          'id': updatedRecord.id,
          'collectionId': updatedRecord.collectionId,
          'collectionName': updatedRecord.collectionName,
          'invoiceNumber': updatedRecord.data['invoiceNumber'],
          'customer': updatedRecord.data['customer'],
          'trip': updatedRecord.data['trip'],
          'status': updatedRecord.data['status'],
          'totalAmount': updatedRecord.data['totalAmount'],
          'confirmTotalAmount': updatedRecord.data['confirmTotalAmount'],
          'customerDeliveryStatus':
              updatedRecord.data['customerDeliveryStatus'],
          'isCompleted':
              updatedRecord.data['isCompleted'] == null
                  ? true
                  : updatedRecord.data['isCompleted'] as bool,

          'productsList': updatedRecord.expand['productsList'] ?? [],
        };

        updatedInvoices.add(InvoiceModel.fromJson(mappedData));
        debugPrint(
          '✅ Updated invoice: ${updatedRecord.id} to completed status',
        );
      }

      debugPrint(
        '✅ Successfully updated ${updatedInvoices.length} invoices to completed status',
      );
      return updatedInvoices;
    } catch (e) {
      debugPrint('❌ Error setting invoices to completed: ${e.toString()}');
      throw ServerException(
        message: 'Failed to set invoices to completed: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<InvoiceModel> setInvoiceUnloaded(String invoiceId) async {
    try {
      debugPrint('🔄 REMOTE: Setting invoice $invoiceId to unloaded status');

      // First, get the current invoice data
      final invoiceRecord = await _pocketBaseClient
          .collection('invoices')
          .getOne(
            invoiceId,
            expand: 'customer,customer.deliveryStatus,productsList,trip',
          );

      debugPrint('✅ Retrieved invoice ${invoiceRecord.id} from API');

      // Update the invoice status to unloaded
      final updatedRecord = await _pocketBaseClient
          .collection('invoices')
          .update(
            invoiceId,
            body: {
              'status': 'unloaded',
             
              // You might want to add additional fields here like:
              // 'unloadedDate': DateTime.now().toIso8601String(),
            },
          );

      debugPrint('✅ Updated invoice ${updatedRecord.id} to unloaded status');

      // Get the updated record with expanded relations
      final refreshedRecord = await _pocketBaseClient
          .collection('invoices')
          .getOne(
            invoiceId,
            expand: 'customer,customer.deliveryStatus,productsList,trip',
          );

      // Process the updated record to create an InvoiceModel
      final mappedData = {
        'id': refreshedRecord.id,
        'collectionId': refreshedRecord.collectionId,
        'collectionName': refreshedRecord.collectionName,
        'invoiceNumber': refreshedRecord.data['invoiceNumber'],
        'customerId': refreshedRecord.data['customer'],
        'tripId': refreshedRecord.data['trip'],
        'status': refreshedRecord.data['status'],
        'totalAmount': refreshedRecord.data['totalAmount'],
        'confirmTotalAmount': refreshedRecord.data['confirmTotalAmount'],
        'isLoaded': refreshedRecord.data['isLoaded'] ?? false,
        'loadedDate': refreshedRecord.data['loadedDate'],
        'expand': {},
      };

      // Process expanded customer data
      if (refreshedRecord.expand.containsKey('customer') &&
          refreshedRecord.expand['customer'] != null) {
        if (refreshedRecord.expand['customer'] is List &&
            (refreshedRecord.expand['customer'] as List).isNotEmpty) {
          final customerRecord =
              (refreshedRecord.expand['customer'] as List).first;
          mappedData['expand']['customer'] = {
            'id': customerRecord.id,
            'collectionId': customerRecord.collectionId,
            'collectionName': customerRecord.collectionName,
            ...customerRecord.data,
          };
        }
      }

      // Process expanded products data
      if (refreshedRecord.expand.containsKey('productsList') &&
          refreshedRecord.expand['productsList'] != null) {
        final productsList = refreshedRecord.expand['productsList'];
        if (productsList is List) {
          mappedData['expand']['productsList'] =
              productsList!
                  .map(
                    (product) => {
                      'id': product.id,
                      'collectionId': product.collectionId,
                      'collectionName': product.collectionName,
                      ...product.data,
                    },
                  )
                  .toList();
        }
      }

      // Process expanded trip data
      if (refreshedRecord.expand.containsKey('trip') &&
          refreshedRecord.expand['trip'] != null) {
        if (refreshedRecord.expand['trip'] is List &&
            (refreshedRecord.expand['trip'] as List).isNotEmpty) {
          final tripRecord = (refreshedRecord.expand['trip'] as List).first;
          mappedData['expand']['trip'] = {
            'id': tripRecord.id,
            'collectionId': tripRecord.collectionId,
            'collectionName': tripRecord.collectionName,
            ...tripRecord.data,
          };
        }
      }

      // Create and return the InvoiceModel
      final invoiceModel = InvoiceModel.fromJson(mappedData);
      debugPrint('✅ Successfully created InvoiceModel for unloaded invoice');

      return invoiceModel;
    } catch (e) {
      debugPrint('❌ Error setting invoice to unloaded: ${e.toString()}');
      throw ServerException(
        message: 'Failed to set invoice to unloaded: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
