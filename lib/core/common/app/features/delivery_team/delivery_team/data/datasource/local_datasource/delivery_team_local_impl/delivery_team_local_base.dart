import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/personels/data/models/personel_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

import '../../../../../../../../../services/objectbox.dart';
import '../../../../../../checklists/intransit_checklist/data/model/checklist_model.dart';
import '../../../../../../trip_ticket/trip/data/models/trip_models.dart';
import '../../../../../delivery_vehicle_data/data/model/delivery_vehicle_model.dart';

abstract class DeliveryTeamLocalBase {
  final ObjectBoxStore objectBoxStore;
  Box<DeliveryTeamModel> get deliveryTeamBox => objectBoxStore.deliveryTeamBox;
  Box<DeliveryVehicleModel> get vehicleBox => objectBoxStore.deliveryVehicleBox;
  Box<PersonelModel> get personnelBox => objectBoxStore.personelBox;
  Box<ChecklistModel> get checklistBox => objectBoxStore.checklistBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;

  DeliveryTeamModel? cachedDeliveryTeam;

  DeliveryTeamLocalBase(this.objectBoxStore);

  Future<void> cleanupDeliveryTeams() async {
    try {
      debugPrint('🧹 Starting delivery team cleanup process');
      final allTeams = deliveryTeamBox.getAll();

      final Map<String?, DeliveryTeamModel> uniqueTeams = {};

      for (var team in allTeams) {
        if (isValidDeliveryTeam(team)) {
          final existingTeam = uniqueTeams[team.pocketbaseId];
          if (existingTeam == null ||
              (team.updated!.isAfter(existingTeam.updated ?? DateTime(0)))) {
            uniqueTeams[team.pocketbaseId] = team;
          }
        }
      }

      deliveryTeamBox.removeAll();
      deliveryTeamBox.putMany(uniqueTeams.values.toList());

      debugPrint('✨ Delivery team cleanup complete:');
      debugPrint('📊 Original count: ${allTeams.length}');
      debugPrint('📊 After cleanup: ${uniqueTeams.length}');
    } catch (e) {
      debugPrint('❌ Cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  Future<void> cleanupPersonnelData(DeliveryTeamModel team) async {
    try {
      debugPrint('🧹 Starting personnel cleanup');
      final currentPersonnel = team.personels.toList();

      // Track unique personnel by their IDs
      final Map<String, PersonelModel> uniquePersonnel = {};

      // First pass - collect unique personnel
      for (var person in currentPersonnel) {
        if (person.id != null) {
          debugPrint('👤 Processing personnel: ${person.name} (${person.id})');
          // Only keep the first instance of each personnel
          if (!uniquePersonnel.containsKey(person.id)) {
            uniquePersonnel[person.id!] = person;
          }
        }
      }

      // Clear existing personnel
      team.personels.clear();

      // Add back only unique personnel
      team.personels.addAll(uniquePersonnel.values);

      debugPrint('✨ Personnel cleanup complete:');
      debugPrint('📊 Original count: ${currentPersonnel.length}');
      debugPrint('📊 After cleanup: ${team.personels.length}');

      // Verify unique personnel
      final uniqueIds = team.personels.map((p) => p.id).toSet();
      debugPrint('🔍 Unique personnel IDs: ${uniqueIds.length}');
      for (var p in team.personels) {
        debugPrint('   - ${p.name} (${p.id})');
      }
    } catch (e) {
      debugPrint('❌ Personnel cleanup failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  bool isValidDeliveryTeam(DeliveryTeamModel team) {
    final hasTrip = team.tripId != null && team.tripId!.isNotEmpty;
    final hasVehicle =
        team.deliveryVehicle.target != null &&
        team.deliveryVehicle.target!.id != 0;
    final hasPersonnel = team.personels.isNotEmpty;

    return hasTrip && hasVehicle && hasPersonnel;
  }
}
