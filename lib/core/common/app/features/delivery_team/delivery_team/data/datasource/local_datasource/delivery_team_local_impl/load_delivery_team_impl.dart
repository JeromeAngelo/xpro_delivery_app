import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/local_datasource/delivery_team_local_impl/delivery_team_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import '../../../../../../checklists/intransit_checklist/data/model/checklist_model.dart';

mixin LoadDeliveryTeamImpl on DeliveryTeamLocalBase {
  Future<DeliveryTeamModel> loadDeliveryTeam(String tripId) async {
    try {
      debugPrint("📥 LOCAL loadDeliveryTeam() tripId = $tripId");

      // -------------------------------------------------------------
      // 1️⃣ Find the trip first
      // -------------------------------------------------------------
      final tripQuery = tripBox.query(TripModel_.id.equals(tripId)).build();
      final trip = tripQuery.findFirst();
      tripQuery.close();

      if (trip == null) {
        debugPrint("⚠️ Trip not found in local DB for tripId: $tripId");
        throw CacheException(
          message: "Trip not found in local DB",
          statusCode: 404,
        );
      }

      // -------------------------------------------------------------
      // 2️⃣ Get DeliveryTeam linked to this trip
      // -------------------------------------------------------------
      DeliveryTeamModel? team;
      for (final t in deliveryTeamBox.getAll()) {
        if (t.trip.targetId == trip.objectBoxId) {
          team = t;
          break;
        }
      }

      if (team == null) {
        debugPrint("❌ No DeliveryTeam found for trip: $tripId");
        throw CacheException(
          message: "No DeliveryTeam found in local DB",
          statusCode: 404,
        );
      }

      debugPrint(
        "✅ DeliveryTeam FOUND → pbId=${team.id}, obx=${team.objectBoxId}, active delivery ${team.activeDeliveries}",
      );
      debugPrint(
        "    Personnels=${team.personels.length}, Checklist=${team.checklist.length}, Vehicle=${team.deliveryVehicle.target?.name}",
      );

      // -------------------------------------------------------------
      // 3️⃣ Load Vehicle (ToOne)
      // -------------------------------------------------------------
      final vRef = team.deliveryVehicle.target;
      if (vRef != null) {
        final fullVehicle = vehicleBox.get(vRef.objectBoxId);
        if (fullVehicle != null) {
          team.deliveryVehicle.target = fullVehicle;
          team.deliveryVehicle.targetId = fullVehicle.objectBoxId;
        }
      }

      // -------------------------------------------------------------
      // 4️⃣ Load Personnels (ToMany)
      // -------------------------------------------------------------
      final personnels = <PersonelModel>[];
      for (var p in team.personels) {
        if (p.objectBoxId != 0) {
          final full = personnelBox.get(p.objectBoxId);
          if (full != null) personnels.add(full);
        }
      }
      team.personels
        ..clear()
        ..addAll(personnels);

      // -------------------------------------------------------------
      // 5️⃣ Load Checklist (ToMany)
      // -------------------------------------------------------------
      final checklist = <ChecklistModel>[];
      for (var c in team.checklist) {
        if (c.objectBoxId != 0) {
          final full = checklistBox.get(c.objectBoxId);
          if (full != null) checklist.add(full);
        }
      }
      team.checklist
        ..clear()
        ..addAll(checklist);

      debugPrint("🎉 DeliveryTeam fully loaded for trip: ${trip.id}");
      return team;
    } catch (e, st) {
      debugPrint("❌ loadDeliveryTeam ERROR: $e\n$st");
      throw CacheException(message: e.toString());
    }
  }
}
