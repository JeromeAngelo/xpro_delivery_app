import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/model/cancelled_invoice_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/cancelled_invoices/data/datasources/local_datasource/cancelled_invoice_local_impl/cancelled_invoice_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin LoadCancelledInvoicesByIdImpl on CancelledInvoiceLocalBase {
  Future<CancelledInvoiceModel> loadCancelledInvoicesById(String id) async {
    try {
      debugPrint('📱 LOCAL: Fetching cancelled invoice by ID: $id');

      // 1️⃣ Query CancelledInvoice by PocketBase ID
      final query =
          cancelledInvoiceBox
              .query(CancelledInvoiceModel_.pocketbaseId.equals(id))
              .build();
      final cancelledInvoice = query.findFirst();
      query.close();

      if (cancelledInvoice == null) {
        debugPrint('⚠️ CancelledInvoice not found for ID: $id');
        throw const CacheException(
          message: 'Cancelled invoice not found in local storage',
        );
      }

      debugPrint('📦 CancelledInvoice found → ${cancelledInvoice.id}');

      // 2️⃣ Load DeliveryData (ToOne)
      final ddRef = cancelledInvoice.deliveryData.target;
      if (ddRef != null) {
        final fullDD = deliveryDataBox.get(ddRef.objectBoxId);
        if (fullDD != null) {
          cancelledInvoice.deliveryData.target = fullDD;
          cancelledInvoice.deliveryData.targetId = fullDD.objectBoxId;
          debugPrint('🚚 DeliveryData loaded → ${fullDD.id}');
        } else {
          debugPrint(
            '⚠️ DeliveryData reference exists but cannot load full object',
          );
        }
      } else {
        debugPrint('⚠️ No DeliveryData assigned');
      }

      // 3️⃣ Load Customer (ToOne)
      final customerRef = cancelledInvoice.customer.target;
      if (customerRef != null) {
        final fullCustomer = customerBox.get(customerRef.objectBoxId);
        if (fullCustomer != null) {
          cancelledInvoice.customer.target = fullCustomer;
          cancelledInvoice.customer.targetId = fullCustomer.objectBoxId;
          debugPrint('👤 Customer loaded → ${fullCustomer.name}');
        } else {
          debugPrint(
            '⚠️ Customer reference exists but cannot load full object',
          );
        }
      } else {
        debugPrint('⚠️ No customer assigned');
      }

      // 4️⃣ Load Primary Invoice (ToOne)
      final invoiceRef = cancelledInvoice.invoice.target;
      if (invoiceRef != null) {
        final fullInvoice = invoiceBox.get(invoiceRef.objectBoxId);
        if (fullInvoice != null) {
          cancelledInvoice.invoice.target = fullInvoice;
          cancelledInvoice.invoice.targetId = fullInvoice.objectBoxId;
          debugPrint('🧾 Invoice loaded → ${fullInvoice.id}');
        } else {
          debugPrint('⚠️ Invoice reference exists but cannot load full object');
        }
      } else {
        debugPrint('⚠️ No primary invoice assigned');
      }

      // 5️⃣ Load Invoices (ToMany)
      final invoices = cancelledInvoice.invoices;
      if (invoices.isNotEmpty) {
        for (var i = 0; i < invoices.length; i++) {
          final inv = invoices[i];
          final fullInv = invoiceBox.get(inv.objectBoxId);
          if (fullInv != null) {
            invoices[i] = fullInv;
            debugPrint('📄 Invoice loaded → ${fullInv.id}');
          } else {
            debugPrint('⚠️ Invoice not found → OBX ID: ${inv.objectBoxId}');
          }
        }
      } else {
        debugPrint('⚠️ No invoices for this cancelled invoice');
      }

      debugPrint('✅ CancelledInvoice fully loaded with expected relations');
      return cancelledInvoice;
    } catch (e) {
      debugPrint('❌ LOCAL: loadCancelledInvoicesById error: $e');
      throw CacheException(message: e.toString());
    }
  }
}
