import 'package:equatable/equatable.dart';

import '../../domain/entity/notification_entity.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load all notifications
class LoadAllNotificationsEvent extends NotificationEvent {}

/// Load unread notifications (for bell count)
class LoadUnreadNotificationsEvent extends NotificationEvent {}

/// Mark a specific notification as read
class MarkAsReadEvent extends NotificationEvent {
  final String notificationId;
  const MarkAsReadEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Mark all notifications as read
class MarkAllAsReadEvent extends NotificationEvent {}

/// Create a new notification
class CreateNotificationEvent extends NotificationEvent {
  final String statusId;
  final String deliveryId;
  final String type; // "deliveryUpdate" | "tripUpdate"

  const CreateNotificationEvent({
    required this.statusId,
    required this.deliveryId,
    required this.type,
  });

  @override
  List<Object?> get props => [statusId, deliveryId, type];
}

/// Delete a notification
class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;
  const DeleteNotificationEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NewNotificationReceivedEvent extends NotificationEvent {
  final NotificationEntity notification;
  const NewNotificationReceivedEvent(this.notification);

  @override
  List<Object?> get props => [notification];
}
