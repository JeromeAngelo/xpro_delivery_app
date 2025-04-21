import 'package:x_pro_delivery_app/core/common/app/features/checklist/domain/entity/checklist_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

abstract class ChecklistRepo {
  ResultFuture<List<ChecklistEntity>> loadChecklist();
   ResultFuture<List<ChecklistEntity>> loadChecklistByTripId(String? tripId);
   ResultFuture<List<ChecklistEntity>> loadLocalChecklistByTripId(String? tripId);
  ResultFuture<bool> checkItem(String id);
  
}