import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/datasource/local_datasource/checklist_local_impl/checklist_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CheckItemImpl on ChecklistLocalBase {
  Future<bool> checkItem(String id) async {
    try {
      final itemId = id.trim();
      if (itemId.isEmpty) return false;

      // ✅ SAFEST: use query with string compare
      final q =
          checklistBox
              .query(ChecklistModel_.pocketbaseId.equals(itemId))
              .build();

      final checklist = q.findFirst();
      q.close();

      if (checklist == null) {
        debugPrint('⚠️ Checklist item not found locally: $itemId');
        return false;
      }

      final current = checklist.isChecked ?? false;

      // ✅ toggle properly
      checklist.isChecked = current;

      checklistBox.put(checklist);

      debugPrint(
        '✅ Updated checklist item: ${checklist.objectName} | Checked: ${checklist.isChecked}',
      );

      return checklist.isChecked ?? false;
    } catch (e, st) {
      debugPrint('❌ Local checkItem error: $e\n$st');
      throw CacheException(message: e.toString());
    }
  }
}
