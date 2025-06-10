import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:pdf/pdf.dart';
import '../../../../../../../../../src/transcation_screen/presentation/utils/delivery_orders_pdf.dart';

abstract class DeliveryReceiptLocalDatasource {
  /// Get all delivery receipts
  Future<List<DeliveryReceiptModel>> getAllDeliveryReceipts();

  /// Get delivery receipt by trip ID
  Future<DeliveryReceiptModel> getDeliveryReceiptByTripId(String tripId);

  /// Get delivery receipt by delivery data ID
  Future<DeliveryReceiptModel> getDeliveryReceiptByDeliveryDataId(String deliveryDataId);

  /// Get delivery receipt by ID
  Future<DeliveryReceiptModel> getDeliveryReceiptById(String id);

  /// Cache delivery receipts
  Future<void> cacheDeliveryReceipts(List<DeliveryReceiptModel> deliveryReceipts);

  // Add this to the abstract class (around line 15):
  /// Generate delivery receipt PDF
  Future<Uint8List> generateDeliveryReceiptPdf(DeliveryDataEntity deliveryData);


  /// Create delivery receipt
  Future<DeliveryReceiptModel> createDeliveryReceiptByDeliveryDataId({
    required String deliveryDataId,
    required String? status,
    required DateTime? dateTimeCompleted,
    required List<String>? customerImages,
    required String? customerSignature,
    required String? receiptFile,
  });

  /// Update delivery receipt
  Future<void> updateDeliveryReceipt(DeliveryReceiptModel deliveryReceipt);

  /// Delete delivery receipt
  Future<bool> deleteDeliveryReceipt(String id);

  /// Clear all delivery receipts
  Future<void> clearAllDeliveryReceipts();
}

class DeliveryReceiptLocalDatasourceImpl implements DeliveryReceiptLocalDatasource {
  final Box<DeliveryReceiptModel> _deliveryReceiptBox;
  List<DeliveryReceiptModel>? _cachedDeliveryReceipts;

  DeliveryReceiptLocalDatasourceImpl(this._deliveryReceiptBox);

  @override
  Future<List<DeliveryReceiptModel>> getAllDeliveryReceipts() async {
    try {
      debugPrint('📱 LOCAL: Fetching all delivery receipts');

      final query = _deliveryReceiptBox.query().build();
      final deliveryReceipts = query.find();
      query.close();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored delivery receipts: ${_deliveryReceiptBox.count()}');
      debugPrint('Found delivery receipts: ${deliveryReceipts.length}');

      _cachedDeliveryReceipts = deliveryReceipts;
      return deliveryReceipts;
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<DeliveryReceiptModel> getDeliveryReceiptByTripId(String tripId) async {
    try {
      debugPrint('📱 LOCAL: Fetching delivery receipt for trip ID: $tripId');

      final query = _deliveryReceiptBox.query(
        DeliveryReceiptModel_.tripId.equals(tripId)
      ).build();
      
      final deliveryReceipt = query.findFirst();
      query.close();

      if (deliveryReceipt != null) {
        debugPrint('✅ LOCAL: Found delivery receipt in local storage');
        return deliveryReceipt;
      }
      
      throw const CacheException(
        message: 'Delivery receipt not found in local storage'
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<DeliveryReceiptModel> getDeliveryReceiptByDeliveryDataId(String deliveryDataId) async {
    try {
      debugPrint('📱 LOCAL: Fetching delivery receipt for delivery data ID: $deliveryDataId');

      final query = _deliveryReceiptBox.query(
        DeliveryReceiptModel_.deliveryDataId.equals(deliveryDataId)
      ).build();
      
      final deliveryReceipt = query.findFirst();
      query.close();

      if (deliveryReceipt != null) {
        debugPrint('✅ LOCAL: Found delivery receipt in local storage');
        return deliveryReceipt;
      }
      
      throw const CacheException(
        message: 'Delivery receipt not found in local storage'
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<DeliveryReceiptModel> getDeliveryReceiptById(String id) async {
    try {
      debugPrint('📱 LOCAL: Fetching delivery receipt with ID: $id');

      final deliveryReceipt = _deliveryReceiptBox
          .query(DeliveryReceiptModel_.pocketbaseId.equals(id))
          .build()
          .findFirst();

      if (deliveryReceipt != null) {
        debugPrint('✅ LOCAL: Found delivery receipt in local storage');
        return deliveryReceipt;
      }
      
      throw const CacheException(
        message: 'Delivery receipt not found in local storage'
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Query error: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheDeliveryReceipts(List<DeliveryReceiptModel> deliveryReceipts) async {
    try {
      debugPrint('💾 LOCAL: Starting delivery receipt caching process...');
      debugPrint('📥 LOCAL: Received ${deliveryReceipts.length} delivery receipts to cache');

      await _cleanupDeliveryReceipts();
      await _autoSave(deliveryReceipts);

      final cachedCount = _deliveryReceiptBox.count();
      debugPrint('✅ LOCAL: Cache verification: $cachedCount delivery receipts stored');

      _cachedDeliveryReceipts = deliveryReceipts;
      debugPrint('🔄 LOCAL: Cache memory updated');
    } catch (e) {
      debugPrint('❌ LOCAL: Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<DeliveryReceiptModel> createDeliveryReceiptByDeliveryDataId({
    required String deliveryDataId,
    required String? status,
    required DateTime? dateTimeCompleted,
    required List<String>? customerImages,
    required String? customerSignature,
    required String? receiptFile,
  }) async {
    try {
      debugPrint('📱 LOCAL: Creating delivery receipt for delivery data: $deliveryDataId');
      
      // Generate a temporary ID for local storage
      final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      
      final deliveryReceipt = DeliveryReceiptModel(
        id: tempId,
        collectionId: 'local',
        collectionName: 'deliveryReceipt',
        status: status ?? 'pending',
        dateTimeCompleted: dateTimeCompleted,
        customerImages: customerImages,
        customerSignature: customerSignature,
        receiptFile: receiptFile,
        created: DateTime.now(),
        updated: DateTime.now(),
      );
      
      // Set the delivery data ID
      deliveryReceipt.deliveryDataId = deliveryDataId;

      _deliveryReceiptBox.put(deliveryReceipt);
      debugPrint('✅ LOCAL: Delivery receipt created in local storage');
      
      return deliveryReceipt;
    } catch (e) {
      debugPrint('❌ LOCAL: Creation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> updateDeliveryReceipt(DeliveryReceiptModel deliveryReceipt) async {
    try {
      debugPrint('📱 LOCAL: Updating delivery receipt: ${deliveryReceipt.id}');
      
      // Ensure delivery data ID is set if delivery data is assigned
      if (deliveryReceipt.deliveryData.target != null) {
        deliveryReceipt.deliveryDataId = deliveryReceipt.deliveryData.target?.id;
      }
      
      // Ensure trip ID is set if trip is assigned
      if (deliveryReceipt.trip.target != null) {
        deliveryReceipt.tripId = deliveryReceipt.trip.target?.id;
      }
      
      _deliveryReceiptBox.put(deliveryReceipt);
      debugPrint('✅ LOCAL: Delivery receipt updated in local storage');
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteDeliveryReceipt(String id) async {
    try {
      debugPrint('📱 LOCAL: Deleting delivery receipt with ID: $id');

      final deliveryReceipt = _deliveryReceiptBox
          .query(DeliveryReceiptModel_.pocketbaseId.equals(id))
          .build()
          .findFirst();

      if (deliveryReceipt == null) {
        throw const CacheException(
          message: 'Delivery receipt not found in local storage'
        );
      }

      _deliveryReceiptBox.remove(deliveryReceipt.objectBoxId);
      debugPrint('✅ LOCAL: Successfully deleted delivery receipt');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: Deletion failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> clearAllDeliveryReceipts() async {
    try {
      debugPrint('🧹 LOCAL: Clearing all delivery receipts');
      _deliveryReceiptBox.removeAll();
      _cachedDeliveryReceipts = null;
      debugPrint('✅ LOCAL: Successfully cleared all delivery receipts');
    } catch (e) {
      debugPrint('❌ LOCAL: Clear operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> _cleanupDeliveryReceipts() async {
    try {
      debugPrint('🧹 LOCAL: Starting delivery receipt cleanup process');
      final allDeliveryReceipts = _deliveryReceiptBox.getAll();

      // Create a map to track unique delivery receipts by their PocketBase ID
      final Map<String?, DeliveryReceiptModel> uniqueDeliveryReceipts = {};

      for (var receipt in allDeliveryReceipts) {
        // Only keep valid delivery receipts with required fields
        if (_isValidDeliveryReceipt(receipt)) {
          // If duplicate found, keep the most recently updated one
          final existingReceipt = uniqueDeliveryReceipts[receipt.pocketbaseId];
          if (existingReceipt == null ||
              (receipt.updated?.isAfter(existingReceipt.updated ?? DateTime(0)) ?? false)) {
            uniqueDeliveryReceipts[receipt.pocketbaseId] = receipt;
          }
        }
      }

      // Clear all and save only valid unique delivery receipts
      _deliveryReceiptBox.removeAll();
      _deliveryReceiptBox.putMany(uniqueDeliveryReceipts.values.toList());

      debugPrint('✨ LOCAL: Cleanup complete:');
      debugPrint('📊 Original count: ${allDeliveryReceipts.length}');
      debugPrint('📊 After cleanup: ${uniqueDeliveryReceipts.length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  // Add this method to the DeliveryReceiptLocalDatasourceImpl class (around line 280):

  @override
  Future<Uint8List> generateDeliveryReceiptPdf(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint('📄 LOCAL: Generating delivery receipt PDF for: ${deliveryData.id}');
      debugPrint('📄 LOCAL: Customer: ${deliveryData.customer.target?.name}');
      debugPrint('📄 LOCAL: Invoice: ${deliveryData.invoice.target?.refId}');

      final pdfBytes = await DeliveryOrdersPDF.generatePDF(
        deliveryData: deliveryData,
     themeColor: PdfColor.fromHex('#2196F3'), // Default blue theme
      );

      debugPrint('✅ LOCAL: Delivery receipt PDF generated successfully');
      debugPrint('📊 LOCAL: PDF size: ${pdfBytes.length} bytes');
      
      return pdfBytes;
    } catch (e) {
      debugPrint('❌ LOCAL: PDF generation failed: ${e.toString()}');
      throw CacheException(message: 'Failed to generate delivery receipt PDF: ${e.toString()}');
    }
  }


  bool _isValidDeliveryReceipt(DeliveryReceiptModel receipt) {
    return receipt.id != null && receipt.pocketbaseId.isNotEmpty;
  }

  Future<void> _autoSave(List<DeliveryReceiptModel> deliveryReceiptList) async {
    try {
      debugPrint('🔍 LOCAL: Processing ${deliveryReceiptList.length} delivery receipt items');

      final validDeliveryReceipts = deliveryReceiptList.map((receipt) {
        // Ensure delivery data ID is set if delivery data is assigned
        if (receipt.deliveryData.target != null) {
          receipt.deliveryDataId = receipt.deliveryData.target?.id;
        }
        
        // Ensure trip ID is set if trip is assigned
        if (receipt.trip.target != null) {
          receipt.tripId = receipt.trip.target?.id;
        }
        
        return receipt;
      }).toList();

      _deliveryReceiptBox.putMany(validDeliveryReceipts);
      _cachedDeliveryReceipts = validDeliveryReceipts;

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total Delivery Receipts: ${validDeliveryReceipts.length}');
      debugPrint('Valid Delivery Receipts: ${validDeliveryReceipts.where((r) => r.id != null).length}');
    } catch (e) {
      debugPrint('❌ LOCAL: Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
