import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import '../../model/notification_model.dart';

abstract class NotificationRemoteDatasource {
  Future<List<NotificationModel>> getAllNotifications();
  Future<List<NotificationModel>> getUnreadNotifications();
  Future<List<NotificationModel>> getReadNotifications();
  Future<List<NotificationModel>> getDeletedNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> createNotification({
    required String statusId,
    required String deliveryId,
    required String type,
  });
  Future<void> deleteNotification(String notificationId);
}

class NotificationRemoteDatasourceImpl implements NotificationRemoteDatasource {
  const NotificationRemoteDatasourceImpl({required PocketBase pocketBaseClient})
      : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  static const String _authTokenKey = 'auth_token';
  static const String _authUserKey = 'auth_user';

  /// Ensure PocketBase is authenticated
  Future<void> _ensureAuthenticated() async {
    try {
      if (_pocketBaseClient.authStore.isValid) {
        debugPrint('✅ PocketBase already authenticated');
        return;
      }

      debugPrint('⚠️ PocketBase not authenticated. Restoring…');

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(_authTokenKey);

      if (authToken != null) {
        _pocketBaseClient.authStore.save(authToken, null);
        debugPrint('✅ Auth restored from storage');
      } else {
        throw const ServerException(
          message: 'User not authenticated. Please log in again.',
          statusCode: '401',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Authentication failed: ${e.toString()}',
        statusCode: '401',
      );
    }
  }

  /// Retry helper with exponential backoff
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation,
    String name, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int retry = 0;
    var delay = initialDelay;

    while (retry < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retry++;
        final isNetworkError = e.toString().contains('Failed to fetch');
        if (retry >= maxRetries || !isNetworkError) rethrow;

        debugPrint('⏳ Retry $retry/$maxRetries for $name in ${delay.inSeconds}s');
        await Future.delayed(delay);
        delay *= 2;
      }
    }
    throw ServerException(
      message: 'Failed after $maxRetries attempts ($name)',
      statusCode: '503',
    );
  }

  NotificationModel _processNotificationRecord(RecordModel record) {
    return NotificationModel.fromJson({
      'id': record.id,
      'collectionId': record.collectionId,
      'collectionName': record.collectionName,
      ...record.data,
    });
  }

  @override
  Future<List<NotificationModel>> getAllNotifications() async {
    return await _retryWithBackoff(() async {
      await _ensureAuthenticated();
      debugPrint('🔄 Fetching all notifications');

      final result = await _pocketBaseClient
          .collection('notifications')
          .getFullList(sort: '-created', expand: 'status,delivery');

      debugPrint('✅ Retrieved ${result.length} notifications');
      return result.map(_processNotificationRecord).toList();
    }, 'getAllNotifications');
  }

  @override
  Future<List<NotificationModel>> getUnreadNotifications() async {
    return await _retryWithBackoff(() async {
      await _ensureAuthenticated();
      debugPrint('🔄 Fetching unread notifications');

      final result = await _pocketBaseClient
          .collection('notifications')
          .getFullList(filter: 'isRead = false', sort: '-created');

      return result.map(_processNotificationRecord).toList();
    }, 'getUnreadNotifications');
  }

  @override
  Future<List<NotificationModel>> getReadNotifications() async {
    return await _retryWithBackoff(() async {
      await _ensureAuthenticated();
      debugPrint('🔄 Fetching read notifications');

      final result = await _pocketBaseClient
          .collection('notifications')
          .getFullList(filter: 'isRead = true', sort: '-created');

      return result.map(_processNotificationRecord).toList();
    }, 'getReadNotifications');
  }

  @override
  Future<List<NotificationModel>> getDeletedNotifications() async {
    return await _retryWithBackoff(() async {
      await _ensureAuthenticated();
      debugPrint('🔄 Fetching deleted notifications');

      final result = await _pocketBaseClient
          .collection('notifications')
          .getFullList(filter: 'isDeleted = true', sort: '-created');

      return result.map(_processNotificationRecord).toList();
    }, 'getDeletedNotifications');
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    return await _retryWithBackoff(() async {
      await _ensureAuthenticated();
      debugPrint('📝 Marking notification $notificationId as read');

      await _pocketBaseClient.collection('notifications').update(
        notificationId,
        body: {'isRead': true},
      );
    }, 'markAsRead');
  }

  @override
  Future<void> markAllAsRead() async {
    return await _retryWithBackoff(() async {
      await _ensureAuthenticated();
      debugPrint('📝 Marking all notifications as read');

      final unread = await _pocketBaseClient
          .collection('notifications')
          .getFullList(filter: 'isRead = false');

      for (final record in unread) {
        await _pocketBaseClient.collection('notifications').update(
          record.id,
          body: {'isRead': true},
        );
      }
    }, 'markAllAsRead');
  }

  @override
  Future<void> createNotification({
    required String statusId,
    required String deliveryId,
    required String type,
  }) async {
    return await _retryWithBackoff(() async {
      await _ensureAuthenticated();
      debugPrint('📝 Creating new notification');

      await _pocketBaseClient.collection('notifications').create(body: {
        'status': statusId,
        'delivery': deliveryId,
        'type': type,
        'isRead': false,
        'created': DateTime.now().toIso8601String(),
      });
    }, 'createNotification');
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    return await _retryWithBackoff(() async {
      await _ensureAuthenticated();
      debugPrint('🗑️ Deleting notification $notificationId');

      await _pocketBaseClient.collection('notifications').delete(notificationId);
    }, 'deleteNotification');
  }
}
