import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/repo/logs_repo.dart';

class SyncLogsToRemote extends UsecaseWithoutParams<int> {
  const SyncLogsToRemote(this._repo);

  final LogsRepo _repo;

  @override
  ResultFuture<int> call() => _repo.syncLogsToRemote();
}
