import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/local_datasource/end_trip_checklist_local_impl/end_trip_checklist_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CheckEndTripChecklistItemImpl on EndTripChecklistLocalBase {
  Future<bool> checkEndTripChecklistItem(String id) async {
    try {
      debugPrint('🔄 LOCAL: Updating checklist item $id');

      final items = endTripChecklistBox.getAll();
      final item = items.firstWhere(
        (item) => item.id == id,
        orElse: () {
          debugPrint('⚠️ LOCAL: Item not found with ID: $id');
          throw const CacheException(
            message: 'Checklist item not found',
            statusCode: 404,
          );
        },
      );

      item.isChecked = true;
      item.status = 'completed';
      item.timeCompleted = DateTime.now();

      endTripChecklistBox.put(item);
      debugPrint('✅ LOCAL: Item updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ LOCAL: Update failed - $e');
      throw CacheException(message: e.toString());
    }
  }
}
