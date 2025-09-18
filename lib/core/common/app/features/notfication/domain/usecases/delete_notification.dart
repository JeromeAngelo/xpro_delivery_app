import 'package:equatable/equatable.dart';

import '../../../../../../typedefs/typedefs.dart';
import '../../../../../../usecases/usecase.dart';
import '../repo/notification_repo.dart';

class DeleteNotificationUseCase extends UsecaseWithParams<void, DeleteNotificationParams> {
  final NotificationRepository repository;

  const DeleteNotificationUseCase(this.repository);

  @override
  ResultFuture<void> call(DeleteNotificationParams params) {
    return repository.deleteNotification(params.notificationId);
  }
}

class DeleteNotificationParams extends Equatable {
  final String notificationId;

  const DeleteNotificationParams(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}