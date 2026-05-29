import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_impl/end_trip_checklist_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CacheChecklistsImpl on EndTripChecklistLocalBase {
  Future<void> cacheChecklists(List<EndTripChecklistModel> checklists) async {
    try {
      debugPrint('💾 Caching checklists from remote');
      await autoSave(checklists);
      debugPrint('✅ Checklists cached successfully');
    } catch (e) {
      debugPrint('❌ Failed to cache checklists: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
