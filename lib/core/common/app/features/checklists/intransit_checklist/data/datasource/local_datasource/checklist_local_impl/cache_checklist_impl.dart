import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/datasource/local_datasource/checklist_local_impl/checklist_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CacheChecklistImpl on ChecklistLocalBase {
  Future<void> cacheChecklist(List<ChecklistModel> checklist) async {
    try {
      debugPrint('💾 Caching ${checklist.length} checklist items');
      checklistBox.removeAll();
      checklistBox.putMany(checklist);
      cachedChecklist = checklist;
      debugPrint('✅ Checklist cached successfully');
    } catch (e) {
      debugPrint('❌ Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
