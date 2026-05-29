import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetDeliveryDataByTripIdImpl on DeliveryDataLocalBase {
  @override
  Future<List<DeliveryDataModel>> getDeliveryDataByTripId(String tripId) async {
    try {
      final id = tripId.trim();
      debugPrint("📥 LOCAL getDeliveryDataByTripId() tripId = $id");

      // -------------------------------------------------------------
      // 1️⃣ Find trip (prefer pocketbaseId)
      // -------------------------------------------------------------
      TripModel? trip;

      final q1 = tripBox.query(TripModel_.pocketbaseId.equals(id)).build();
      trip = q1.findFirst();
      q1.close();

      if (trip == null) {
        final q2 = tripBox.query(TripModel_.id.equals(id)).build();
        trip = q2.findFirst();
        q2.close();
      }

      if (trip == null) {
        debugPrint("⚠️ Trip not found in local DB for tripId: $id");
        return [];
      }

      // -------------------------------------------------------------
      // 2️⃣ Read deliveryData linked to trip (dedupe by PB id)
      // -------------------------------------------------------------
      final Map<String, DeliveryDataModel> unique = {};

      // NOTE: trip.deliveryData typically returns usable entities already
      for (final d in trip.deliveryData) {
        final key = ((d.pocketbaseId)).trim();
        if (key.isEmpty) continue;
        unique[key] = d;
      }

      if (unique.isEmpty) {
        debugPrint("⚠️ No delivery data found for trip: ${trip.name}");
        return [];
      }

      final output = <DeliveryDataModel>[];

      // -------------------------------------------------------------
      // 3️⃣ Load nested relations fully for each delivery data
      // -------------------------------------------------------------
      for (final data in unique.values) {
        // 👤 Customer (ToOne)
        final cust = data.customer.target;
        if (cust != null) {
          final fullCustomer = customerBox.get(cust.objectBoxId);
          if (fullCustomer != null) {
            data.customer.target = fullCustomer;
            data.customer.targetId = fullCustomer.objectBoxId;
          }
        }

        // 🧾 Invoice (ToOne)
        final invRef = data.invoice.target;
        if (invRef != null) {
          final fullInvoice = invoiceBox.get(invRef.objectBoxId);
          if (fullInvoice != null) {
            data.invoice.target = fullInvoice;
            data.invoice.targetId = fullInvoice.objectBoxId;
          }
        }

        // 📄 Invoices (ToMany)
        final invoicesList = data.invoices;
        if (invoicesList.isNotEmpty) {
          for (var i = 0; i < invoicesList.length; i++) {
            final fullInvoice = invoiceBox.get(invoicesList[i].objectBoxId);
            if (fullInvoice != null) {
              invoicesList[i] = fullInvoice;
            }
          }
        }

        // 📄 Invoice Items (ToMany)
        final invoiceItemsList = data.invoiceItems;
        if (invoiceItemsList.isNotEmpty) {
          for (var i = 0; i < invoiceItemsList.length; i++) {
            final fullItem = invoiceItemsBox.get(
              invoiceItemsList[i].objectBoxId,
            );
            if (fullItem != null) {
              invoiceItemsList[i] = fullItem;
            }
          }
        }

        // 🚛 Trip (ToOne)
        final tripRef = data.trip.target;
        if (tripRef != null) {
          final fullTrip = tripBox.get(tripRef.objectBoxId);
          if (fullTrip != null) {
            data.trip.target = fullTrip;
            data.trip.targetId = fullTrip.objectBoxId;
          }
        }

        // 🔄 Delivery Updates (ToMany)
        final updates = data.deliveryUpdates;
        if (updates.isNotEmpty) {
          for (var i = 0; i < updates.length; i++) {
            final fullUpdate = deliveryUpdateBox.get(updates[i].objectBoxId);
            if (fullUpdate != null) {
              updates[i] = fullUpdate;
            }
          }

          // Deduplicate delivery updates
          final dedupList = deduplicateDeliveryUpdates(updates.toList());
          if (dedupList.length < updates.length) {
            data.deliveryUpdates
              ..clear()
              ..addAll(dedupList);
            deliveryDataBox.put(data);
          }
        }

        output.add(data);
      }

      debugPrint(
        "📦 Found ${output.length} delivery items linked to trip: ${trip.name}",
      );
      return output;
    } catch (e, st) {
      debugPrint("❌ getDeliveryDataByTripId ERROR: $e\n$st");
      throw CacheException(message: e.toString());
    }
  }
}
