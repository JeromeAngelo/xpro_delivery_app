import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin ForceLoadCancelledInvoicesByTripIdImpl on CancelledInvoiceLocalBase {
  Future<List<CancelledInvoiceModel>> forceLoadCancelledInvoicesByTripId(
    String tripId,
  ) async {
    try {
      debugPrint(
        '🔁 LOCAL: Force loading cancelled invoices for tripId=$tripId',
      );

      // 1️⃣ Load cancelled invoices using the existing loader
      final cancelledInvoices = await loadCancelledInvoicesByTripId(tripId);

      if (cancelledInvoices.isEmpty) {
        debugPrint('🔁 LOCAL: No cancelled invoices found for tripId=$tripId');
        return [];
      }

      // 2️⃣ For each cancelled invoice, re-query by its own ID
      for (final invoice in cancelledInvoices) {
        try {
          final invoiceId = invoice.id;
          if (invoiceId == null || invoiceId.isEmpty) continue;

          // Re-query cancelledInvoiceBox by this invoice's ID
          final q =
              cancelledInvoiceBox
                  .query(CancelledInvoiceModel_.id.equals(invoiceId))
                  .build();
          final found = q.find();
          q.close();

          if (found.isEmpty) {
            debugPrint(
              '⚠️ LOCAL: No rows found for cancelled invoice OBX=${invoice.objectBoxId}, ID=$invoiceId',
            );
            continue;
          }

          // Sort by preferred timestamp
          found.sort((a, b) {
            final ta = a.lastLocalUpdatedAt ?? a.updated ?? a.created;
            final tb = b.lastLocalUpdatedAt ?? b.updated ?? b.created;

            if (ta == null && tb == null) return 0;
            if (ta == null) return -1;
            if (tb == null) return 1;
            return ta.compareTo(tb);
          });

          // Reattach to Trip (ToMany normalization) for UI watchers
          final trip = invoice.trip.target;
          if (trip != null) {
            // Remove old instance(s) and add freshly loaded invoice
            trip.cancelledInvoices.removeWhere((e) => e.id == invoiceId);
            trip.cancelledInvoices.addAll(found);

            // Persist parent → notifies listeners
            tripBox.put(trip);

            debugPrint(
              '🔁 LOCAL: Trip ${trip.name} refreshed with ${found.length} instance(s) of cancelled invoice ID=$invoiceId',
            );
          } else {
            debugPrint('⚠️ LOCAL: Invoice ID=$invoiceId has no linked trip');
          }

          // Persist the invoice(s) themselves
          cancelledInvoiceBox.putMany(found);

          debugPrint(
            '🔁 LOCAL: Cancelled invoice ID=$invoiceId refreshed successfully',
          );
        } catch (e) {
          debugPrint(
            '❌ LOCAL: Failed to reload cancelled invoice OBX=${invoice.objectBoxId}: $e',
          );
        }
      }

      debugPrint(
        '🔁 LOCAL: Force load cancelled invoices complete for tripId=$tripId',
      );

      return cancelledInvoices;
    } catch (e, st) {
      debugPrint('❌ forceLoadCancelledInvoicesByTripId ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
