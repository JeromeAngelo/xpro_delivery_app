import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/datasource/local_datasource/delivery_data_local_impl/delivery_data_local_base.dart';

mixin WatchAllDeliveryDataImpl on DeliveryDataLocalBase {
  Stream<List<DeliveryDataModel>> watchAllDeliveryData() async* {
    debugPrint('👀 LOCAL: Watching ALL delivery data');

    final query = deliveryDataBox.query().build();

    await for (final _ in query.stream()) {
      try {
        final allDeliveryData = deliveryDataBox.getAll();
        if (allDeliveryData.isEmpty) {
          debugPrint('⚠️ LOCAL: No delivery data found');
          yield <DeliveryDataModel>[];
          continue;
        }

        final output = <DeliveryDataModel>[];
        final seenIds = <String>{};
        for (final data in allDeliveryData) {
          if (seenIds.contains(data.id)) continue; // skip duplicates
          seenIds.add(data.id ?? '');

          // ------------------------- Customer -------------------------
          final customerRef = data.customer.target;
          if (customerRef != null) {
            final fullCustomer = customerBox.get(customerRef.objectBoxId);
            if (fullCustomer != null) {
              data.customer.target = fullCustomer;
              data.customer.targetId = fullCustomer.objectBoxId;
            }
          }

          // ------------------------- Invoices -------------------------
          if (data.invoices.isNotEmpty) {
            final invoicesList =
                data.invoices.map((inv) {
                  return invoiceBox.get(inv.objectBoxId) ?? inv;
                }).toList();
            data.invoices
              ..clear()
              ..addAll(invoicesList);
          }

          // ---------------------- Delivery Updates ---------------------
          if (data.deliveryUpdates.isNotEmpty) {
            final updatesList =
                data.deliveryUpdates.map((upd) {
                  return deliveryUpdateBox.get(upd.objectBoxId) ?? upd;
                }).toList();
            data.deliveryUpdates
              ..clear()
              ..addAll(updatesList);
          }

          output.add(data);
        }

        debugPrint('✅ LOCAL: Stream emitted ${output.length} delivery items');
        yield output;
      } catch (e, st) {
        debugPrint('❌ watchAllDeliveryData ERROR: $e\n$st');
        yield <DeliveryDataModel>[];
      }
    }
  }
}
