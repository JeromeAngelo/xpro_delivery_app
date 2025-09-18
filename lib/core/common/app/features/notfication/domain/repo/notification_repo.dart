import '../../../../../../typedefs/typedefs.dart';
import '../entity/notification_entity.dart';

abstract class NotificationRepository {
  /// Get all notifications
  ResultFuture<List<NotificationEntity>> getAllNotifications();

  /// Get unread notifications
  ResultFuture<List<NotificationEntity>> getUnreadNotifications();

  /// Mark a specific notification as read
  ResultFuture<void> markAsRead(String notificationId);

  /// Mark all notifications as read (optional but useful for "clear all")
  ResultFuture<void> markAllAsRead();

  /// Create a new notification (usually called after delivery status or trip update)
  ResultFuture<void> createNotification({
    required String statusId,
    required String deliveryId,
    required String type, // "deliveryUpdate" or "tripUpdate"
  });

  /// Delete a notification (optional, if admin wants to clean up)
  ResultFuture<void> deleteNotification(String notificationId);
}
