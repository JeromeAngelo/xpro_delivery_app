import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/repo/end_trip_checklist_repo.dart';
import 'package:x_pro_delivery_app/core/common/app/features/end_trip_checklist/domain/entity/end_checklist_entity.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class GenerateEndTripChecklist extends UsecaseWithParams<List<EndChecklistEntity>, String> {
  const GenerateEndTripChecklist(this._repo);

  final EndTripChecklistRepo _repo;

  @override
  ResultFuture<List<EndChecklistEntity>> call(String params) => 
      _repo.generateEndTripChecklist(params);
}


