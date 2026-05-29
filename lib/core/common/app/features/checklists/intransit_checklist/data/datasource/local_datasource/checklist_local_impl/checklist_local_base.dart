import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';

import '../../../../../../../../../services/objectbox.dart';

abstract class ChecklistLocalBase {
  final ObjectBoxStore objectBoxStore;
  Box<ChecklistModel> get checklistBox => objectBoxStore.checklistBox;
  Box<TripModel> get tripBox => objectBoxStore.tripBox;
  List<ChecklistModel>? cachedChecklist;

  ChecklistLocalBase(this.objectBoxStore);
}
