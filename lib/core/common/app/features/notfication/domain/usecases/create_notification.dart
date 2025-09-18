import 'package:equatable/equatable.dart';

import '../../../../../../typedefs/typedefs.dart';
import '../../../../../../usecases/usecase.dart';
import '../repo/notification_repo.dart';

class CreateNotificationUseCase extends UsecaseWithParams<void, CreateNotificationParams> {
  final NotificationRepository repository;

  const CreateNotificationUseCase(this.repository);

  @override
  ResultFuture<void> call(CreateNotificationParams params) {
    return repository.createNotification(
      statusId: params.statusId,
      deliveryId: params.deliveryId,
      type: params.type,
    );
  }
}

class CreateNotificationParams extends Equatable {
  final String statusId;
  final String deliveryId;
  final String type;

  const CreateNotificationParams({
    required this.statusId,
    required this.deliveryId,
    required this.type,
  });

  @override
  List<Object?> get props => [statusId, deliveryId, type];
}