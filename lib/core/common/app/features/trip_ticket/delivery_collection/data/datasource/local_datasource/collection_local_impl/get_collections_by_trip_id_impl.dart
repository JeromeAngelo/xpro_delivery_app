import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/model/collection_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_collection/data/datasource/local_datasource/collection_local_impl/collection_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetCollectionsByTripIdImpl on CollectionLocalBase {
  Future<List<CollectionModel>> getCollectionsByTripId(String tripId) async {
    try {
      debugPrint("📥 LOCAL getCollectionsByTripId() tripId = $tripId");

      // -------------------------------------------------------------
      // 1️⃣ Find the trip first
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint("⚠️ Trip not found in local DB for tripId: $tripId");
        return [];
      }

      // -------------------------------------------------------------
      // 2️⃣ Get Collections linked to this trip
      // -------------------------------------------------------------
      final collectionSet = <String, CollectionModel>{}; // dedupe by PB ID

      for (final c in trip.deliveryCollection) {
        final fullCollection = collectionBox.get(c.objectBoxId);
        if (fullCollection != null) {
          collectionSet[fullCollection.id ?? ""] = fullCollection;
        }
      }

      if (collectionSet.isEmpty) {
        debugPrint("⚠️ No collections found for trip: ${trip.name}");
        return [];
      }

      final output = <CollectionModel>[];

      // -------------------------------------------------------------
      // 3️⃣ Load nested relations safely
      // -------------------------------------------------------------
      for (final collection in collectionSet.values) {
        debugPrint("📄 Loading relations for Collection → ${collection.id}");

        // 👤 Customer
        final customer = collection.customer.target;
        if (customer != null) {
          final fullCustomer = customerBox.get(customer.objectBoxId);
          if (fullCustomer != null) {
            collection.customer.target = fullCustomer;
            debugPrint("👤 Customer loaded → ${fullCustomer.name}");
          }
        }

        // 🚚 Delivery Data
        final dd = collection.deliveryData.target;
        if (dd != null) {
          final fullDD = deliveryDataBox.get(dd.objectBoxId);
          if (fullDD != null) {
            collection.deliveryData.target = fullDD;
            debugPrint("🚚 DeliveryData loaded → ${fullDD.id}");
          }
        }

        // 🧾 Invoices
        final invoiceList = <InvoiceDataModel>[];
        for (final inv in collection.invoices) {
          final fullInv = invoiceBox.get(inv.objectBoxId);
          if (fullInv != null) invoiceList.add(fullInv);
        }
        collection.invoices
          ..clear()
          ..addAll(invoiceList);

        // 🧾 Delivery Receipt (optional)
        final receipt = collection.deliveryReceipt.target;
        if (receipt != null) {
          final fullReceipt = deliveryReceiptBox.get(receipt.objectBoxId);
          if (fullReceipt != null) {
            collection.deliveryReceipt.target = fullReceipt;
          }
        }

        debugPrint(
          "✅ Collection ready → ${collection.id} "
          "Invoices: ${collection.invoices.length}",
        );

        output.add(collection);
      }

      debugPrint(
        "📦 Found ${output.length} collections linked to trip: ${trip.name}",
      );

      return output;
    } catch (e, st) {
      debugPrint("❌ getCollectionsByTripId ERROR: $e\n$st");
      throw CacheException(message: e.toString());
    }
  }
}
