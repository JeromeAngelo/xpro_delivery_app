import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/data/model/delivery_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin CheckEndDeliverStatusImpl on DeliveryUpdateLocalBase {
  /// Checks if delivery has a valid end delivery status
  bool _hasValidEndDeliveryStatus(DeliveryDataModel delivery) {
    if (delivery.deliveryUpdates.isEmpty) return false;

    return delivery.deliveryUpdates.any((status) {
      final title = status.title?.toLowerCase().trim() ?? '';
      return title == 'end delivery' || title == 'mark as undelivered';
    });
  }

  /// Validates all delivery data entries have required status updates
  Future<DataMap> checkEndDeliverStatus(String tripId) async {
    try {
      debugPrint('🔍 LOCAL: Checking end delivery status for trip: $tripId');

      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint('⚠️ Trip not found in local DB for tripId: $tripId');
        return {
          'total': 0,
          'completed': 0,
          'pending': 0,
          'validDeliveries': [],
          'invalidDeliveries': [],
          'hasAllStatusUpdates': true,
        };
      }

      final deliverySet = <String, DeliveryDataModel>{};
      for (final d in trip.deliveryData) {
        final fullDD = deliveryDataBox.get(d.objectBoxId);
        if (fullDD != null) {
          deliverySet[fullDD.id ?? ""] = fullDD;
        }
      }

      if (deliverySet.isEmpty) {
        debugPrint('⚠️ No delivery data found for trip: ${trip.name}');
        return {
          'total': 0,
          'completed': 0,
          'pending': 0,
          'validDeliveries': [],
          'invalidDeliveries': [],
          'hasAllStatusUpdates': true,
        };
      }

      final allDeliveries = deliverySet.values.toList();
      final totalCustomers = allDeliveries.length;

      final validDeliveries = <String>[];
      final invalidDeliveries = <String>[];

      for (final delivery in allDeliveries) {
        if (_hasValidEndDeliveryStatus(delivery)) {
          validDeliveries.add(delivery.id ?? 'unknown');
        } else {
          invalidDeliveries.add(delivery.id ?? 'unknown');
        }
      }

      final completedDeliveries = validDeliveries.length;
      final hasAllStatusUpdates = invalidDeliveries.isEmpty;

      debugPrint('📊 LOCAL: Delivery Status Summary for Trip: $tripId');
      debugPrint('   - Total Customers: $totalCustomers');
      debugPrint(
        '   - Completed Deliveries (with status): $completedDeliveries',
      );
      debugPrint(
        '   - Pending Deliveries (missing status): ${totalCustomers - completedDeliveries}',
      );
      debugPrint('   - All deliveries have status: $hasAllStatusUpdates');

      if (invalidDeliveries.isNotEmpty) {
        debugPrint(
          '⚠️  Deliveries missing end status: ${invalidDeliveries.join(", ")}',
        );
      }

      return {
        'total': totalCustomers,
        'completed': completedDeliveries,
        'pending': totalCustomers - completedDeliveries,
        'validDeliveries': validDeliveries,
        'invalidDeliveries': invalidDeliveries,
        'hasAllStatusUpdates': hasAllStatusUpdates,
      };
    } catch (e, st) {
      debugPrint('❌ LOCAL: Error checking end delivery status - $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
