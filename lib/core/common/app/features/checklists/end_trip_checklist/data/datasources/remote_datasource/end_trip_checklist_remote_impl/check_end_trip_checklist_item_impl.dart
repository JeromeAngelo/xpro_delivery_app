import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/datasources/remote_datasource/end_trip_checklist_remote_impl/end_trip_checklist_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CheckEndTripChecklistItemImpl on EndTripChecklistRemoteBase {
  Future<bool> checkEndTripChecklistItem(String id) async {
    try {
      debugPrint('🔄 Updating checklist item: $id');

      await pocketBaseClient
          .collection('endTripChecklist')
          .update(
            id,
            body: {
              'isChecked': true,
              'status': 'completed',
              'timeCompleted': DateTime.now().toIso8601String(),
            },
          );

      debugPrint('✅ Checklist item updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to update checklist item: ${e.toString()}');
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
