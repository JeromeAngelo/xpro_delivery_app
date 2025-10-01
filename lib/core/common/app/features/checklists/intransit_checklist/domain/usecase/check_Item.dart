import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/domain/repo/checklist_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class CheckItem extends UsecaseWithParams<bool, String> {
  const CheckItem(this._repo);

  final ChecklistRepo _repo;

  @override
  ResultFuture<bool> call(String params) => _repo.checkItem(params);
}

