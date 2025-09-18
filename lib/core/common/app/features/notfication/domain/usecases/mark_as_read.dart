import 'package:equatable/equatable.dart';

import '../../../../../../typedefs/typedefs.dart';
import '../../../../../../usecases/usecase.dart';
import '../repo/notification_repo.dart';

class MarkAsReadUseCase extends UsecaseWithParams<void, MarkAsReadParams> {
  final NotificationRepository repository;

  const MarkAsReadUseCase(this.repository);

  @override
  ResultFuture<void> call(MarkAsReadParams params) {
    return repository.markAsRead(params.notificationId);
  }
}

class MarkAsReadParams extends Equatable {
  final String notificationId;

  const MarkAsReadParams(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}