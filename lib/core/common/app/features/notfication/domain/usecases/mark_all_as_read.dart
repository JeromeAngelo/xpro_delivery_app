
import '../../../../../../typedefs/typedefs.dart';
import '../../../../../../usecases/usecase.dart';
import '../repo/notification_repo.dart';

class MarkAllAsReadUseCase extends UsecaseWithoutParams<void> {
  final NotificationRepository repository;

  const MarkAllAsReadUseCase(this.repository);

  @override
  ResultFuture<void> call() {
    return repository.markAllAsRead();
  }
}