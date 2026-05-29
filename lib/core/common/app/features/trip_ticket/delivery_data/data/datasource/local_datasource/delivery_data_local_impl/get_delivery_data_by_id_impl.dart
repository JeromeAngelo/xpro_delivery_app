import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetDeliveryDataByIdImpl on DeliveryDataLocalBase {
  @override
  Future<DeliveryDataModel?> getDeliveryDataById(String id) async {
    try {
      debugPrint('📱 LOCAL: Fetching delivery data by ID: $id');

      // -----------------------------------------------------
      // 1️⃣ Query DeliveryData by PocketBase ID
      // -----------------------------------------------------
      final query =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(id))
              .build();
      final deliveryData = query.findFirst();
      query.close();

      if (deliveryData == null) {
        debugPrint('⚠️ DeliveryData not found for ID: $id');
        return null;
      }

      debugPrint('📦 DeliveryData found → ${deliveryData.id}');

      // -----------------------------------------------------
      // 2️⃣ Load Customer (ToOne)
      // -----------------------------------------------------
      final customerRef = deliveryData.customer.target;
      if (customerRef != null) {
        final fullCustomer = customerBox.get(customerRef.objectBoxId);
        if (fullCustomer != null) {
          deliveryData.customer.target = fullCustomer;
          deliveryData.customer.targetId = fullCustomer.objectBoxId;
          debugPrint('👤 Customer loaded → ${fullCustomer.name}');
        } else {
          debugPrint(
            '⚠️ Customer reference exists but cannot load full object',
          );
        }
      } else {
        debugPrint('⚠️ No customer assigned');
      }

      // -----------------------------------------------------
      // 3️⃣ Load Invoice (ToOne)
      // -----------------------------------------------------
      final invoiceRef = deliveryData.invoice.target;
      if (invoiceRef != null) {
        final fullInvoice = invoiceBox.get(invoiceRef.objectBoxId);
        if (fullInvoice != null) {
          deliveryData.invoice.target = fullInvoice;
          deliveryData.invoice.targetId = fullInvoice.objectBoxId;
          debugPrint('🧾 Invoice loaded → ${fullInvoice.name}');
        } else {
          debugPrint('⚠️ Invoice reference exists but cannot load full object');
        }
      } else {
        debugPrint('⚠️ No single invoice assigned');
      }

      // -----------------------------------------------------
      // 4️⃣ Load Invoices (ToMany)
      // -----------------------------------------------------
      final invoices = deliveryData.invoices;
      if (invoices.isNotEmpty) {
        for (var i = 0; i < invoices.length; i++) {
          final inv = invoices[i];
          final fullInvoice = invoiceBox.get(inv.objectBoxId);
          if (fullInvoice != null) {
            invoices[i] = fullInvoice;
            debugPrint('📄 Invoice loaded → ${fullInvoice.name}');
          } else {
            debugPrint('⚠️ Invoice not found → OBX ID: ${inv.objectBoxId}');
          }
        }
      } else {
        debugPrint('⚠️ No invoices for this delivery data');
      }

      // -----------------------------------------------------
      // 5️⃣ Load Invoice Items (ToMany)
      // -----------------------------------------------------
      final invoiceItems = deliveryData.invoiceItems;
      if (invoiceItems.isNotEmpty) {
        for (var i = 0; i < invoiceItems.length; i++) {
          final inv = invoiceItems[i];
          final fullInvoiceItems = invoiceItemsBox.get(inv.objectBoxId);
          if (fullInvoiceItems != null) {
            invoiceItems[i] = fullInvoiceItems;
            debugPrint('📄 Invoice Items loaded → ${fullInvoiceItems.name}');
          } else {
            debugPrint(
              '⚠️ Invoice Items not found → OBX ID: ${inv.objectBoxId}',
            );
          }
        }
      } else {
        debugPrint('⚠️ No invoice items for this delivery data');
      }

      // -----------------------------------------------------
      // 6️⃣ Load Trip (ToOne)
      // -----------------------------------------------------
      final tripRef = deliveryData.trip.target;
      if (tripRef != null) {
        final fullTrip = tripBox.get(tripRef.objectBoxId);
        if (fullTrip != null) {
          deliveryData.trip.target = fullTrip;
          deliveryData.trip.targetId = fullTrip.objectBoxId;
          debugPrint('🚛 Trip loaded → ${fullTrip.name}');
        } else {
          debugPrint('⚠️ Trip reference exists but cannot load full object');
        }
      } else {
        debugPrint('⚠️ No trip assigned');
      }

      // -----------------------------------------------------
      // 7️⃣ Load Delivery Updates (ToMany)
      // -----------------------------------------------------
      final updates = deliveryData.deliveryUpdates;
      if (updates.isNotEmpty) {
        for (var i = 0; i < updates.length; i++) {
          final upd = updates[i];
          final fullUpdate = deliveryUpdateBox.get(upd.objectBoxId);
          if (fullUpdate != null) {
            updates[i] = fullUpdate;
            debugPrint(
              '🔄 DeliveryUpdate loaded → ${fullUpdate.title} at ${fullUpdate.time} in customer $id',
            );
          } else {
            debugPrint(
              '⚠️ DeliveryUpdate not found → OBX ID: ${upd.objectBoxId}',
            );
          }
        }
      } else {
        debugPrint('⚠️ No delivery updates for this delivery data');
      }

      // ---------------------------------------------------
      // 🆕 8️⃣ DEDUPLICATION: Remove duplicate delivery updates
      // ---------------------------------------------------
      if (updates.isNotEmpty) {
        try {
          debugPrint('🔍 Checking for duplicate delivery updates...');
          final dedupList = deduplicateDeliveryUpdates(updates.toList());

          if (dedupList.length < updates.length) {
            deliveryData.deliveryUpdates
              ..clear()
              ..addAll(dedupList);

            // Persist the cleaned relation
            deliveryDataBox.put(deliveryData);

            debugPrint('✅ Delivery updates deduplicated and persisted');
            debugPrint(
              '   📊 Before: ${updates.length} | After: ${dedupList.length}',
            );
          } else {
            debugPrint('✅ No duplicates found in delivery updates');
          }
        } catch (e) {
          debugPrint('⚠️ Deduplication failed (non-blocking): $e');
          // Continue anyway - deduplication is a best-effort optimization
        }
      }

      // ---------------------------------------------------
      // 9️⃣ FORCE LOAD: Ensure totalAmount and paymentMode are available
      // ---------------------------------------------------
      debugPrint('💰 FORCE LOAD: totalAmount = ${deliveryData.totalAmount}');
      debugPrint('💳 FORCE LOAD: paymentMode = ${deliveryData.paymentMode}');

      // If totalAmount is still null/zero, try calculating from invoices
      if (deliveryData.totalAmount == null || deliveryData.totalAmount == 0.0) {
        try {
          double calculatedTotal = 0.0;
          final invoicesList = deliveryData.invoices;

          if (invoicesList.isNotEmpty) {
            for (final invoice in invoicesList) {
              if (invoice.totalAmount != null && invoice.totalAmount! > 0) {
                calculatedTotal += invoice.totalAmount!;
              }
            }

            if (calculatedTotal > 0) {
              debugPrint(
                '💰 Calculated totalAmount from ${invoicesList.length} invoices: ₱${calculatedTotal.toStringAsFixed(2)}',
              );
              deliveryData.totalAmount = calculatedTotal;
              // Persist the calculated amount
              deliveryDataBox.put(deliveryData);
              debugPrint(
                '💾 Persisted calculated totalAmount to local storage',
              );
            }
          } else {
            debugPrint('⚠️ No invoices available to calculate total amount');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to calculate total amount: $e (non-blocking)');
        }
      }

      debugPrint('✅ DeliveryData fully loaded with all relations');
      debugPrint(
        '📊 FINAL CHECK: totalAmount = ${deliveryData.totalAmount}, paymentMode = ${deliveryData.paymentMode}',
      );
      return deliveryData;
    } catch (e) {
      debugPrint('❌ LOCAL: getDeliveryDataById error: $e');
      throw CacheException(message: e.toString());
    }
  }
}
