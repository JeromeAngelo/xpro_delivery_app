import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

abstract class InvoiceItemsLocalDataSource {
  // Get invoice items by invoice data ID
  Future<List<InvoiceItemsModel>> getInvoiceItemsByInvoiceDataId(String invoiceDataId);

  // Get all invoice items
  Future<List<InvoiceItemsModel>> getAllInvoiceItems();

  // Cache invoice items
  Future<void> cacheInvoiceItems(List<InvoiceItemsModel> invoiceItems);

  // Update invoice item by ID
  Future<void> updateInvoiceItem(InvoiceItemsModel invoiceItem);

  // Delete invoice item
  Future<bool> deleteInvoiceItem(String id);
}

class InvoiceItemsLocalDataSourceImpl implements InvoiceItemsLocalDataSource {
  final Box<InvoiceItemsModel> _invoiceItemsBox;
  List<InvoiceItemsModel>? _cachedInvoiceItems;

  InvoiceItemsLocalDataSourceImpl(this._invoiceItemsBox);

  @override
  Future<List<InvoiceItemsModel>> getInvoiceItemsByInvoiceDataId(String invoiceDataId) async {
    try {
      debugPrint('📱 LOCAL: Fetching invoice items for invoice data ID: $invoiceDataId');

      final query = _invoiceItemsBox.query(
        InvoiceItemsModel_.invoiceDataId.equals(invoiceDataId)
      ).build();
      
      final invoiceItems = query.find();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored invoice items: ${_invoiceItemsBox.count()}');
      debugPrint('Found invoice items for invoice data: ${invoiceItems.length}');

      return invoiceItems;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<InvoiceItemsModel>> getAllInvoiceItems() async {
    try {
      debugPrint('📱 LOCAL: Fetching all invoice items');

      final invoiceItems = _invoiceItemsBox.getAll();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored invoice items: ${invoiceItems.length}');

      _cachedInvoiceItems = invoiceItems;
      return invoiceItems;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheInvoiceItems(List<InvoiceItemsModel> invoiceItems) async {
    try {
      debugPrint('💾 LOCAL: Starting invoice items caching process...');
      debugPrint('📥 LOCAL: Received ${invoiceItems.length} invoice items to cache');

      await _cleanupInvoiceItems();
      await _autoSave(invoiceItems);

      final cachedCount = _invoiceItemsBox.count();
      debugPrint('✅ LOCAL: Cache verification: $cachedCount invoice items stored');

      _cachedInvoiceItems = invoiceItems;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateInvoiceItem(InvoiceItemsModel invoiceItem) async {
    try {
      debugPrint('📱 LOCAL: Updating invoice item: ${invoiceItem.id}');
      
      // Ensure invoiceDataId is set if invoiceData is assigned
      if (invoiceItem.invoiceData.target != null) {
        invoiceItem.invoiceDataId = invoiceItem.invoiceData.target?.id;
      }
      
      _invoiceItemsBox.put(invoiceItem);
      debugPrint('✅ LOCAL: Invoice item updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteInvoiceItem(String id) async {
    try {
      debugPrint('📱 LOCAL: Deleting invoice item with ID: $id');

      final invoiceItem = _invoiceItemsBox
          .query(InvoiceItemsModel_.pocketbaseId.equals(id))
          .build()
          .findFirst();

      if (invoiceItem == null) {
        throw const CacheException(
          message: 'Invoice item not found in local storage'
        );
      }

      _invoiceItemsBox.remove(invoiceItem.objectBoxId);
      debugPrint('✅ LOCAL: Successfully deleted invoice item');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: Deletion failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupInvoiceItems() async {
    try {
      debugPrint('🧹 LOCAL: Starting invoice items cleanup process');
      final allInvoiceItems = _invoiceItemsBox.getAll();

      // Create a map to track unique invoice items by their PocketBase ID
      final Map<String?, InvoiceItemsModel> uniqueInvoiceItems = {};

      for (var item in allInvoiceItems) {
        // Only keep valid invoice items with required fields
        if (_isValidInvoiceItem(item)) {
          // If duplicate found, keep the most recently updated one
          final existingItem = uniqueInvoiceItems[item.pocketbaseId];
          if (existingItem == null ||
              (item.updated?.isAfter(existingItem.updated ?? DateTime(0)) ?? false)) {
            uniqueInvoiceItems[item.pocketbaseId] = item;
          }
        }
      }

      // Clear all and save only valid unique invoice items
      _invoiceItemsBox.removeAll();
      _invoiceItemsBox.putMany(uniqueInvoiceItems.values.toList());

      debugPrint('✨ LOCAL: Cleanup complete:');
      debugPrint('📊 Original count: ${allInvoiceItems.length}');
      debugPrint('📊 After cleanup: ${uniqueInvoiceItems.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  bool _isValidInvoiceItem(InvoiceItemsModel item) {
    return item.id != null && item.pocketbaseId.isNotEmpty;
  }

  Future<void> _autoSave(List<InvoiceItemsModel> invoiceItemsList) async {
    try {
      debugPrint('🔍 LOCAL: Processing ${invoiceItemsList.length} invoice items');

      final validInvoiceItems = invoiceItemsList.map((item) {
        // Ensure invoiceDataId is set if invoiceData is assigned
        if (item.invoiceData.target != null) {
          item.invoiceDataId = item.invoiceData.target?.id;
        }
        return item;
      }).toList();

      _invoiceItemsBox.putMany(validInvoiceItems);
      _cachedInvoiceItems = validInvoiceItems;

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total Invoice Items: ${validInvoiceItems.length}');
      debugPrint('Valid Invoice Items: ${validInvoiceItems.where((i) => i.id != null).length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
