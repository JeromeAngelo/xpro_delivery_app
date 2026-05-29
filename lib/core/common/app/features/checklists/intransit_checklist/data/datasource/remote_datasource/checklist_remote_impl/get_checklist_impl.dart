import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/datasource/remote_datasource/checklist_remote_impl/checklist_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetChecklistImpl on ChecklistRemoteBase {
  Future<List<ChecklistModel>> getChecklist() async {
    try {
      final records =
          await pocketBaseClient.collection('checklist').getFullList();
      return records.map((record) {
        final data = {
          ...record.data,
          'id': record.id,
          'collectionId': record.collectionId,
          'collectionName': record.collectionName,
        };
        debugPrint('Processing checklist record: $data');
        return ChecklistModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
