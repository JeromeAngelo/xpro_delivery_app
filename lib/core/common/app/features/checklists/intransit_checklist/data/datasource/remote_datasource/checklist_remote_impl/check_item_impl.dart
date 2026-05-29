import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/datasource/remote_datasource/checklist_remote_impl/checklist_remote_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin CheckItemImpl on ChecklistRemoteBase {
  Future<bool> checkItem(String id) async {
    try {
      final record = await pocketBaseClient.collection('checklist').getOne(id);
      final currentStatus = record.data['isChecked'] as bool? ?? false;

      final currentTime = DateTime.now().toIso8601String();
      final updatedRecord = await pocketBaseClient
          .collection('checklist')
          .update(
            id,
            body: {'isChecked': !currentStatus, 'timeCompleted': currentTime},
          );

      return updatedRecord.data['isChecked'] as bool? ?? false;
    } catch (e) {
      throw ServerException(message: e.toString(), statusCode: '500');
    }
  }
}
