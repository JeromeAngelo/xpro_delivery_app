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
  try {
    debugPrint('🔄 Mapping record to NotificationModel: ${record.id}');
    debugPrint('🔔 Record expand keys: ${record.expand.keys}');

    // ✅ Single relations: delivery, status, trip
    final deliveryJson = _mapExpandedSingle(record.expand['delivery'], fieldName: 'delivery');
    final statusJson = _mapExpandedSingle(record.expand['status'], fieldName: 'status');
    final tripJson = _mapExpandedSingle(record.expand['trip'], fieldName: 'trip');

    // ✅ Build mapped payload (include created/updated + expand)
    final mappedData = <String, dynamic>{
      'id': record.id,
      'collectionId': record.collectionId,
      'collectionName': record.collectionName,
      'created': record.created,
      'updated': record.updated,
      ...Map<String, dynamic>.from(record.data),

      // Keep PB-style expand so NotificationModel.fromJson can read it
      'expand': <String, dynamic>{
        if (deliveryJson != null) 'delivery': deliveryJson,
        if (statusJson != null) 'status': statusJson,
        if (tripJson != null) 'trip': tripJson,
      },
    };

    // ✅ Debug what we mapped (IDs only to keep logs light)
    debugPrint('✅ Notification mapped: ${record.id}');
    debugPrint('   📦 delivery expanded: ${deliveryJson?['id'] ?? 'none'}');
    debugPrint('   📦 status expanded: ${statusJson?['id'] ?? 'none'}');
    debugPrint('   📦 trip expanded: ${tripJson?['id'] ?? 'none'}');

    return NotificationModel.fromJson(mappedData);
  } catch (e) {
    debugPrint('❌ Error mapping record to NotificationModel: $e');
    throw ServerException(
      message: 'Failed to map record to NotificationModel: $e',
      statusCode: '500',
    );
  }
}

/// ✅ Helper: map a SINGLE expanded relation (RecordModel or List<RecordModel>)
/// - PocketBase expand can sometimes be a RecordModel or a List<RecordModel>
/// - For your case (single relation), we normalize to a Map<String, dynamic>
Map<String, dynamic>? _mapExpandedSingle(
  dynamic expanded, {
  required String fieldName,
}) {
  if (expanded == null) {
    debugPrint('⚠️ No expanded "$fieldName" found');
    return null;
  }

  // Sometimes PB expand can be List even for single (depending on schema/client)
  if (expanded is List) {
    if (expanded.isEmpty) {
      debugPrint('⚠️ Expanded "$fieldName" is an empty list');
      return null;
    }
    final first = expanded.first;
    if (first is RecordModel) {
      debugPrint('✅ Expanded "$fieldName" is List<RecordModel> (using first: ${first.id})');
      return <String, dynamic>{
        'id': first.id,
        'collectionId': first.collectionId,
        'collectionName': first.collectionName,
        'created': first.created,
        'updated': first.updated,
        ...Map<String, dynamic>.from(first.data),
        'expand': first.expand,
      };
    }
    debugPrint('⚠️ Expanded "$fieldName" list item is not RecordModel: ${first.runtimeType}');
    return null;
  }

  if (expanded is RecordModel) {
    debugPrint('✅ Expanded "$fieldName" is RecordModel: ${expanded.id}');
    return <String, dynamic>{
      'id': expanded.id,
      'collectionId': expanded.collectionId,
      'collectionName': expanded.collectionName,
      'created': expanded.created,
      'updated': expanded.updated,
      ...Map<String, dynamic>.from(expanded.data),
      'expand': expanded.expand,
    };
  }

  // If expand is not present but you received only raw ID somewhere,
  // keep it out of expand and let NotificationModel.fromJson handle raw fields.
  debugPrint('⚠️ Expanded "$fieldName" unexpected type: ${expanded.runtimeType}');
  return null;
}

@override
Future<List<NotificationModel>> getAllNotifications() async {
  try {
    debugPrint('🔄 Fetching notifications (max 30)');

    // Ensure PocketBase client is authenticated
    await _ensureAuthenticated();

    // ✅ Only fetch latest 30 (faster than getFullList)
    final result = await _pocketBaseClient.collection('notifications').getList(
          page: 1,
          perPage: 30,
          sort: '-created',
          expand: 'status,delivery,trip',
        );

    final records = result.items;

    debugPrint('✅ Retrieved ${records.length} notifications from API (page=1, perPage=30)');

    // Debug print for each record (safe + useful)
    for (final record in records) {
      debugPrint('🔔 Notification Record ID: ${record.id}');
      debugPrint('🔔 Created: ${record.created}');
      debugPrint('🔔 Updated: ${record.updated}');
      debugPrint('🔔 Title: ${record.data['title']}');
      debugPrint('🔔 Body: ${record.data['body']}');
      debugPrint('🔔 Is Read: ${record.data['isRead']}');
      debugPrint('🔔 User: ${record.data['user']}');
      debugPrint('🔔 Expand keys: ${record.expand.keys}');
      debugPrint('-----------------------------------');
    }

    // Faster mapping: pre-size list + loop
    final notifications = List<NotificationModel>.filled(
      records.length,
      NotificationModel.empty(),
      growable: false,
    );

    for (var i = 0; i < records.length; i++) {
      notifications[i] = _processNotificationRecord(records[i]);
    }

    return notifications;
  } catch (e) {
    debugPrint('❌ Failed to fetch notifications: ${e.toString()}');

    // Optional auth debug
    try {
      debugPrint('🔐 PB Auth Valid: ${_pocketBaseClient.authStore.isValid}');
      debugPrint(
        '🔐 PB Token (first 10): ${_pocketBaseClient.authStore.token.isNotEmpty ? _pocketBaseClient.authStore.token.substring(0, 10) : 'EMPTY'}',
      );
    } catch (_) {}

    throw ServerException(
      message: 'Failed to fetch notifications: ${e.toString()}',
      statusCode: '500',
    );
  }
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
