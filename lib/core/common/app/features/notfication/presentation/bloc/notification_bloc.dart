import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/notfication/domain/usecases/create_notification.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/notfication/domain/usecases/delete_notification.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/notfication/domain/usecases/get_all_notification.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/notfication/domain/usecases/mark_all_as_read.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/notfication/domain/usecases/mark_as_read.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/notfication/presentation/bloc/notification_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/notfication/presentation/bloc/notification_state.dart';

import '../../domain/usecases/get_unread_notification.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetAllNotificationsUseCase _getAllNotifications;
  final GetUnreadNotificationsUseCase _getUnreadNotifications;
  final MarkAsReadUseCase _markAsRead;
  final MarkAllAsReadUseCase _markAllAsRead;
  final CreateNotificationUseCase _createNotification;
  final DeleteNotificationUseCase _deleteNotification;

  NotificationState? _cachedState;

  NotificationBloc({
    required GetAllNotificationsUseCase getAllNotifications,
    required GetUnreadNotificationsUseCase getUnreadNotifications,
    required MarkAsReadUseCase markAsRead,
    required MarkAllAsReadUseCase markAllAsRead,
    required CreateNotificationUseCase createNotification,
    required DeleteNotificationUseCase deleteNotification,
  })  : _getAllNotifications = getAllNotifications,
        _getUnreadNotifications = getUnreadNotifications,
        _markAsRead = markAsRead,
        _markAllAsRead = markAllAsRead,
        _createNotification = createNotification,
        _deleteNotification = deleteNotification,
        super(NotificationInitial()) {
    on<LoadAllNotificationsEvent>(_onLoadAllNotifications);
    on<LoadUnreadNotificationsEvent>(_onLoadUnreadNotifications);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
    on<CreateNotificationEvent>(_onCreateNotification);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<NewNotificationReceivedEvent>(_onNewNotificationReceived);
  }

  Future<void> _onLoadAllNotifications(
  LoadAllNotificationsEvent event,
  Emitter<NotificationState> emit,
) async {
  emit(NotificationLoading());
  debugPrint('🔄 BLOC: Getting all notifications');

  final result = await _getAllNotifications();
  result.fold(
    (failure) {
      debugPrint('❌ BLOC: Failed to get notifications: ${failure.message}');
      emit(NotificationError(message: failure.message));
    },
    (notifications) {
      debugPrint('✅ BLOC: Successfully retrieved ${notifications.length} notifications');

      // Safe check for null values
      final unreadCount = notifications.where((n) => n.isRead == false).length;

      final newState = NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      );
      _cachedState = newState;
      emit(newState);
    },
  );
}


Future<void> _onNewNotificationReceived(
  NewNotificationReceivedEvent event,
  Emitter<NotificationState> emit,
) async {
  if (_cachedState is NotificationLoaded) {
    final current = _cachedState as NotificationLoaded;
    final updatedList = [event.notification, ...current.notifications];
    emit(NotificationLoaded(
      notifications: updatedList,
      unreadCount: updatedList.where((n) => n.isRead == false).length,
    ));
  }
}


  Future<void> _onLoadUnreadNotifications(
    LoadUnreadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    debugPrint('🔄 BLOC: Getting unread notifications');

    final result = await _getUnreadNotifications();
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get unread notifications: ${failure.message}');
        emit(NotificationError(message:failure.message));
      },
      (notifications) {
        debugPrint('✅ BLOC: Successfully retrieved ${notifications.length} unread notifications');
        final newState = NotificationLoaded(
          notifications: notifications,
          unreadCount: notifications.length,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

Future<void> _onMarkAsRead(
  MarkAsReadEvent event,
  Emitter<NotificationState> emit,
) async {
  emit(NotificationLoading());
  debugPrint('🔄 BLOC: Marking notification ${event.notificationId} as read');

  // wrap the String into MarkAsReadParams
  final result = await _markAsRead(MarkAsReadParams(event.notificationId));

  result.fold(
    (failure) {
      debugPrint('❌ BLOC: Failed to mark notification as read: ${failure.message}');
      emit(NotificationError(message: failure.message));
    },
    (_) {
      debugPrint('✅ BLOC: Notification marked as read');
      emit(const NotificationSuccess('Notification marked as read'));
      
      // refresh the list after marking as read
      add(LoadAllNotificationsEvent());
    },
  );
}


  Future<void> _onMarkAllAsRead(
    MarkAllAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    debugPrint('🔄 BLOC: Marking all notifications as read');

    final result = await _markAllAsRead();
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to mark all as read: ${failure.message}');
        emit(NotificationError(message:failure.message));
      },
      (_) {
        debugPrint('✅ BLOC: All notifications marked as read');
        emit(const NotificationSuccess('All notifications marked as read'));
        add(LoadAllNotificationsEvent()); // refresh
      },
    );
  }

 Future<void> _onCreateNotification(
  CreateNotificationEvent event,
  Emitter<NotificationState> emit,
) async {
  emit(NotificationLoading());
  debugPrint('🔄 BLOC: Creating new notification for deliveryId: ${event.deliveryId}');

  final result = await _createNotification(
    CreateNotificationParams(
      statusId: event.statusId,
      deliveryId: event.deliveryId,
      type: event.type,
    ),
  );

  result.fold(
    (failure) {
      debugPrint('❌ BLOC: Failed to create notification: ${failure.message}');
      emit(NotificationError(message: failure.message));
    },
    (_) {
      debugPrint('✅ BLOC: Notification created successfully');
      emit(const NotificationSuccess('Notification created'));
      add( LoadAllNotificationsEvent()); // refresh after creation
    },
  );
}


  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    debugPrint('🔄 BLOC: Deleting notification with ID: ${event.notificationId}');

    final result = await _deleteNotification(event.notificationId as DeleteNotificationParams);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to delete notification: ${failure.message}');
        emit(NotificationError(message:failure.message));
      },
      (_) {
        debugPrint('✅ BLOC: Notification deleted with ID: ${event.notificationId}');
        emit(const NotificationSuccess('Notification deleted'));
        add(LoadAllNotificationsEvent()); // refresh
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
