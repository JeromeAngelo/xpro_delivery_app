import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/model/delivery_receipt_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_receipt/data/datasource/local_datasource/delivery_receipt_local_impl/delivery_receipt_local_base.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin CreateDeliveryReceiptByDeliveryDataIdImpl on DeliveryReceiptLocalBase {
  Future<DeliveryReceiptModel> createDeliveryReceiptByDeliveryDataId({
    required String deliveryDataId,
    required String? status,
    required DateTime? dateTimeCompleted,
    required List<String>? customerImages,
    required String? customerSignature,
    required String? receiptFile,
    required double? amount,
    required String? mop,
  }) async {
    try {
      debugPrint(
        '📱 LOCAL: Creating delivery receipt for deliveryDataId=$deliveryDataId',
      );

      // -------------------------------------------------------------
      // 1️⃣ Resolve actual PB delivery id (supports JSON string input)
      // -------------------------------------------------------------
      String actualDeliveryDataId = deliveryDataId.trim();
      if (actualDeliveryDataId.startsWith('{')) {
        try {
          final decoded = jsonDecode(actualDeliveryDataId);
          actualDeliveryDataId = (decoded['id'] ?? '').toString().trim();
          debugPrint(
            '🎯 LOCAL: Extracted deliveryDataId from JSON → $actualDeliveryDataId',
          );
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

      final q1 =
          deliveryDataBox
              .query(
                DeliveryDataModel_.pocketbaseId.equals(actualDeliveryDataId),
              )
              .build();
      delivery = q1.findFirst();
      q1.close();

      if (delivery == null) {
        final q2 =
            deliveryDataBox
                .query(DeliveryDataModel_.id.equals(actualDeliveryDataId))
                .build();
        delivery = q2.findFirst();
        q2.close();
      }

      if (delivery == null) {
        debugPrint(
          '❌ LOCAL: DeliveryData not found in ObjectBox for id=$actualDeliveryDataId',
        );
        throw CacheException(
          message: 'DeliveryData not found locally: $actualDeliveryDataId',
        );
      }

      final deliveryPbId = (delivery.pocketbaseId).trim();
      debugPrint(
        '✅ LOCAL: DeliveryData found → obx=${delivery.objectBoxId} pb=$deliveryPbId',
      );

      // -------------------------------------------------------------
      // 3️⃣ Create Delivery Collection FIRST
      // -------------------------------------------------------------
      try {
        debugPrint(
          '📦 LOCAL: Creating delivery collection for: $actualDeliveryDataId',
        );

        // Resolve Trip (optional)
        TripModel? tripModel;
        try {
          final tripTarget = delivery.trip.target;
          if (tripTarget != null) {
            final tripQuery =
                objectBoxStore.tripBox
                    .query(TripModel_.id.equals(tripTarget.id!))
                    .build();
            tripModel = tripQuery.findFirst();
            tripQuery.close();
            debugPrint(
              tripModel != null
                  ? '🚛 LOCAL: Trip resolved → OBX ID: ${tripModel.objectBoxId}'
                  : '⚠️ LOCAL: Trip not found locally for ID: ${tripTarget.id}',
            );
          }
        } catch (e) {
          debugPrint('⚠️ LOCAL: Trip resolution failed (non-blocking): $e');
        }

        // Resolve customer and invoices (optional)
        final customerModel = delivery.customer.target;
        final invoiceList = delivery.invoices.toList();

        // Resolve totalAmount and mop from deliveryData
        double? collectionTotalAmount = amount;
        String? collectionMop = mop;

        if (collectionTotalAmount == null || collectionTotalAmount == 0) {
          final deliveryDataTotal = delivery.totalAmount;
          if (deliveryDataTotal != null && deliveryDataTotal > 0) {
            collectionTotalAmount = deliveryDataTotal;
            debugPrint(
              '🧾 LOCAL: Using deliveryData.totalAmount as fallback: $collectionTotalAmount',
            );
          }
        }
        if (collectionMop == null || collectionMop.isEmpty) {
          final deliveryDataPaymentMode = delivery.paymentMode;
          if (deliveryDataPaymentMode != null &&
              deliveryDataPaymentMode.isNotEmpty) {
            collectionMop = deliveryDataPaymentMode;
            debugPrint(
              '💳 LOCAL: Using deliveryData.paymentMode as fallback: $collectionMop',
            );
          }
        }

        final now = DateTime.now();
        final collection = CollectionModel(
          id: '${actualDeliveryDataId}_collection_${now.millisecondsSinceEpoch}',
          collectionName: 'deliveryCollection',
          deliveryDataModel: delivery,
          tripData: tripModel,
          customerData: customerModel,
          invoiceData: invoiceList.isNotEmpty ? invoiceList.first : null,
          invoicesList: invoiceList,
          totalAmount: collectionTotalAmount,
          mop: collectionMop,
          created: now,
          updated: now,
        );

        objectBoxStore.deliveryCollectonBox.put(collection);
        debugPrint('✅ LOCAL: Delivery collection created → ${collection.id}');
        debugPrint(
          '   📦 Collection: totalAmount=$collectionTotalAmount, mop=$collectionMop',
        );
      } catch (e, st) {
        debugPrint(
          '⚠️ LOCAL: Failed to create delivery collection (non-blocking): $e',
        );
        debugPrint('STACK TRACE: $st');
        // Non-blocking: continue with receipt creation
      }

     

      // -------------------------------------------------------------
      // 5️⃣ Prepare a local DeliveryReceiptModel
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
        mop: mop,
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      // -------------------------------------------------------------
      // 6️⃣ Link relations properly (ObjectBox)
      // -------------------------------------------------------------
      deliveryReceipt.deliveryData.target = delivery;

      // Trip relation (optional)
      try {
        final tripTarget = delivery.trip.target;
        if (tripTarget != null) {
          deliveryReceipt.trip.target = tripTarget;
          debugPrint(
            '🚛 LOCAL: Linked trip → ${tripTarget.id} / pb=${tripTarget.pocketbaseId}',
          );
        } else {
          debugPrint('⚠️ LOCAL: DeliveryData has no linked trip');
        }
      } catch (_) {}

      // -------------------------------------------------------------
      // 7️⃣ Save to ObjectBox
      // -------------------------------------------------------------
      final savedObxId = deliveryReceiptBox.put(deliveryReceipt);

      debugPrint('✅ LOCAL: DeliveryReceipt saved → obx=$savedObxId id=$tempId');
      debugPrint('   📦 delivery pb=$deliveryPbId');
      debugPrint(
        '   🧾 images=${customerImages?.length ?? 0}, signature=${customerSignature != null}, receiptFile=${receiptFile != null}',
      );
      debugPrint(
        '   ✅ status=${deliveryReceipt.status} completedAt=${deliveryReceipt.dateTimeCompleted}',
      );
      debugPrint('   💳 mop=${deliveryReceipt.mop}');

      final savedReceipt = deliveryReceiptBox.get(savedObxId)!;

      // Link the delivery receipt to the collection (now that receipt exists)
      try {
        // Find the collection we just created by matching deliveryData relation
        final deliveryId = delivery.id;
        final deliveryPb = delivery.pocketbaseId;
        final fallbackQuery =
            objectBoxStore.deliveryCollectonBox.query().build();
        final allCollections = fallbackQuery.find();
        fallbackQuery.close();
        final existingCollection =
            allCollections.where((c) {
              // Match by deliveryDataId convenience field or by the ToOne relation
              return c.deliveryDataId == deliveryId ||
                  c.deliveryDataId == deliveryPb ||
                  (c.deliveryData.target != null &&
                      (c.deliveryData.target?.id == deliveryId ||
                          c.deliveryData.target?.pocketbaseId == deliveryPbId));
            }).firstOrNull;

        if (existingCollection != null) {
          existingCollection.deliveryReceipt.target = savedReceipt;
          objectBoxStore.deliveryCollectonBox.put(existingCollection);
          debugPrint(
            '✅ LOCAL: Receipt linked to collection → ${existingCollection.id}',
          );
        }
      } catch (e) {
        debugPrint(
          '⚠️ LOCAL: Failed to link receipt to collection (non-blocking): $e',
        );
      }

      // -------------------------------------------------------------
      // 8️⃣ Create "Mark as Received" delivery update locally
      // -------------------------------------------------------------
      try {
        debugPrint(
          '📝 LOCAL: Creating "Mark as Received" delivery update for: $actualDeliveryDataId',
        );

        final now = DateTime.now().add(
          const Duration(seconds: 45),
        ); // Add delay to ensure it appears after the receipt in UI

        // Create a DeliveryUpdateModel for "Mark as Received"
        final deliveryUpdate = DeliveryUpdateModel(
          id: 'local_update_${DateTime.now().millisecondsSinceEpoch}',
          collectionId: 'local',
          collectionName: 'deliveryUpdate',
          title: 'Mark as Received',
          subtitle: 'Received Delivery',
          time: now,
          created: now,
          updated: now,
          lastLocalUpdatedAt: now,
          isAssigned: true,
          deliveryDataPbId: deliveryPbId,
          syncStatus: 'pending',
          retryCount: 0,
          customer: delivery.customer.target?.id,
        );

        // Link the delivery update to the delivery data
        deliveryUpdate.deliveryData.target = delivery;

        // Save the delivery update to ObjectBox
        final updateObxId = deliveryUpdateBox.put(deliveryUpdate);
        debugPrint(
          '✅ LOCAL: Delivery update saved → obx=$updateObxId, title="${deliveryUpdate.title}"',
        );

        // Add the update to the delivery data's deliveryUpdates relation
        delivery.deliveryUpdates.add(deliveryUpdate);
        deliveryDataBox.put(delivery);

        debugPrint(
          '✅ LOCAL: Delivery update linked to DeliveryData → ${delivery.id}',
        );
      } catch (e, st) {
        debugPrint(
          '⚠️ LOCAL: Failed to create "Mark as Received" delivery update (non-blocking): $e',
        );
        debugPrint('STACK TRACE: $st');
        // Non-blocking: receipt was still created successfully
      }

      return savedReceipt;
    } catch (e, st) {
      debugPrint('❌ LOCAL: createDeliveryReceiptByDeliveryDataId ERROR: $e');
      debugPrint('STACK TRACE: $st');
      throw CacheException(message: e.toString());
    }
  }
}
