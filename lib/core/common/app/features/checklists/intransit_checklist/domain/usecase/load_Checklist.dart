import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/domain/entity/checklist_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/domain/repo/checklist_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class LoadChecklist extends UsecaseWithoutParams <List<ChecklistEntity>> {
  const LoadChecklist(this._repo);

  final ChecklistRepo _repo;

  @override
  ResultFuture<List<ChecklistEntity>> call() => _repo.loadChecklist();
}