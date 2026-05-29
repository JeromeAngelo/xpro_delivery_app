import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/local_datasource/delivery_team_local_impl/delivery_team_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CacheDeliveryTeamImpl on DeliveryTeamLocalBase {
  Future<void> cacheDeliveryTeam(DeliveryTeamModel team) async {
    try {
      debugPrint('💾 LOCAL: Caching delivery team');

      // Create a deep copy of the team data
      final teamCopy = DeliveryTeamModel(
        id: team.id,
        collectionId: team.collectionId,
        collectionName: team.collectionName,
      );

      // Copy personnel and vehicles
      teamCopy.personels.addAll(team.personels);
      if (team.deliveryVehicle.target != null) {
        teamCopy.deliveryVehicle.target = team.deliveryVehicle.target;
      }
      // teamCopy.deliveryVehicle.target?.id = team.deliveryVehicle.target?.id;

      // Clean up data
      await cleanupPersonnelData(teamCopy);
      await cleanupDeliveryTeams();

      // Save the clean copy
      final savedId = deliveryTeamBox.put(teamCopy);
      cachedDeliveryTeam = teamCopy;

      // Verify storage immediately after saving
      deliveryTeamBox.get(savedId);
      // if (storedTeam != null) {
      //   debugPrint('✅ Storage verification successful');
      //   debugPrint('📊 Final stored team details:');
      //   debugPrint('Team ID: ${storedTeam.id}');
      //   debugPrint('Trip ID: ${storedTeam.tripId}');
      //   debugPrint('Personnel count: ${storedTeam.personels.length}');
      //   debugPrint('Vehicle count: ${storedTeam.deliveryVehicle.target!.id}');

      //   // Verify personnel details
      //   for (var p in storedTeam.personels) {
      //     debugPrint('   👤 ${p.name} (${p.id})');
      //   }
      // }
    } catch (e) {
      debugPrint('❌ Cache failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
