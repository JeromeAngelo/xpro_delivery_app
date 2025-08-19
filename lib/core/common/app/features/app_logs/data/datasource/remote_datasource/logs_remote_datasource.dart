import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';
import 'package:x_pro_delivery_app/core/enums/log_level.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class LogsRemoteDataSource {
  /// Upload logs to PocketBase
  Future<List<String>> uploadLogsToRemote(List<LogEntryEntity> logs);
  
  /// Check if remote logging is available
  Future<bool> isRemoteLoggingAvailable();
  
  /// Get logs from remote (for cross-device sync)
  Future<List<LogEntryEntity>> getLogsFromRemote({
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  });
}

class LogsRemoteDataSourceImpl implements LogsRemoteDataSource {
  const LogsRemoteDataSourceImpl({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  @override
  Future<List<String>> uploadLogsToRemote(List<LogEntryEntity> logs) async {
    try {
      debugPrint('🔄 Uploading ${logs.length} logs to remote');
      
      List<String> uploadedLogIds = [];
      int successCount = 0;
      int errorCount = 0;

      for (var log in logs) {
        try {
          // Create log record in PocketBase
          final record = await _pocketBaseClient
              .collection('appLogs')
              .create(body: {
                'userId': log.userId ?? '',
                'category': log.category?.name ?? 'general',
                'level': log.level?.name ?? 'info',
                'message': log.message ?? '',
                'details': log.details ?? '',
                'timestamp': log.timestamp?.toUtc().toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
                'tripId': log.tripId ?? '',
                'deliveryId': log.deliveryId ?? '',
                'stackTrace': log.stackTrace ?? '',
                
                'localLogId': log.id ?? '', // Store local ID for reference
              });

          uploadedLogIds.add(log.id ?? '');
          successCount++;
          debugPrint('✅ Uploaded log: ${record.id}');
        } catch (e) {
          errorCount++;
          debugPrint('❌ Failed to upload log ${log.id}: $e');
          // Continue with other logs even if one fails
        }
      }

      debugPrint('📊 Upload summary: $successCount succeeded, $errorCount failed');
      
      if (successCount == 0) {
        throw ServerException(
          message: 'No logs were uploaded successfully',
          statusCode: '500',
        );
      }

      return uploadedLogIds;
    } catch (e) {
      debugPrint('❌ Failed to upload logs to remote: ${e.toString()}');
      throw ServerException(
        message: 'Failed to upload logs to remote: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  @override
  Future<bool> isRemoteLoggingAvailable() async {
    try {
      // Try to make a simple request to check if remote is available
      await _pocketBaseClient.health.check();
      debugPrint('✅ Remote logging service is available');
      return true;
    } catch (e) {
      debugPrint('⚠️ Remote logging service is not available: $e');
      return false;
    }
  }

  @override
  Future<List<LogEntryEntity>> getLogsFromRemote({
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      debugPrint('🔄 Fetching logs from remote');
      
      // Build filter query
      List<String> filters = [];
      
      if (userId != null && userId.isNotEmpty) {
        filters.add('userId = "$userId"');
      }
      
      if (fromDate != null) {
        filters.add('timestamp >= "${fromDate.toUtc().toIso8601String()}"');
      }
      
      if (toDate != null) {
        filters.add('timestamp <= "${toDate.toUtc().toIso8601String()}"');
      }

      final filterString = filters.isNotEmpty ? filters.join(' && ') : '';
      
      final result = await _pocketBaseClient
          .collection('appLogs')
          .getFullList(
            filter: filterString,
            sort: '-timestamp',
          );

      debugPrint('✅ Retrieved ${result.length} logs from remote');

      List<LogEntryEntity> remoteLogs = [];

      for (var record in result) {
        final log = LogEntryEntity(
          id: record.data['localLogId']?.toString() ?? record.id,
          userId: record.data['userId']?.toString(),
          category: _parseLogCategory(record.data['category']),
          level: _parseLogLevel(record.data['level']),
          message: record.data['message']?.toString(),
          details: record.data['details']?.toString(),
          timestamp: _parseDate(record.data['timestamp']),
          tripId: record.data['tripId']?.toString(),
          deliveryId: record.data['deliveryId']?.toString(),
          stackTrace: record.data['stackTrace']?.toString(),
        );
        
        remoteLogs.add(log);
      }

      return remoteLogs;
    } catch (e) {
      debugPrint('❌ Failed to fetch logs from remote: ${e.toString()}');
      throw ServerException(
        message: 'Failed to fetch logs from remote: ${e.toString()}',
        statusCode: '500',
      );
    }
  }

  // Helper method to parse date strings
  DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('⚠️ Failed to parse date "$value": $e');
      return null;
    }
  }

  // Helper method to parse log level enum
  LogLevel? _parseLogLevel(dynamic value) {
    if (value == null) return null;
    try {
      final levelString = value.toString().toLowerCase();
      switch (levelString) {
        case 'info':
          return LogLevel.info;
        case 'success':
          return LogLevel.success;
        case 'warning':
          return LogLevel.warning;
        case 'error':
          return LogLevel.error;
        case 'debug':
          return LogLevel.debug;
        default:
          return LogLevel.info;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to parse log level "$value": $e');
      return LogLevel.info;
    }
  }

  // Helper method to parse log category enum
  LogCategory? _parseLogCategory(dynamic value) {
    if (value == null) return null;
    try {
      final categoryString = value.toString().toLowerCase();
      switch (categoryString) {
        case 'authentication':
          return LogCategory.authentication;
        case 'tripmanagement':
        case 'trip_management':
          return LogCategory.tripManagement;
        case 'deliveryupdate':
        case 'delivery_update':
          return LogCategory.deliveryUpdate;
        case 'deliveryreceipt':
        case 'delivery_receipt':
          return LogCategory.deliveryReceipt;
        case 'sync':
          return LogCategory.sync;
        case 'network':
          return LogCategory.network;
        case 'general':
        default:
          return LogCategory.general;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to parse log category "$value": $e');
      return LogCategory.general;
    }
  }
}
