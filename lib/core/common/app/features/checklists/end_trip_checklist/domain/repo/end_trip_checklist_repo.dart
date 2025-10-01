import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/domain/entity/end_checklist_entity.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
abstract class EndTripChecklistRepo {
  // Automatically generates checklist items for end trip
  ResultFuture<List<EndChecklistEntity>> generateEndTripChecklist(String tripId);
  
  // Checks/updates specific checklist item
  ResultFuture<bool> checkEndTripChecklistItem(String id);
  
  // Loads the generated checklist for viewing
  ResultFuture<List<EndChecklistEntity>> loadEndTripChecklist(String tripId);

  // Loads checklist from local storage
  ResultFuture<List<EndChecklistEntity>> loadLocalEndTripChecklist(String tripId);
}




