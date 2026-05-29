import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/local_datasource/delivery_team_local_impl/delivery_team_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin LoadDeliveryTeamByIdImpl on DeliveryTeamLocalBase {
  Future<DeliveryTeamModel> loadDeliveryTeamById(String deliveryTeamId) async {
    try {
      debugPrint('🔍 LOCAL: Loading delivery team by ID: $deliveryTeamId');

      final team =
          deliveryTeamBox
              .query(DeliveryTeamModel_.pocketbaseId.equals(deliveryTeamId))
              .build()
              .findFirst();

      if (team == null) {
        throw const CacheException(message: 'Delivery team not found');
      }

      debugPrint('✅ LOCAL: Team found with ID: ${team.id}');
      return team;
    } catch (e) {
      debugPrint('❌ Load failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
