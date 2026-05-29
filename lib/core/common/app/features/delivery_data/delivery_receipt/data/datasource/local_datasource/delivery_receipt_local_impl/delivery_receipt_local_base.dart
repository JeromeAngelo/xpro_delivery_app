import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/services/objectbox.dart';

abstract class DeliveryReceiptLocalBase {
  final ObjectBoxStore objectBoxStore;
  List<DeliveryReceiptModel>? cachedDeliveryReceipts;

  Box<DeliveryDataModel> get deliveryDataBox => objectBoxStore.deliveryDataBox;
  Box<DeliveryReceiptModel> get deliveryReceiptBox =>
      objectBoxStore.deliveryReceiptBox;
  Box<DeliveryUpdateModel> get deliveryUpdateBox =>
      objectBoxStore.deliveryUpdateBox;

  DeliveryReceiptLocalBase(this.objectBoxStore);

  Future<void> cleanupDeliveryReceipts() async {
    try {
      debugPrint('🧹 LOCAL: Starting delivery receipt cleanup process');
      final allDeliveryReceipts = deliveryReceiptBox.getAll();

      // Create a map to track unique delivery receipts by their PocketBase ID
      final Map<String?, DeliveryReceiptModel> uniqueDeliveryReceipts = {};

      for (var receipt in allDeliveryReceipts) {
        // Only keep valid delivery receipts with required fields
        if (isValidDeliveryReceipt(receipt)) {
          // If duplicate found, keep the most recently updated one
          final existingReceipt = uniqueDeliveryReceipts[receipt.pocketbaseId];
          if (existingReceipt == null ||
              (receipt.updated?.isAfter(
                    existingReceipt.updated ?? DateTime(0),
                  ) ??
                  false)) {
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

  bool isValidDeliveryReceipt(DeliveryReceiptModel receipt) {
    return receipt.id != null && receipt.pocketbaseId.isNotEmpty;
  }

  Future<void> autoSave(List<DeliveryReceiptModel> deliveryReceiptList) async {
    try {
      debugPrint(
        '🔍 LOCAL: Processing ${deliveryReceiptList.length} delivery receipt items',
      );

      final validDeliveryReceipts =
          deliveryReceiptList.map((receipt) {
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
      cachedDeliveryReceipts = validDeliveryReceipts;

      debugPrint('📊 LOCAL: Storage Stats:');
      debugPrint('Total Delivery Receipts: ${validDeliveryReceipts.length}');
      debugPrint(
        'Valid Delivery Receipts: ${validDeliveryReceipts.where((r) => r.id != null).length}',
      );
    } catch (e) {
      debugPrint('❌ LOCAL: Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
