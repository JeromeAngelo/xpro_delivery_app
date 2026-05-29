import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/datasource/local_datasource/checklist_local_impl/checklist_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

mixin GetChecklistImpl on ChecklistLocalBase {
  Future<List<ChecklistModel>> getChecklist() async {
    try {
      return checklistBox.getAll();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
