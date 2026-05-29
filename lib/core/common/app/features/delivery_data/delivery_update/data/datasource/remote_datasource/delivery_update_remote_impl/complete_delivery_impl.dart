import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/remote_datasource/delivery_update_remote_impl/delivery_update_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CompleteDeliveryImpl on DeliveryUpdateRemoteBase {
  Future<void> completeDelivery(DeliveryDataEntity deliveryData) async {
    try {
      debugPrint(
        '🔄 Processing delivery completion for delivery data: ${deliveryData.id}',
      );

      // Extract delivery data ID
      final deliveryDataId = deliveryData.id;
      if (deliveryDataId == null || deliveryDataId.isEmpty) {
        throw const ServerException(
          message: 'Invalid delivery data ID',
          statusCode: '400',
        );
      }

      // Get trip ID from delivery data
      final tripId = deliveryData.trip.target?.id;
      if (tripId == null) {
        throw const ServerException(
          message: 'Trip ID not found for delivery data',
          statusCode: '404',
        );
      }

      debugPrint('🚛 Found trip ID: $tripId');

      // Step 1: Add "End Delivery" status to delivery updates
      debugPrint('📝 Adding "End Delivery" status to delivery updates');

      // Get the "End Delivery" status from deliveryStatusChoices
      final endDeliveryStatus = await pocketBaseClient
          .collection('deliveryStatusChoices')
          .getFirstListItem('title = "End Delivery"');

      // Create delivery update with "End Delivery" status
      final currentTime = DateTime.now().toUtc().toIso8601String();
      final deliveryUpdateRecord = await pocketBaseClient
          .collection('deliveryUpdate')
          .create(
            body: {
              'deliveryData': deliveryDataId,
              'status': endDeliveryStatus.id,
              'title': endDeliveryStatus.data['title'],
              'subtitle': endDeliveryStatus.data['subtitle'],
              'created': currentTime,
              'time': currentTime,
              'isAssigned': true,
            },
          );

      debugPrint('✅ Created "End Delivery" update: ${deliveryUpdateRecord.id}');

      // Update delivery data with the new delivery update
      await pocketBaseClient
          .collection('deliveryData')
          .update(
            deliveryDataId,
            body: {
              'invoiceStatus': 'delivered',
              'deliveryUpdates+': [deliveryUpdateRecord.id],
            },
          );

      debugPrint('✅ Updated delivery data with "End Delivery" status');

      // Step 2: Find delivery receipt for this delivery data
      debugPrint(
        '🔍 Looking for delivery receipt with delivery data: $deliveryDataId',
      );

      final deliveryReceiptRecords = await pocketBaseClient
          .collection('deliveryReceipt')
          .getList(filter: 'deliveryData = "$deliveryDataId"');

      if (deliveryReceiptRecords.items.isEmpty) {
        throw const ServerException(
          message: 'Delivery receipt not found for this delivery data',
          statusCode: '404',
        );
      }

      final deliveryReceiptRecord = deliveryReceiptRecords.items.first;
      debugPrint('✅ Found delivery receipt: ${deliveryReceiptRecord.id}');

      // Step 3: Extract customer and invoices IDs from delivery data
      debugPrint('🔍 Extracting customer and invoices data from delivery data');

      final customerId = deliveryData.customer.target?.id;
      final invoices = deliveryData.invoices;
      final invoiceIds = invoices.map((invoice) => invoice.id).toList();

      debugPrint('👤 Customer ID: $customerId');
      debugPrint('📄 Invoice IDs: $invoiceIds');
      debugPrint('📦 Number of invoices: ${invoices.length}');

      if (customerId == null || customerId.isEmpty) {
        throw const ServerException(
          message: 'Customer ID not found in delivery data',
          statusCode: '404',
        );
      }

      if (invoiceIds.isEmpty) {
        throw const ServerException(
          message: 'No invoices found in delivery data',
          statusCode: '404',
        );
      }

      // Step 4: Create record in deliveryCollection with customer and invoices
      debugPrint(
        '📝 Creating delivery collection record with customer and invoices',
      );

      final deliveryCollectionData = {
        'deliveryData': deliveryDataId,
        'trip': tripId,
        'deliveryReceipt': deliveryReceiptRecord.id,
        'customer': customerId,
        'invoice':
            invoiceIds.isNotEmpty
                ? invoiceIds.first
                : null, // Primary invoice for backward compatibility
        'invoices': invoiceIds, // Multiple invoices
        'invoiceStatus': 'completed',
        'completedAt': DateTime.now().toUtc().toIso8601String(),
        'status': 'completed',
      };

      debugPrint('📋 Delivery collection data:');
      debugPrint('   - Delivery Data: $deliveryDataId');
      debugPrint('   - Trip: $tripId');
      debugPrint('   - Delivery Receipt: ${deliveryReceiptRecord.id}');
      debugPrint('   - Customer: $customerId');
      debugPrint(
        '   - Primary Invoice: ${invoiceIds.isNotEmpty ? invoiceIds.first : "null"}',
      );
      debugPrint('   - All Invoices: $invoiceIds');
      debugPrint('   - Status: completed');

      final deliveryCollectionRecord = await pocketBaseClient
          .collection('deliveryCollection')
          .create(body: deliveryCollectionData);

      debugPrint(
        '✅ Created delivery collection record: ${deliveryCollectionRecord.id}',
      );

      // Update user performance - increment successful deliveries
      try {
        debugPrint('📊 Updating user performance for successful delivery');

        // Get user ID from trip ticket
        final tripTicketRecord = await pocketBaseClient
            .collection('tripticket')
            .getOne(tripId);

        final userId = tripTicketRecord.data['user'];
        if (userId != null && userId.isNotEmpty) {
          debugPrint('👤 Found user ID from trip: $userId');

          // Find user performance record
          final userPerformanceRecords = await pocketBaseClient
              .collection('userPerformance')
              .getList(filter: 'user = "$userId"');

          if (userPerformanceRecords.items.isNotEmpty) {
            // Update existing record
            final userPerformanceRecord = userPerformanceRecords.items.first;
            final currentSuccessfulDeliveries =
                userPerformanceRecord.data['successfulDeliveries'] ?? 0;
            final newSuccessfulDeliveries =
                (currentSuccessfulDeliveries is String)
                    ? (int.tryParse(currentSuccessfulDeliveries) ?? 0) + 1
                    : (currentSuccessfulDeliveries as int) + 1;

            debugPrint(
              '📈 Incrementing successful deliveries: $currentSuccessfulDeliveries → $newSuccessfulDeliveries',
            );

            // Calculate new success rate
            final totalDeliveries =
                userPerformanceRecord.data['totalDeliveries'] ?? 0;
            final totalDelCount =
                (totalDeliveries is String)
                    ? (int.tryParse(totalDeliveries) ?? 0)
                    : (totalDeliveries as int);

            final successRate =
                totalDelCount > 0
                    ? (newSuccessfulDeliveries / totalDelCount * 100)
                    : 0.0;

            await pocketBaseClient
                .collection('userPerformance')
                .update(
                  userPerformanceRecord.id,
                  body: {
                    'successfulDeliveries': newSuccessfulDeliveries.toString(),
                    'successRate': successRate.toStringAsFixed(2),
                    'updated': DateTime.now().toUtc().toIso8601String(),
                  },
                );

            debugPrint(
              '✅ User performance updated - Successful deliveries: $newSuccessfulDeliveries, Success rate: ${successRate.toStringAsFixed(2)}%',
            );
          } else {
            debugPrint('⚠️ No user performance record found for user: $userId');
          }
        } else {
          debugPrint('⚠️ No user ID found in trip ticket');
        }
      } catch (e) {
        debugPrint(
          '⚠️ Failed to update user performance for successful delivery: $e',
        );
        // Don't throw error here as delivery completion should still succeed
      }

      // Step 5: Update delivery team stats
      debugPrint('🔄 Updating delivery team statistics');

      // Get delivery team using trip ID
      final deliveryTeamRecords = await pocketBaseClient
          .collection('deliveryTeam')
          .getList(filter: 'tripTicket = "$tripId"');

      if (deliveryTeamRecords.items.isEmpty) {
        throw const ServerException(
          message: 'Delivery team not found for this trip',
          statusCode: '404',
        );
      }

      final deliveryTeamRecord = deliveryTeamRecords.items.first;
      debugPrint('✅ Found delivery team: ${deliveryTeamRecord.id}');

      // Calculate new stats
      final currentActiveDeliveries =
          int.tryParse(
            deliveryTeamRecord.data['activeDeliveries']?.toString() ?? '0',
          ) ??
          0;

      final currentTotalDelivered =
          int.tryParse(
            deliveryTeamRecord.data['totalDelivered']?.toString() ?? '0',
          ) ??
          0;

      final newActiveDeliveries =
          (currentActiveDeliveries - 1).clamp(0, double.infinity).toInt();
      final newTotalDelivered = currentTotalDelivered + 1;

      debugPrint('📊 Delivery team stats update:');
      debugPrint(
        '   - Active deliveries: $currentActiveDeliveries -> $newActiveDeliveries',
      );
      debugPrint(
        '   - Total delivered: $currentTotalDelivered -> $newTotalDelivered',
      );

      // Update delivery team stats
      await pocketBaseClient
          .collection('deliveryTeam')
          .update(
            deliveryTeamRecord.id,
            body: {
              'activeDeliveries': newActiveDeliveries.toString(),
              'totalDelivered': newTotalDelivered.toString(),
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Updated delivery team statistics');

      // Step 6: Update trip ticket with completed delivery collection
      debugPrint('🔄 Updating trip ticket with completed delivery');

      await pocketBaseClient
          .collection('tripticket')
          .update(
            tripId,
            body: {
              'deliveryCollection+': [deliveryCollectionRecord.id],
              'updated': DateTime.now().toUtc().toIso8601String(),
            },
          );

      debugPrint('✅ Updated trip ticket with delivery collection');
      debugPrint(
        '🎉 Successfully completed delivery process with customer and invoice data',
      );
    } catch (e) {
      debugPrint('❌ Failed to complete delivery: ${e.toString()}');
      throw ServerException(
        message: 'Failed to complete delivery: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
