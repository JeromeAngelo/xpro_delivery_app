import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

import '../../../../../../usecases/usecase.dart';
import '../entity/notification_entity.dart';
import '../repo/notification_repo.dart';

class GetAllNotificationsUseCase extends UsecaseWithoutParams<List<NotificationEntity>> {
  final NotificationRepository repository;

  const GetAllNotificationsUseCase(this.repository);

  @override
  ResultFuture<List<NotificationEntity>> call() {
    return repository.getAllNotifications();
  }
}