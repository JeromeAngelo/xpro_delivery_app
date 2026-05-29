import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

import '../../../../../../../../../services/objectbox.dart';

abstract class EndTripChecklistLocalBase {
  final ObjectBoxStore objectBoxStore;
  Box<EndTripChecklistModel> get endTripChecklistBox =>
      objectBoxStore.endTripChecklistBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  List<EndTripChecklistModel>? cachedChecklists;

  EndTripChecklistLocalBase(this.objectBoxStore);

  Future<void> autoSave(List<EndTripChecklistModel> checklists) async {
    try {
      debugPrint('🔍 Processing ${checklists.length} checklist items');

      // Clear existing data
      endTripChecklistBox.removeAll();
      debugPrint('🧹 Cleared previous checklist items');

      // Filter out duplicates by ID
      final uniqueChecklists =
          checklists
              .fold<Map<String, EndTripChecklistModel>>({}, (map, checklist) {
                map[checklist.id ?? ''] = checklist;
                return map;
              })
              .values
              .toList();

      endTripChecklistBox.putMany(uniqueChecklists);
      cachedChecklists = uniqueChecklists;
      debugPrint(
        '📊 Stored ${uniqueChecklists.length} unique valid checklist items',
      );
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
