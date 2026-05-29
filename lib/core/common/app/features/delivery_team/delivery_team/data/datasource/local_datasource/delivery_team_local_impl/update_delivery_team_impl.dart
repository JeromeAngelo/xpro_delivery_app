import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/local_datasource/delivery_team_local_impl/delivery_team_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin UpdateDeliveryTeamImpl on DeliveryTeamLocalBase {
  Future<void> updateDeliveryTeam(DeliveryTeamModel team) async {
    try {
      debugPrint('💾 LOCAL: Updating delivery team: ${team.id}');
      deliveryTeamBox.put(team);
      cachedDeliveryTeam = team;
      debugPrint('✅ LOCAL: Team updated successfully');
    } catch (e) {
      debugPrint('❌ Update failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
