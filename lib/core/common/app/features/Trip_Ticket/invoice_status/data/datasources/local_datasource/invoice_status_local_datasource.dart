import 'dart:async';

import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/data/model/invoice_status_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../../../../../objectbox.g.dart';

abstract class InvoiceStatusLocalDataSource {
  // Get invoice status by invoice ID
  Future<List<InvoiceStatusModel>> getInvoiceStatusByInvoiceId(String invoiceId);
  
  // Cache invoice status
  Future<void> cacheInvoiceStatus(List<InvoiceStatusModel> invoiceStatusList);
}

class InvoiceStatusLocalDataSourceImpl implements InvoiceStatusLocalDataSource {
  const InvoiceStatusLocalDataSourceImpl({required Store store}) : _store = store;

  final Store _store;

  @override
  Future<List<InvoiceStatusModel>> getInvoiceStatusByInvoiceId(String invoiceId) async {
    try {
      debugPrint('📱 Getting local invoice status for invoice ID: $invoiceId');

      final box = _store.box<InvoiceStatusModel>();
      
      // Query for invoice status where the related invoice data ID matches
      final query = box.query(InvoiceStatusModel_.pocketbaseId.notNull()).build();
      final allInvoiceStatus = query.find();
      query.close();

      // Filter by invoice data relation
      final filteredStatus = allInvoiceStatus.where((status) {
        final relatedInvoiceId = status.invoiceData.target?.id;
        return relatedInvoiceId == invoiceId;
      }).toList();

      debugPrint('✅ Retrieved ${filteredStatus.length} local invoice status records for invoice ID: $invoiceId');
      return filteredStatus;
    } catch (e) {
      debugPrint('❌ Failed to get local invoice status: ${e.toString()}');
      throw CacheException(
        message: 'Failed to load local invoice status: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> cacheInvoiceStatus(List<InvoiceStatusModel> invoiceStatusList) async {
    try {
      debugPrint('💾 Caching ${invoiceStatusList.length} invoice status records');

      final box = _store.box<InvoiceStatusModel>();
      
      for (var invoiceStatus in invoiceStatusList) {
        // Check if this invoice status already exists
        final query = box.query(InvoiceStatusModel_.pocketbaseId.equals(invoiceStatus.pocketbaseId)).build();
        final existingStatus = query.findFirst();
        query.close();

        if (existingStatus != null) {
          // Update existing record
          final updatedStatus = existingStatus.copyWith(
            collectionId: invoiceStatus.collectionId,
            collectionName: invoiceStatus.collectionName,
            invoiceData: invoiceStatus.invoiceData.target,
            tripStatus: invoiceStatus.tripStatus,
            created: invoiceStatus.created,
            updated: invoiceStatus.updated,
          );
          updatedStatus.objectBoxId = existingStatus.objectBoxId;
          box.put(updatedStatus);
          debugPrint('🔄 Updated existing invoice status: ${invoiceStatus.id}');
        } else {
          // Insert new record
          box.put(invoiceStatus);
          debugPrint('➕ Cached new invoice status: ${invoiceStatus.id}');
        }
      }

      debugPrint('✅ Successfully cached invoice status records');
    } catch (e) {
      debugPrint('❌ Failed to cache invoice status: ${e.toString()}');
      throw CacheException(
        message: 'Failed to cache invoice status: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
