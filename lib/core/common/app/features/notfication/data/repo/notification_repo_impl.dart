import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/notfication/data/datasources/remote_datasource/notification_remote_datasource.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/notfication/domain/entity/notification_entity.dart';
import 'package:xpro_delivery_admin_app/core/errors/exceptions.dart';
import 'package:xpro_delivery_admin_app/core/typedefs/typedefs.dart';

import '../../../../../../errors/failures.dart';
import '../../domain/repo/notification_repo.dart';

class NotificationRepoImpl implements NotificationRepository {
  const NotificationRepoImpl(this._datasource);

  final NotificationRemoteDatasource _datasource;

  @override
  ResultFuture<void> createNotification({
    required String statusId,
    required String deliveryId,
    required String type,
  }) async {
    try {
      debugPrint('📝 Creating new notification');
      await _datasource.createNotification(
        statusId: statusId,
        deliveryId: deliveryId,
        type: type,
      );
      return const Right(null);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      debugPrint('⚠️ Unexpected Error: ${e.toString()}');
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<void> deleteNotification(String notificationId) async {
    try {
      debugPrint('🗑️ Deleting notification with ID: $notificationId');
      await _datasource.deleteNotification(notificationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<NotificationEntity>> getAllNotifications() async {
    try {
      debugPrint('🔄 Fetching all notifications');
      final remoteNotifications = await _datasource.getAllNotifications();
      return Right(remoteNotifications);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<List<NotificationEntity>> getUnreadNotifications() async {
    try {
      debugPrint('🔄 Fetching unread notifications');
      final remoteNotifications = await _datasource.getUnreadNotifications();
      return Right(remoteNotifications);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<void> markAllAsRead() async {
    try {
      debugPrint('✅ Marking all notifications as read');
      await _datasource.markAllAsRead();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }

  @override
  ResultFuture<void> markAsRead(String notificationId) async {
    try {
      debugPrint('✅ Marking notification $notificationId as read');
      await _datasource.markAsRead(notificationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), statusCode: '500'));
    }
  }
}
