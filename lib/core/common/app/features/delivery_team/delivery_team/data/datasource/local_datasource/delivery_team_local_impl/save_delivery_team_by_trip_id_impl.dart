import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/local_datasource/delivery_team_local_impl/delivery_team_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin SaveDeliveryTeamByTripIdImpl on DeliveryTeamLocalBase {
  /// Saves delivery team data locally for a given trip ID
  Future<void> saveDeliveryTeamByTripId(
    String tripId,
    DeliveryTeamModel team,
  ) async {
    try {
      debugPrint(
        '💾 LOCAL: Saving delivery team via Trip relation → tripId=$tripId',
      );

      // -------------------------------------------------------------
      // 1️⃣ Find the trip first
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint('❌ Trip not found in local DB for tripId=$tripId');
        throw CacheException(
          message: 'Trip not found in local DB',
          statusCode: 404,
        );
      }

      // -------------------------------------------------------------
      // 2️⃣ Cleanup dependent data before save
      // -------------------------------------------------------------
      await cleanupPersonnelData(team);

      // -------------------------------------------------------------
      // 3️⃣ Check existing DeliveryTeam via Trip relation
      // -------------------------------------------------------------
      DeliveryTeamModel? existingTeam;
      if (trip.deliveryTeam.target != null) {
        final obxId = trip.deliveryTeam.target!.objectBoxId;
        existingTeam = deliveryTeamBox.get(obxId);
      }

      if (existingTeam != null) {
        debugPrint('♻️ Updating existing DeliveryTeam for trip ${trip.name}');
        team.objectBoxId = existingTeam.objectBoxId;
      }

      // -------------------------------------------------------------
      // 4️⃣ Link team to trip (CRITICAL)
      // -------------------------------------------------------------
      team.trip.target = trip;
      team.trip.targetId = trip.objectBoxId;

      // -------------------------------------------------------------
      // 5️⃣ Save DeliveryTeam
      // -------------------------------------------------------------
      deliveryTeamBox.put(team);

      // -------------------------------------------------------------
      // 6️⃣ Ensure Trip → DeliveryTeam link is set
      // -------------------------------------------------------------
      trip.deliveryTeam.target = team;
      tripBox.put(trip);

      cachedDeliveryTeam = team;

      debugPrint(
        '✅ LOCAL: Delivery team saved successfully for trip ${trip.name}',
      );

      // -------------------------------------------------------------
      // 7️⃣ Verification
      // -------------------------------------------------------------
      final verifyTeam = tripBox.get(trip.objectBoxId)?.deliveryTeam.target;

      if (verifyTeam != null) {
        debugPrint(
          '📊 Verification OK → ${verifyTeam.personels.length} personnels stored',
        );
      } else {
        debugPrint('⚠️ Verification failed: Trip has no linked DeliveryTeam');
      }
    } catch (e, st) {
      debugPrint(
        '❌ LOCAL: Failed to save delivery team for trip $tripId\n$e\n$st',
      );
      throw CacheException(message: e.toString());
    }
  }
}
