import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:pdf/pdf.dart';
import '../../../../../../../../../src/transaction_screen/presentation/utils/delivery_orders_pdf.dart';
import '../../../../../../../../enums/sync_status_enums.dart';
import '../../../../../../../../services/objectbox.dart';
import '../../../../../trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import '../../../../delivery_update/data/models/delivery_update_model.dart';

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
    required double? amount,
  });

  /// Update delivery receipt
  Future<void> updateDeliveryReceipt(DeliveryReceiptModel deliveryReceipt);

  /// Delete delivery receipt
  Future<bool> deleteDeliveryReceipt(String id);

  /// Clear all delivery receipts
  Future<void> clearAllDeliveryReceipts();
}

class DeliveryReceiptLocalDatasourceImpl implements DeliveryReceiptLocalDatasource {
    final ObjectBoxStore objectBoxStore;

  List<DeliveryReceiptModel>? _cachedDeliveryReceipts;
  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<DeliveryReceiptModel> get deliveryReceiptBox => objectBoxStore.deliveryReceiptBox;
  // Box<DeliveryStatusChoicesModel> get deliveryStatusChoicesBox =>
  //     objectBoxStore.deliveryStatusBox;

  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;

  //Box<TripModel> get tripBox => objectBoxStore.tripBox; 

  DeliveryReceiptLocalDatasourceImpl(this.objectBoxStore);

  @override
  Future<List<DeliveryReceiptModel>> getAllDeliveryReceipts() async {
    try {
      debugPrint('📱 LOCAL: Fetching all delivery receipts');

      final query = deliveryReceiptBox.query().build();
      final deliveryReceipts = query.find();
      query.close();

      debugPrint('📊 Storage Stats:');
      debugPrint('Total stored delivery receipts: ${deliveryReceiptBox.count()}');
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

      final query = deliveryReceiptBox.query(
        DeliveryReceiptModel_.trip.equals(tripId as int)
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

      final query = deliveryReceiptBox.query(
        DeliveryReceiptModel_.deliveryData.equals(deliveryDataId as int)
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

      final deliveryReceipt = deliveryReceiptBox
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

      final cachedCount = deliveryReceiptBox.count();
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
  required double? amount,
}) async {
  try {
    debugPrint('📱 LOCAL: Creating delivery receipt for deliveryDataId=$deliveryDataId');

    // -------------------------------------------------------------
    // 1️⃣ Resolve actual PB delivery id (supports JSON string input)
    // -------------------------------------------------------------
    String actualDeliveryDataId = deliveryDataId.trim();
    if (actualDeliveryDataId.startsWith('{')) {
      try {
        final decoded = jsonDecode(actualDeliveryDataId);
        actualDeliveryDataId = (decoded['id'] ?? '').toString().trim();
        debugPrint('🎯 LOCAL: Extracted deliveryDataId from JSON → $actualDeliveryDataId');
      } catch (e) {
        debugPrint('⚠️ LOCAL: Failed to parse deliveryDataId JSON: $e');
      }
    }

    if (actualDeliveryDataId.isEmpty) {
      throw CacheException(message: 'deliveryDataId is empty');
    }

    // -------------------------------------------------------------
    // 2️⃣ Find DeliveryData locally (pocketbaseId first, then id)
    // -------------------------------------------------------------
    DeliveryDataModel? delivery;

    final q1 = deliveryDataBox
        .query(DeliveryDataModel_.pocketbaseId.equals(actualDeliveryDataId))
        .build();
    delivery = q1.findFirst();
    q1.close();

    if (delivery == null) {
      final q2 = deliveryDataBox
          .query(DeliveryDataModel_.id.equals(actualDeliveryDataId))
          .build();
      delivery = q2.findFirst();
      q2.close();
    }

    if (delivery == null) {
      debugPrint('❌ LOCAL: DeliveryData not found in ObjectBox for id=$actualDeliveryDataId');
      throw CacheException(message: 'DeliveryData not found locally: $actualDeliveryDataId');
    }

    final deliveryPbId = (delivery.pocketbaseId).trim();
    debugPrint('✅ LOCAL: DeliveryData found → obx=${delivery.objectBoxId} pb=$deliveryPbId');

    // -------------------------------------------------------------
    // ✅ 2.5️⃣ ADD LOCAL DELIVERY STATUS UPDATE (Mark as Received)
    // -------------------------------------------------------------
    try {
      debugPrint('🔄 LOCAL: Creating DeliveryUpdate → Mark as Received');

      final deliveryUpdate = DeliveryUpdateModel(
        title: 'Mark as Received',
        subtitle: 'Received Delivery',
        time: DateTime.now(),
        isAssigned: true,
        id: '', // ⏳ will be set after remote sync (if you sync later)
      );

      // Link relations + offline sync markers
      deliveryUpdate.deliveryData.target = delivery;
      deliveryUpdate.deliveryDataPbId = deliveryPbId;

      // If you have these fields in your model (based on your sample)
      deliveryUpdate.syncStatus = SyncStatus.pending.name;
      deliveryUpdate.retryCount = 0;
      deliveryUpdate.lastLocalUpdatedAt = DateTime.now();

      // Optional fields you used in sample
      deliveryUpdate.customer = delivery.pocketbaseId;

      // Add to parent ToMany
      delivery.deliveryUpdates.add(deliveryUpdate);

      // Save child -> parent
      final updateObxId = deliveryUpdateBox.put(deliveryUpdate);
      deliveryDataBox.put(delivery);

      debugPrint('✅ LOCAL: DeliveryUpdate CREATED');
      debugPrint('   • Update OBX ID: $updateObxId');
      debugPrint('   • Title: ${deliveryUpdate.title}');
      debugPrint('   • Subtitle: ${deliveryUpdate.subtitle}');
      debugPrint('   • Time: ${deliveryUpdate.time}');
      debugPrint('   • Total updates: ${delivery.deliveryUpdates.length}');
    } catch (e) {
      debugPrint('⚠️ LOCAL: Failed to create local delivery update: $e');
      // Do not fail receipt creation; continue
    }

    // -------------------------------------------------------------
    // 3️⃣ Prepare a local DeliveryReceiptModel
    // -------------------------------------------------------------
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    final deliveryReceipt = DeliveryReceiptModel(
      id: tempId,
      collectionId: 'local',
      collectionName: 'deliveryReceipt',
      status: (status ?? 'completed'),
      dateTimeCompleted: dateTimeCompleted ?? DateTime.now(),
      customerImages: customerImages,
      customerSignature: customerSignature,
      receiptFile: receiptFile,
      totalAmount: amount,
      created: DateTime.now(),
      updated: DateTime.now(),
    );

    // -------------------------------------------------------------
    // 4️⃣ Link relations properly (ObjectBox)
    // -------------------------------------------------------------
    deliveryReceipt.deliveryData.target = delivery;

    // Trip relation (optional)
    try {
      final tripTarget = delivery.trip.target;
      if (tripTarget != null) {
        deliveryReceipt.trip.target = tripTarget;
        debugPrint('🚛 LOCAL: Linked trip → ${tripTarget.id} / pb=${tripTarget.pocketbaseId}');
      } else {
        debugPrint('⚠️ LOCAL: DeliveryData has no linked trip');
      }
    } catch (_) {}

    // // InvoiceItems relation (optional)
    // try {
    //   final items = delivery.invoiceItems.toList();
    //   debugPrint('🧾 LOCAL: Found ${items.length} invoiceItems in DeliveryData');

    //   deliveryReceipt.i
    //     ..clear()
    //     ..addAll(items);

    //   debugPrint('✅ LOCAL: Attached ${deliveryReceipt.invoiceItems.length} invoiceItems to receipt');
    // } catch (_) {}

    // -------------------------------------------------------------
    // 5️⃣ Save to ObjectBox
    // -------------------------------------------------------------
    final savedObxId = deliveryReceiptBox.put(deliveryReceipt);

    debugPrint('✅ LOCAL: DeliveryReceipt saved → obx=$savedObxId id=$tempId');
    debugPrint('   📦 delivery pb=$deliveryPbId');
    debugPrint('   🧾 images=${customerImages?.length ?? 0}, signature=${customerSignature != null}, receiptFile=${receiptFile != null}');
    //debugPrint('   💰 totalAmount=${amount ?? 0.0}');
    debugPrint('   ✅ status=${deliveryReceipt.status} completedAt=${deliveryReceipt.dateTimeCompleted}');

    return deliveryReceiptBox.get(savedObxId)!;
  } catch (e, st) {
    debugPrint('❌ LOCAL: createDeliveryReceiptByDeliveryDataId ERROR: $e');
    debugPrint('STACK TRACE: $st');
    throw CacheException(message: e.toString());
  }
}

  @override
  Future<void> updateDeliveryReceipt(DeliveryReceiptModel deliveryReceipt) async {
    try {
      debugPrint('📱 LOCAL: Updating delivery receipt: ${deliveryReceipt.id}');
      
      // Ensure delivery data ID is set if delivery data is assigned
      if (deliveryReceipt.deliveryData.target != null) {
        deliveryReceipt.deliveryData.target!.id = deliveryReceipt.deliveryData.target?.id;
      }
      
      // Ensure trip ID is set if trip is assigned
      if (deliveryReceipt.trip.target != null) {
        deliveryReceipt.trip.target!.id = deliveryReceipt.trip.target?.id;
      }
      
      deliveryReceiptBox.put(deliveryReceipt);
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

      final deliveryReceipt = deliveryReceiptBox
          .query(DeliveryReceiptModel_.pocketbaseId.equals(id))
          .build()
          .findFirst();

      if (deliveryReceipt == null) {
        throw const CacheException(
          message: 'Delivery receipt not found in local storage'
        );
      }

      deliveryReceiptBox.remove(deliveryReceipt.objectBoxId);
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
      deliveryReceiptBox.removeAll();
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
      final allDeliveryReceipts = deliveryReceiptBox.getAll();

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
      deliveryReceiptBox.removeAll();
      deliveryReceiptBox.putMany(uniqueDeliveryReceipts.values.toList());

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
          receipt.deliveryData.target!.id = receipt.deliveryData.target?.id;
        }
        
        // Ensure trip ID is set if trip is assigned
        if (receipt.trip.target != null) {
          receipt.trip.target!.id = receipt.trip.target?.id;
        }
        
        return receipt;
      }).toList();

      deliveryReceiptBox.putMany(validDeliveryReceipts);
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
