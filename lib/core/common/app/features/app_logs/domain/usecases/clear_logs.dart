import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/repo/logs_repo.dart';

class ClearLogs extends UsecaseWithoutParams<void> {
  const ClearLogs(this._repo);

  final LogsRepo _repo;

  @override
  ResultFuture<void> call() => _repo.clearAllLogs();
}
