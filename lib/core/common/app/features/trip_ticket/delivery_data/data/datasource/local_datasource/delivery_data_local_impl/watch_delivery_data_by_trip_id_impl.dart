import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';

mixin WatchDeliveryDataByTripIdImpl on DeliveryDataLocalBase {
  Stream<List<DeliveryDataModel>> watchDeliveryDataByTripId(String tripId) {
    debugPrint(
      '👀 LOCAL: Watching delivery data via Trip relation → tripId=$tripId',
    );

    // -------------------------------------------------------------
    // 1️⃣ Find trip ONCE
    // -------------------------------------------------------------
    final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
    final trip = tripQuery.findFirst();
    tripQuery.close();

    if (trip == null) {
      debugPrint('⚠️ Trip not found in local DB for tripId=$tripId');
      return Stream.value(<DeliveryDataModel>[]);
    }

    // -------------------------------------------------------------
    // 2️⃣ Watch DeliveryData box (react to any changes)
    // -------------------------------------------------------------
    return deliveryDataBox.query().watch(triggerImmediately: true).map((_) {
      try {
        final deliverySet = <String, DeliveryDataModel>{};

        // ---------------------------------------------------------
        // 3️⃣ Pull DeliveryData from Trip relation
        // ---------------------------------------------------------
        for (final d in trip.deliveryData) {
          final fullDD = deliveryDataBox.get(d.objectBoxId);
          if (fullDD != null) {
            deliverySet[fullDD.id ?? ""] = fullDD;
          }
        }

        if (deliverySet.isEmpty) {
          debugPrint(
            '⚠️ LOCAL: No delivery data linked to trip → ${trip.name}',
          );
          return <DeliveryDataModel>[];
        }

        final output = <DeliveryDataModel>[];

        // ---------------------------------------------------------
        // 4️⃣ Load nested relations (same as getDeliveryDataByTripId)
        // ---------------------------------------------------------
        for (final data in deliverySet.values) {
          // 👤 Customer
          final c = data.customer.target;
          if (c != null) {
            final fullCustomer = customerBox.get(c.objectBoxId);
            if (fullCustomer != null) {
              data.customer.target = fullCustomer;
              data.customer.targetId = fullCustomer.objectBoxId;
            }
          }

          // 🧾 Invoices
          final invoiceList = <InvoiceDataModel>[];
          for (final inv in data.invoices) {
            final fullInv = invoiceBox.get(inv.objectBoxId);
            if (fullInv != null) invoiceList.add(fullInv);
          }
          data.invoices
            ..clear()
            ..addAll(invoiceList);

          // 🧾 Invoices
          final invoiceItemsList = <InvoiceItemsModel>[];
          for (final inv in data.invoiceItems) {
            final fullInv = invoiceItemsBox.get(inv.objectBoxId);
            if (fullInv != null) invoiceItemsList.add(fullInv);
          }
          data.invoiceItems
            ..clear()
            ..addAll(invoiceItemsList);

          // 🔄 Delivery Updates
          final updatesList = <DeliveryUpdateModel>[];
          for (final u in data.deliveryUpdates) {
            final fullUpdate = deliveryUpdateBox.get(u.objectBoxId);
            if (fullUpdate != null) updatesList.add(fullUpdate);
          }

          // 🆕 DEDUPLICATION: Remove duplicate delivery updates
          final dedupUpdates = deduplicateDeliveryUpdates(updatesList);

          data.deliveryUpdates
            ..clear()
            ..addAll(dedupUpdates);

          output.add(data);
        }

        debugPrint(
          '✅ LOCAL: Stream emitted ${output.length} delivery items for trip=${trip.name}',
        );
        return output;
      } catch (e, st) {
        debugPrint('❌ watchDeliveryDataByTripId ERROR: $e\n$st');
        return <DeliveryDataModel>[];
      }
    });
  }
}
