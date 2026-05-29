import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/local_datasource/delivery_team_local_impl/delivery_team_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin AssignDeliveryTeamToTripImpl on DeliveryTeamLocalBase {
  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  }) async {
    try {
      debugPrint('📱 LOCAL: Assigning delivery team to trip');

      final query =
          deliveryTeamBox
              .query(DeliveryTeamModel_.pocketbaseId.equals(deliveryTeamId))
              .build();
      final deliveryTeam = query.findFirst();
      query.close();

      if (deliveryTeam == null) {
        throw const CacheException(
          message: 'Delivery team not found in local storage',
        );
      }

      deliveryTeam.tripId = tripId;
      deliveryTeamBox.put(deliveryTeam);

      debugPrint('✅ LOCAL: Delivery team assigned successfully');
      return deliveryTeam;
    } catch (e) {
      debugPrint('❌ LOCAL: Assignment failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
