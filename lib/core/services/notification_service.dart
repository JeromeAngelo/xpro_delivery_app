import 'package:pocketbase/pocketbase.dart';

import '../common/app/features/notfication/data/model/notification_model.dart';
import '../common/app/features/notfication/presentation/bloc/notification_bloc.dart';
import '../common/app/features/notfication/presentation/bloc/notification_event.dart';

class NotificationRealtimeService {
  final PocketBase pb;
  final NotificationBloc bloc;

  NotificationRealtimeService(this.pb, this.bloc);

  void init() {
    pb.collection('notifications').subscribe('*', (e) {
      if (e.action == 'create' && e.record != null) {
        final newNotification = NotificationModel.fromRecord(e.record!);
        bloc.add(NewNotificationReceivedEvent(newNotification));
      }
    });
  }

  void dispose() {
    pb.collection('notifications').unsubscribe('*');
  }
}
