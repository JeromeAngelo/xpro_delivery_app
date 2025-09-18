import '../../../../../../typedefs/typedefs.dart';
import '../../../../../../usecases/usecase.dart';
import '../entity/notification_entity.dart';
import '../repo/notification_repo.dart';

class GetUnreadNotificationsUseCase extends UsecaseWithoutParams<List<NotificationEntity>> {
  final NotificationRepository repository;

  const GetUnreadNotificationsUseCase(this.repository);

  @override
  ResultFuture<List<NotificationEntity>> call() {
    return repository.getUnreadNotifications();
  }
}