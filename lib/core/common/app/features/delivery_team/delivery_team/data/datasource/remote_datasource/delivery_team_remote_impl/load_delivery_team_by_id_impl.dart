import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/remote_datasource/delivery_team_remote_impl/delivery_team_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import '../../../models/delivery_team_model.dart';

mixin LoadDeliveryTeamByIdImpl on DeliveryTeamRemoteBase {
  Future<DeliveryTeamModel> loadDeliveryTeamById(String deliveryTeamId) async {
    try {
      debugPrint('📍 Fetching data for delivery team: $deliveryTeamId');

      final record = await pocketBaseClient
          .collection('deliveryTeam')
          .getOne(
            deliveryTeamId,
            expand: 'personels,tripTicket,deliveryVehicle, checklist',
          );

      // FIXED: Process the record like delivery data datasource
      final deliveryTeamModel = processDeliveryTeamRecord(record);

      debugPrint('✅ Delivery team data processed successfully');

      return deliveryTeamModel;
    } catch (e) {
      debugPrint('❌ Error fetching delivery team by ID: $e');
      throw ServerException(
        message: 'Failed to load delivery team by ID: ${e.toString()}',
        statusCode: '500',
      );
    }
  }
}
