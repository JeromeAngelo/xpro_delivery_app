import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

import '../common/app/features/notfication/data/model/notification_model.dart';
import '../common/app/features/notfication/presentation/bloc/notification_bloc.dart';
import '../common/app/features/notfication/presentation/bloc/notification_event.dart';

class NotificationRealtimeService {
  final PocketBase pb;
  final NotificationBloc bloc;

  NotificationRealtimeService(this.pb, this.bloc);

  Future<void> init() async {
    try {
      debugPrint('📡 Realtime: initializing notifications subscription...');
      debugPrint('🔐 Realtime: PB auth valid: ${pb.authStore.isValid}');

      await pb.collection('notifications').subscribe('*', (e) {
        try {
          debugPrint('📡 Realtime event: action=${e.action}');

          final record = e.record;
          if (record == null) {
            debugPrint('⚠️ Realtime: record is null');
            return;
          }

          if (e.action == 'create') {
            // ✅ Correct conversion for PocketBase RecordModel
            final newNotification = NotificationModel.fromJson(record as DataMap);

            debugPrint('✅ Realtime: new notification received id=${newNotification.id}');
            bloc.add(NewNotificationReceivedEvent(newNotification));
          } else if (e.action == 'update') {
            // Optional: handle update events if you want
            // final updated = NotificationModel.fromRecord(record);
            // bloc.add(NotificationUpdatedEvent(updated));
          } else if (e.action == 'delete') {
            // Optional: handle deletes if you want
            // bloc.add(NotificationDeletedEvent(record.id));
          }
        } catch (err) {
          debugPrint('❌ Realtime: failed to process event: $err');
        }
      });

      debugPrint('✅ Realtime: notifications subscription ACTIVE');
    } catch (e) {
      debugPrint('❌ Realtime: subscribe failed: $e');
    }
  }

  Future<void> dispose() async {
    try {
      debugPrint('🧹 Realtime: unsubscribing notifications...');
      await pb.collection('notifications').unsubscribe('*');
      debugPrint('✅ Realtime: unsubscribed');
    } catch (e) {
      debugPrint('⚠️ Realtime: unsubscribe failed: $e');
    }
  }
}
