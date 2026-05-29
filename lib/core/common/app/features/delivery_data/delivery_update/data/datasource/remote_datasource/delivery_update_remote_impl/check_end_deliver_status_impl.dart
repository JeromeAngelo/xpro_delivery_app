import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

mixin CheckEndDeliverStatusImpl on DeliveryUpdateRemoteBase {
  Future<DataMap> checkEndDeliverStatus(String tripId) async {
    try {
      debugPrint('🔍 Checking end delivery status for trip: $tripId');

      // Extract trip ID if received as JSON
      String actualTripId;
      if (tripId.startsWith('{')) {
        final tripData = jsonDecode(tripId);
        actualTripId = tripData['id'];
      } else {
        actualTripId = tripId;
      }

      // Get customers using trip ID
      final customerRecords = await pocketBaseClient
          .collection('deliveryData')
          .getFullList(
            filter: 'trip = "$actualTripId"',
            expand: 'deliveryUpdates',
          );

      final totalCustomers = customerRecords.length;
      debugPrint('📦 Total customers in trip: $totalCustomers');

      final completedDeliveries =
          customerRecords.where((customer) {
            final deliveryStatuses =
                customer.expand['deliveryUpdates'] as List? ?? [];
            final hasEndDelivery = deliveryStatuses.any((status) {
              final title = status.data['title'].toString().toLowerCase();
              if (title == 'end delivery') {
                debugPrint(
                  '   ✅ Customer ${customer.data['storeName']} has End Delivery status',
                );
                return true;
              }
              if (title == 'mark as undelivered') {
                debugPrint(
                  '   ⚠️ Customer ${customer.data['storeName']} is marked Undelivered',
                );
                return true;
              }
              return false;
            });
            return hasEndDelivery;
          }).length;

      debugPrint('📊 Delivery Status Summary:');
      debugPrint('   - Total Customers: $totalCustomers');
      debugPrint('   - Completed Deliveries: $completedDeliveries');
      debugPrint(
        '   - Pending Deliveries: ${totalCustomers - completedDeliveries}',
      );

      return {
        'total': totalCustomers,
        'completed': completedDeliveries,
        'pending': totalCustomers - completedDeliveries,
      };
    } catch (e) {
      debugPrint('❌ Error checking end delivery status: $e');
      throw ServerException(
        message: 'Failed to check end delivery status: $e',
        statusCode: '500',
      );
    }
  }
}
