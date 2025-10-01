import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/domain/repo/end_trip_checklist_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CheckEndTripChecklist extends UsecaseWithParams<bool, String> {
  const CheckEndTripChecklist(this._repo);

  final EndTripChecklistRepo _repo;

  @override
  ResultFuture<bool> call(String params) => 
      _repo.checkEndTripChecklistItem(params);
}
