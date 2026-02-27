import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/data/model/delivery_data_model.dart';

import '../../../../../../../errors/exceptions.dart';
import '../../../../Trip_Ticket/customer_data/data/model/customer_data_model.dart';
import '../../../../Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import '../../model/invoice_status_model.dart';

abstract class InvoiceStatusRemoteDatasource {
  Future<List<InvoiceStatusModel>> getAllInvoiceStatuses();
  Future<InvoiceStatusModel> getInvoiceStatusById(String id);
  Future<List<int>> exportInvoiceStatusesCsvBytes();
  Future<List<int>> exportInvoiceStatusesExcelBytes();
}

class InvoiceStatusRemoteDatasourceImpl
    implements InvoiceStatusRemoteDatasource {
  const InvoiceStatusRemoteDatasourceImpl(this._pocketBaseClient);
  final PocketBase _pocketBaseClient;
  static const String _authTokenKey = 'auth_token';
  static const String _authUserKey = 'auth_user';

  // Helper method to ensure PocketBase client is authenticated
  Future<void> _ensureAuthenticated() async {
    try {
      // Check if already authenticated
      if (_pocketBaseClient.authStore.isValid) {
        debugPrint('✅ PocketBase client already authenticated');
        return;
      }

      debugPrint(
        '⚠️ PocketBase client not authenticated, attempting to restore from storage',
      );

      // Try to restore authentication from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(_authTokenKey);
      final userDataString = prefs.getString(_authUserKey);

      if (authToken != null && userDataString != null) {
        debugPrint('🔄 Restoring authentication from storage');

        // Restore the auth store with token only
        // The PocketBase client will handle the record validation
        _pocketBaseClient.authStore.save(authToken, null);

        debugPrint('✅ Authentication restored from storage');
      } else {
        debugPrint('❌ No stored authentication found');
        throw const ServerException(
          message: 'User not authenticated. Please log in again.',
          statusCode: '401',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to ensure authentication: ${e.toString()}');
      throw ServerException(
        message: 'Authentication error: ${e.toString()}',
        statusCode: '401',
      );
    }
  }

  // ----------------------------
  // ✅ EXPORT: CSV BYTES
  // ----------------------------
  @override
  Future<List<int>> exportInvoiceStatusesCsvBytes() async {
    try {
      debugPrint('📤 Exporting invoice statuses to CSV bytes...');
      await _ensureAuthenticated();

      // Fetch all records (remote)
      final all = await getAllInvoiceStatuses();

      // CSV Header (customize columns as you want)
      const headers = [
        'id',
        'Invoice Name',
        'Customer Name',
        'Delivery Status',
        'Total Amount',
        'documentDate'
        'volume',
        'weight',
        'deliveryDataId',
        'Created',
        'Updated',
      ];

      String _csvEscape(String? v) {
        final s = (v ?? '').replaceAll('\r\n', '\n');
        // escape if contains comma, quote, or newline
        if (s.contains(',') || s.contains('"') || s.contains('\n')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }

      final sb = StringBuffer();
      sb.writeln(headers.join(','));

      for (final item in all) {
        final row = <String>[
          _csvEscape(item.id),
          _csvEscape(item.invoiceData?.name),

          _csvEscape(item.customer?.name),
          _csvEscape(item.tripStatus),
          _csvEscape(item.invoiceData?.totalAmount?.toString()),
          _csvEscape(item.invoiceData?.documentDate?.toIso8601String()),
          _csvEscape(item.invoiceData?.volume?.toString()),
          _csvEscape(item.deliveryData?.id),
          _csvEscape(item.created?.toIso8601String()),
          _csvEscape(item.updated?.toIso8601String()),
        ];
        sb.writeln(row.join(','));
      }

      final bytes = utf8.encode(sb.toString());
      debugPrint('✅ CSV export done. bytes=${bytes.length}');
      return bytes;
    } catch (e) {
      debugPrint('❌ exportInvoiceStatusesCsvBytes failed: $e');
      throw ServerException(
        message: 'Failed to export CSV: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<int>> exportInvoiceStatusesExcelBytes() async {
    try {
      debugPrint('📤 Exporting invoice statuses to Excel bytes...');
      await _ensureAuthenticated();

      final all = await getAllInvoiceStatuses();

      final excel = Excel.createExcel();
      final sheet = excel['InvoiceStatus'];

      // Helper: convert any string to CellValue
      TextCellValue t(String v) => TextCellValue(v);

      // Header row ✅
      sheet.appendRow(<CellValue?>[
        t('ID'),
        t('Invoice Name'),
        t('Customer Name'),
        t('Delivery Status'),
        t('Total Amount'),
        t('Document Date'),
        t('Volume'),
        t('Weight'),
        t('DeliveryData ID'),
        t('Created'),
        t('Updated'),
      ]);

      // Rows ✅
      for (final item in all) {
        sheet.appendRow(<CellValue?>[
          t(item.id ?? ''),
          t(item.invoiceData?.name ?? ''),
          t(item.customer?.name ?? ''),
          t(item.tripStatus ?? ''),
          t(item.invoiceData?.totalAmount?.toString() ?? ''),
          t(item.invoiceData?.documentDate?.toIso8601String() ?? ''),
          t(item.invoiceData?.volume?.toString() ?? ''),
          t(item.invoiceData?.weight?.toString() ?? ''),
          t(item.deliveryData?.id ?? ''),
          t((item.created ?? DateTime.now()).toIso8601String()),
          t((item.updated ?? DateTime.now()).toIso8601String()),
        ]);
      }

      final encoded = excel.encode();
      if (encoded == null) {
        throw const ServerException(
          message: 'Excel encoding failed (null bytes)',
          statusCode: '500',
        );
      }

      debugPrint('✅ Excel export done. bytes=${encoded.length}');
      return encoded;
    } catch (e) {
      debugPrint('❌ exportInvoiceStatusesExcelBytes failed: $e');
      throw ServerException(
        message: 'Failed to export Excel: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<List<InvoiceStatusModel>> getAllInvoiceStatuses() async {
    try {
      debugPrint('🔄 Fetching all invoice data');

      await _ensureAuthenticated();

      const int pageSize = 200; // tune: 100–500
      int page = 1;

      final List<InvoiceStatusModel> all = [];

      while (true) {
        final res = await _pocketBaseClient
            .collection('invoiceStatus')
            .getList(
              page: page,
              perPage: pageSize,
              sort: '-created',
              expand: 'customerData,deliveryData,invoiceData',
            );

        final items = res.items;
        if (items.isEmpty) break;

        all.addAll(items.map(_invoiceStatusFromRecordFast));
        if (items.length < pageSize) break;

        page++;
      }

      debugPrint('✅ Retrieved ${all.length} invoice data records');
      return all;
    } catch (e) {
      debugPrint('❌ Failed to fetch all invoice data: $e');
      throw ServerException(
        message: 'Failed to load invoice data: $e',
        statusCode: '500',
      );
    }
  }

  @override
  Future<InvoiceStatusModel> getInvoiceStatusById(String id) async {
    return await _retryWithBackoff(() async {
      debugPrint('🔄 Fetching delivery data with ID: $id');

      final record = await _pocketBaseClient
          .collection('deliveryData')
          .getOne(id, expand: 'customerData,deliveryData,invoiceData');

      debugPrint('✅ Retrieved delivery data with ID: $id');

      return _invoiceStatusFromRecordFast(record);
    }, 'getDeliveryDataById');
  }

  // Faster mapping (no intermediate Map allocation per field)
  InvoiceStatusModel _invoiceStatusFromRecordFast(RecordModel record) {
    // Process customer data
    CustomerDataModel? customerModel;
    if (record.expand['customerData'] != null) {
      final customerData = record.expand['customerData'];
      if (customerData is List && customerData!.isNotEmpty) {
        final customerRecord = customerData[0];
        customerModel = CustomerDataModel.fromJson({
          'id': customerRecord.id,
          'collectionId': customerRecord.collectionId,
          'collectionName': customerRecord.collectionName,
          'refId': customerRecord.data['refID'],
          'name': customerRecord.data['name'],
          'created': customerRecord.created,
          'updated': customerRecord.updated,

          ...customerRecord.data,
        });
      }
    } else if (record.data['customer'] != null) {
      customerModel = CustomerDataModel(id: record.data['customer'].toString());
    }

    // Process invoice data
    InvoiceDataModel? invoiceModel;
    if (record.expand['invoiceData'] != null) {
      final invoiceData = record.expand['invoiceData'];
      if (invoiceData is List && invoiceData!.isNotEmpty) {
        final invoiceRecord = invoiceData[0];
        invoiceModel = InvoiceDataModel.fromJson({
          'id': invoiceRecord.id,
          'collectionId': invoiceRecord.collectionId,
          'collectionName': invoiceRecord.collectionName,
          'refId': invoiceRecord.data['refID'],
          'name': invoiceRecord.data['name'],
          'documentDate': invoiceRecord.data['documentDate'],
          'totalAmount': invoiceRecord.data['totalAmount'],
          'weight': invoiceRecord.data['weight'],
          'volume': invoiceRecord.data['volume'],
          'created': invoiceRecord.created,
          'updated': invoiceRecord.updated,
          ...invoiceRecord.data,
        });
      }
    } else if (record.data['invoice'] != null) {
      invoiceModel = InvoiceDataModel(id: record.data['invoice'].toString());
    }

    // Process delivery data
    DeliveryDataModel? deliveryDataModel;
    if (record.expand['deliveryData'] != null) {
      final deliveryData = record.expand['deliveryData'];
      if (deliveryData is List && deliveryData!.isNotEmpty) {
        final deliveryRecord = deliveryData[0];
        deliveryDataModel = DeliveryDataModel.fromJson({
          'id': deliveryRecord.id,
          'collectionId': deliveryRecord.collectionId,
          'collectionName': deliveryRecord.collectionName,

          ...deliveryRecord.data,
        });
      }
    } else if (record.data['deliveryData'] != null) {
      deliveryDataModel = DeliveryDataModel(
        id: record.data['deliveryData'].toString(),
      );
    }

    return InvoiceStatusModel(
      id: record.id,
      collectionId: record.collectionId,
      collectionName: record.collectionName,
      customer: customerModel,
      invoiceData: invoiceModel,
      deliveryData: deliveryDataModel,
      tripStatus: record.data['tripStatus']?.toString() ?? '',
      // created: record.created.toIso8601String().to,
      // updated: record.updated,
    );
  }

  // Helper method for retry logic with exponential backoff
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int retryCount = 0;
    Duration delay = initialDelay;

    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;

        // Check if it's a network-related error
        bool isNetworkError =
            e.toString().contains('Failed to fetch') ||
            e.toString().contains('statusCode: 0') ||
            e.toString().contains('isAbort: true') ||
            e.toString().contains('ClientException');

        debugPrint(
          '🔄 Attempt $retryCount/$maxRetries failed for $operationName: ${e.toString()}',
        );

        if (retryCount >= maxRetries || !isNetworkError) {
          debugPrint(
            '❌ Max retries exceeded or non-network error for $operationName',
          );

          // Provide more user-friendly error messages
          if (isNetworkError) {
            throw ServerException(
              message:
                  'Network connection failed. Please check your internet connection and try again.',
              statusCode: '503',
            );
          }

          rethrow;
        }

        debugPrint(
          '⏳ Retrying $operationName in ${delay.inSeconds} seconds...',
        );
        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2); // Exponential backoff
      }
    }

    throw ServerException(
      message: 'Failed to complete $operationName after $maxRetries attempts',
      statusCode: '503',
    );
  }
}
