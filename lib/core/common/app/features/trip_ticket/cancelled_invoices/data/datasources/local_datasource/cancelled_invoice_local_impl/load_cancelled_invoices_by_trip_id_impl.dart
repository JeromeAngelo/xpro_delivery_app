import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin LoadCancelledInvoicesByTripIdImpl on CancelledInvoiceLocalBase {
  @override
  Future<List<CancelledInvoiceModel>> loadCancelledInvoicesByTripId(
    String tripId,
  ) async {
    try {
      debugPrint("📥 LOCAL loadCancelledInvoicesByTripId() tripId = $tripId");

      // 1️⃣ Find the trip first
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint("⚠️ Trip not found in local DB for tripId: $tripId");
        return [];
      }
      await cleanCancelledInvoices();
      // 2️⃣ Get CancelledInvoices linked to this trip
      final cancelledSet = <String, CancelledInvoiceModel>{};

      for (final ci in trip.cancelledInvoices) {
        final fullCI = cancelledInvoiceBox.get(ci.objectBoxId);
        if (fullCI != null) {
          cancelledSet[fullCI.id ?? ""] = fullCI;
        }
      }

      if (cancelledSet.isEmpty) {
        debugPrint("⚠️ No cancelled invoices found for trip: ${trip.name}");
        return [];
      }

      final output = <CancelledInvoiceModel>[];

      // 3️⃣ Load nested relations safely
      for (final cancelled in cancelledSet.values) {
        debugPrint(
          "📄 Loading relations for CancelledInvoice → ${cancelled.id}",
        );

        // 🚚 DeliveryData
        final dd = cancelled.deliveryData.target;
        if (dd != null) {
          final fullDD = deliveryDataBox.get(dd.objectBoxId);
          if (fullDD != null) {
            cancelled.deliveryData.target = fullDD;
            cancelled.deliveryData.targetId = fullDD.objectBoxId;
            debugPrint("🚚 DeliveryData loaded → ${fullDD.id}");
          }
        }

        // 👤 Customer
        final customer = cancelled.customer.target;
        if (customer != null) {
          final fullCustomer = customerBox.get(customer.objectBoxId);
          if (fullCustomer != null) {
            cancelled.customer.target = fullCustomer;
            cancelled.customer.targetId = fullCustomer.objectBoxId;
            debugPrint("👤 Customer loaded → ${fullCustomer.name}");
          }
        }

        // 🧾 Primary Invoice
        final invoice = cancelled.invoice.target;
        if (invoice != null) {
          final fullInvoice = invoiceBox.get(invoice.objectBoxId);
          if (fullInvoice != null) {
            cancelled.invoice.target = fullInvoice;
            cancelled.invoice.targetId = fullInvoice.objectBoxId;
            debugPrint("🧾 Invoice loaded → ${fullInvoice.id}");
          }
        }

        // 📑 Multiple Invoices
        final invoiceList = <InvoiceDataModel>[];
        for (final inv in cancelled.invoices) {
          final fullInv = invoiceBox.get(inv.objectBoxId);
          if (fullInv != null) invoiceList.add(fullInv);
        }
        cancelled.invoices
          ..clear()
          ..addAll(invoiceList);

        debugPrint(
          "✅ CancelledInvoice ready → ${cancelled.id} "
          "(${cancelled.invoices.length} invoices)",
        );

        output.add(cancelled);
      }

      debugPrint(
        "📦 Found ${output.length} cancelled invoices linked to trip: ${trip.name}",
      );
      return output;
    } catch (e, st) {
      debugPrint("❌ loadCancelledInvoicesByTripId ERROR: $e\n$st");
      throw CacheException(message: e.toString());
    }
  }
}
