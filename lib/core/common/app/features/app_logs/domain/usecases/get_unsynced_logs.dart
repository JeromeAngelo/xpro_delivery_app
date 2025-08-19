import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/repo/logs_repo.dart';

class GetUnsyncedLogs extends UsecaseWithoutParams<List<LogEntryEntity>> {
  const GetUnsyncedLogs(this._repo);

  final LogsRepo _repo;

  @override
  ResultFuture<List<LogEntryEntity>> call() => _repo.getUnsyncedLogs();
}
