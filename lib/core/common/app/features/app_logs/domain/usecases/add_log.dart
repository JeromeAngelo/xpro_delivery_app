import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/repo/logs_repo.dart';

class AddLog extends UsecaseWithParams<void, AddLogParams> {
  const AddLog(this._repo);

  final LogsRepo _repo;

  @override
  ResultFuture<void> call(AddLogParams params) => _repo.addLog(params.logEntry);
}

class AddLogParams extends Equatable {
  const AddLogParams({required this.logEntry});

  final LogEntryEntity logEntry;

  @override
  List<Object?> get props => [logEntry];
}
