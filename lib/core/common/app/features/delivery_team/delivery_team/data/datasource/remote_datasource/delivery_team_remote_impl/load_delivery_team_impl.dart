import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/remote_datasource/delivery_team_remote_impl/delivery_team_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import '../../../models/delivery_team_model.dart';

mixin LoadDeliveryTeamImpl on DeliveryTeamRemoteBase {
  Future<DeliveryTeamModel> loadDeliveryTeam(String tripId) async {
    try {
      debugPrint('🔄 Starting delivery team load with trip ID: $tripId');

      // Fetch delivery team by actual trip record ID
      final result = await pocketBaseClient
          .collection('deliveryTeam')
          .getFullList(
            expand: 'personels,tripTicket,deliveryVehicle',
            filter: 'tripTicket = "$tripId"', // using actual PB record ID
          );

      debugPrint('📡 Raw DeliveryTeam Result Count: ${result.length}');

      if (result.isEmpty) {
        debugPrint('⚠️ No delivery team found for trip ID: $tripId');
        throw const ServerException(
          message: 'No delivery team found for this trip',
          statusCode: '404',
        );
      }

      // RAW RECORD DUMP (before mapping)
      final record = result.first;

      debugPrint('📦 RAW DELIVERY TEAM RECORD (before mapping):');
      debugPrint('🆔 id: ${record.id}');
      debugPrint('📚 collectionName: ${record.collectionName}');
      debugPrint('👤 name: ${record.data['name']}');
      debugPrint('🚌 deliveryVehicle: ${record.data['deliveryVehicle']}');
      debugPrint('🧑‍🤝‍🧑 personels(list): ${record.data['personels']}');
      debugPrint('🧾 tripTicket: ${record.data['tripTicket']}');
      debugPrint('🔍 expanded keys: ${record.expand.keys.toList()}');

      // EXPANDED DATA RAW DUMP
      if (record.expand.isNotEmpty) {
        debugPrint('📦 EXPANDED DATA:');

        record.expand.forEach((key, value) {
          debugPrint('   ➜ $key: (${value.runtimeType})');

          for (var i = 0; i < value.length; i++) {
            debugPrint(
              '      [$i] → id: ${value[i].id}, name: ${value[i].data['name']}',
            );
          }
        });
      }

      // Process model
      final deliveryTeamModel = processDeliveryTeamRecord(record);

      debugPrint('✅ Delivery team data processed successfully');
      return deliveryTeamModel;
    } catch (e) {
      debugPrint('❌ Error in delivery team load: $e');
      throw ServerException(
        message: 'Failed to load delivery team: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
