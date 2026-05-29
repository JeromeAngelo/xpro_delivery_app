import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../../../../../enums/invoice_status.dart';

mixin SetInvoiceIntoUnloadingImpl on DeliveryDataLocalBase {
  Future<DeliveryDataModel> setInvoiceIntoUnloading(
    String deliveryDataId,
  ) async {
    try {
      final id = deliveryDataId.trim();
      debugPrint(
        '🔄 LOCAL: Setting invoice to unloading for deliveryDataId=$id',
      );

      // -------------------------------------------------------------
      // 1️⃣ Find DeliveryData (prefer pocketbaseId)
      // -------------------------------------------------------------
      DeliveryDataModel? delivery;

      final q1 =
          deliveryDataBox
              .query(DeliveryDataModel_.pocketbaseId.equals(id))
              .build();
      delivery = q1.findFirst();
      q1.close();

      if (delivery == null) {
        final q2 =
            deliveryDataBox.query(DeliveryDataModel_.id.equals(id)).build();
        delivery = q2.findFirst();
        q2.close();
      }

      if (delivery == null) {
        debugPrint('⚠️ LOCAL: DeliveryData not found for id=$id');
        throw const CacheException(
          message: 'DeliveryData not found in local DB',
        );
      }

      debugPrint(
        '📦 LOCAL: DeliveryData found → OBX=${delivery.objectBoxId}, PB=${delivery.pocketbaseId}, current isUnloading=${delivery.isUnloading}',
      );

      // -------------------------------------------------------------
      // 2️⃣ Update field
      // -------------------------------------------------------------
      delivery.isUnloading = true;
      delivery.invoiceStatus = InvoiceStatus.unloading;

      // OPTIONAL (only if your model has updated field)
      try {
        delivery.updated = DateTime.now();
      } catch (_) {
        // ignore if model doesn't have updated
      }

      // -------------------------------------------------------------
      // 3️⃣ Persist
      // -------------------------------------------------------------
      final savedId = deliveryDataBox.put(delivery);

      debugPrint(
        '✅ LOCAL: Successfully set isUnloading=true for DeliveryData '
        'OBX=$savedId, PB=${delivery.pocketbaseId}',
      );

      // -------------------------------------------------------------
      // 4️⃣ Reload relations (optional but consistent with your pattern)
      // -------------------------------------------------------------
      // Customer
      final cust = delivery.customer.target;
      if (cust != null) {
        final fullCustomer = customerBox.get(cust.objectBoxId);
        if (fullCustomer != null) {
          delivery.customer.target = fullCustomer;
          delivery.customer.targetId = fullCustomer.objectBoxId;
        }
      }

      // Invoices
      for (final inv in delivery.invoices) {
        invoiceBox.get(inv.objectBoxId);
      }

      // Updates
      for (final up in delivery.deliveryUpdates) {
        deliveryUpdateBox.get(up.objectBoxId);
      }

      // Invoice Items
      for (final item in delivery.invoiceItems) {
        invoiceItemsBox.get(item.objectBoxId);
      }

      debugPrint(
        '📦 LOCAL: Final DeliveryData state → '
        'isUnloading=${delivery.isUnloading}, '
        'invoices=${delivery.invoices.length}, '
        'updates=${delivery.deliveryUpdates.length}, '
        'items=${delivery.invoiceItems.length}',
      );

      return delivery;
    } catch (e, st) {
      debugPrint('❌ LOCAL setInvoiceIntoUnloading ERROR: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
