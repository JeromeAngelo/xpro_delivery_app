import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_status/data/model/invoice_status_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class InvoiceStatusRemoteDataSource {
  // Get invoice status by invoice ID
  Future<List<InvoiceStatusModel>> getInvoiceStatusByInvoiceId(String invoiceId);
}

class InvoiceStatusRemoteDataSourceImpl implements InvoiceStatusRemoteDataSource {
  const InvoiceStatusRemoteDataSourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<List<InvoiceStatusModel>> getInvoiceStatusByInvoiceId(String invoiceId) async {
    try {
      debugPrint('🔄 Fetching invoice status for invoice ID: $invoiceId');

      final result = await _pocketBaseClient
          .collection('invoiceStatus')
          .getFullList(
            expand: 'invoiceData',
            filter: 'invoiceData = "$invoiceId"',
            sort: '-created',
          );

      debugPrint('✅ Retrieved ${result.length} invoice status records for invoice ID: $invoiceId');

      List<InvoiceStatusModel> invoiceStatusList = [];

      for (var record in result) {
        final mappedData = {
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
          'invoiceData': record.data['invoiceData'],
          'tripStatus': record.data['tripStatus'],
          'created': record.data['created'],
          'updated': record.data['updated'],
          'expand': record.expand,
        };

        invoiceStatusList.add(InvoiceStatusModel.fromJson(mappedData));
      }

      return invoiceStatusList;
    } catch (e) {
      debugPrint('❌ Failed to fetch invoice status by invoice ID: ${e.toString()}');
      throw ServerException(
        message: 'Failed to load invoice status by invoice ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
