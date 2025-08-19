import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/repo/logs_repo.dart';

class MarkLogsAsSynced extends UsecaseWithParams<void, MarkLogsAsSyncedParams> {
  const MarkLogsAsSynced(this._repo);

  final LogsRepo _repo;

  @override
  ResultFuture<void> call(MarkLogsAsSyncedParams params) => _repo.markLogsAsSynced(params.logIds);
}

class MarkLogsAsSyncedParams extends Equatable {
  const MarkLogsAsSyncedParams({required this.logIds});

  final List<String> logIds;

  @override
  List<Object?> get props => [logIds];
}
