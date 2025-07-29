import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/repo/logs_repo.dart';

class DownloadLogsPdf extends UsecaseWithoutParams<String> {
  const DownloadLogsPdf(this._repo);

  final LogsRepo _repo;

  @override
  ResultFuture<String> call() => _repo.downloadLogsAsPdf();
}
