import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/collection_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetCollectionByIdImpl on CollectionLocalBase {
  @override
  Future<CollectionModel?> getCollectionById(String collectionId) async {
    try {
      debugPrint('📱 LOCAL: Fetching collection by ID: $collectionId');

      // -----------------------------------------------------
      // 1️⃣ Query Collection by PocketBase ID
      // -----------------------------------------------------
      final query =
          collectionBox
              .query(CollectionModel_.pocketbaseId.equals(collectionId))
              .build();
      final collection = query.findFirst();
      query.close();

      if (collection == null) {
        debugPrint('⚠️ Collection not found for ID: $collectionId');
        return null;
      }

      debugPrint('📦 Collection found → ${collection.pocketbaseId}');

      // -----------------------------------------------------
      // 2️⃣ Load Customer (ToOne)
      // -----------------------------------------------------
      final customerRef = collection.customer.target;
      if (customerRef != null) {
        final fullCustomer = customerBox.get(customerRef.objectBoxId);
        if (fullCustomer != null) {
          collection.customer.target = fullCustomer;
          debugPrint('👤 Customer loaded → ${fullCustomer.name}');
        } else {
          debugPrint(
            '⚠️ Customer reference exists but cannot load full object',
          );
        }
      } else {
        debugPrint('⚠️ No customer assigned to this collection');
      }

      // -----------------------------------------------------
      // 3️⃣ Load Delivery Data (ToOne)
      // -----------------------------------------------------
      final deliveryDataRef = collection.deliveryData.target;
      if (deliveryDataRef != null) {
        final fullDeliveryData = deliveryDataBox.get(
          deliveryDataRef.objectBoxId,
        );
        if (fullDeliveryData != null) {
          collection.deliveryData.target = fullDeliveryData;
          debugPrint('🚚 DeliveryData loaded → ${fullDeliveryData.id}');
        } else {
          debugPrint(
            '⚠️ DeliveryData reference exists but cannot load full object',
          );
        }
      } else {
        debugPrint('⚠️ No delivery data assigned to this collection');
      }

      // -----------------------------------------------------
      // 4️⃣ Load Trip (ToOne)
      // -----------------------------------------------------
      final tripRef = collection.trip.target;
      if (tripRef != null) {
        final fullTrip = tripBox.get(tripRef.objectBoxId);
        if (fullTrip != null) {
          collection.trip.target = fullTrip;
          debugPrint('🗺 Trip loaded → ${fullTrip.name}');
        } else {
          debugPrint('⚠️ Trip reference exists but cannot load full object');
        }
      } else {
        debugPrint('⚠️ No trip assigned to this collection');
      }

      // -----------------------------------------------------
      // 5️⃣ Load Invoices (ToMany)
      // -----------------------------------------------------
      final invoices = collection.invoices;
      if (invoices.isNotEmpty) {
        for (var i = 0; i < invoices.length; i++) {
          final inv = invoices[i];
          final fullInv = invoiceBox.get(inv.objectBoxId);
          if (fullInv != null) {
            invoices[i] = fullInv;
            debugPrint('📄 Invoice loaded → ${fullInv.name}');
          } else {
            debugPrint('⚠️ Invoice not found → OBX ID: ${inv.objectBoxId}');
          }
        }
      } else {
        debugPrint('⚠️ No invoices for this collection');
      }

      // -----------------------------------------------------
      // 6️⃣ Load Delivery Receipt (ToOne)
      // -----------------------------------------------------
      final receiptRef = collection.deliveryReceipt.target;
      if (receiptRef != null) {
        final fullReceipt = deliveryReceiptBox.get(receiptRef.objectBoxId);
        if (fullReceipt != null) {
          collection.deliveryReceipt.target = fullReceipt;
          debugPrint('📜 DeliveryReceipt loaded → ${fullReceipt.id}');
        } else {
          debugPrint(
            '⚠️ DeliveryReceipt reference exists but cannot load object',
          );
        }
      } else {
        debugPrint('⚠️ No delivery receipt assigned to this collection');
      }

      debugPrint('✅ Collection fully loaded with nested relations');
      return collection;
    } catch (e, st) {
      debugPrint('❌ LOCAL: getCollectionById error: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
