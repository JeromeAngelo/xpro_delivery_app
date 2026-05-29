import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:x_pro_delivery_app/core/utils/device_info_utils.dart';

/// Base class that holds the shared PocketBase client and helper methods
/// used across all auth remote data source implementations.
class AuthRemoteBase {
  const AuthRemoteBase({required PocketBase pocketBaseClient})
    : _pocketBaseClient = pocketBaseClient;

  final PocketBase _pocketBaseClient;

  PocketBase get pocketBaseClient => _pocketBaseClient;

  /// Maps an expanded record (single or list) into a structured map/list.
  dynamic mapExpandedRecord(dynamic record) {
    if (record == null) return null;

    if (record is List) {
      if (record.isEmpty) return [];

      return record.map((r) {
        if (r is RecordModel) {
          final dataMap = Map<String, dynamic>.from(r.data);
          // Ensure 'name' exists
          if (!dataMap.containsKey('name')) {
            dataMap['name'] = r.data['name'] ?? r.id; // fallback to ID
          }
          return {
            'id': r.id,
            'collectionId': r.collectionId,
            'collectionName': r.collectionName,
            'created': formatDateField(r.created),
            'updated': formatDateField(r.updated),
            ...dataMap,
          };
        }

        if (r is Map<String, dynamic>) return r;

        return {'value': r};
      }).toList();
    }

    if (record is RecordModel) {
      final dataMap = Map<String, dynamic>.from(record.data);
      if (!dataMap.containsKey('name')) {
        dataMap['name'] = record.data['name'] ?? record.id;
      }
      return {
        'id': record.id,
        'collectionId': record.collectionId,
        'collectionName': record.collectionName,
        'created': formatDateField(record.created),
        'updated': formatDateField(record.updated),
        ...dataMap,
      };
    }

    if (record is Map<String, dynamic>) return record;

    return null;
  }

  /// Safely formats a date field into ISO8601 string.
  String? formatDateField(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      // Directly return ISO8601 if valid string
      if (dateValue is String) {
        // Attempt ISO 8601 parse
        try {
          final parsed = DateTime.parse(dateValue);
          return parsed.toIso8601String();
        } catch (_) {
          // continue trying other formats below
        }

        // Try common non-ISO date formats
        final possibleFormats = [
          'yyyy-MM-dd HH:mm:ss',
          'yyyy/MM/dd HH:mm:ss',
          'yyyy-MM-dd',
          'yyyy/MM/dd',
          'MM/dd/yyyy',
          'MM-dd-yyyy',
          'dd/MM/yyyy',
          'dd-MM-yyyy',
          'dd MMM yyyy',
          'MMM dd, yyyy',
        ];

        for (final format in possibleFormats) {
          try {
            final parsed = DateFormat(format).parse(dateValue, true);
            return parsed.toIso8601String();
          } catch (_) {}
        }

        // Try parsing numeric string as timestamp
        final numeric = int.tryParse(dateValue);
        if (numeric != null) {
          return timestampToIso(numeric);
        }

        debugPrint('⚠️ Unrecognized date string format: $dateValue');
        return null;
      }

      // If DateTime → ISO string
      if (dateValue is DateTime) {
        return dateValue.toIso8601String();
      }

      // If numeric timestamp (milliseconds or seconds)
      if (dateValue is int) {
        return timestampToIso(dateValue);
      }

      // Fallback: try toString() and parse
      final dateString = dateValue.toString();
      try {
        final parsed = DateTime.parse(dateString);
        return parsed.toIso8601String();
      } catch (_) {
        debugPrint('⚠️ Could not parse date string: $dateString');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ Invalid date format for value: $dateValue, error: $e');
      return null;
    }
  }

  /// Converts timestamps (in ms or s) → ISO8601 string
  String timestampToIso(int timestamp) {
    try {
      // Detect ms vs s
      final isMilliseconds = timestamp > 1000000000000; // ~Sat Nov 20 2001
      final dateTime =
          isMilliseconds
              ? DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true)
              : DateTime.fromMillisecondsSinceEpoch(
                timestamp * 1000,
                isUtc: true,
              );
      return dateTime.toIso8601String();
    } catch (e) {
      debugPrint('⚠️ Failed to convert timestamp: $timestamp → $e');
      return DateTime.now().toIso8601String(); // fallback
    }
  }

  /// Records authentication log with device information to authLogs collection
  Future<void> recordAuthLog({
    required String userId,
    required String loginTime,
  }) async {
    try {
      debugPrint('🔐 Recording auth log for user: $userId');

      // Get device information (IP and IMEI/Device ID)
      final deviceInfo = await DeviceInfoUtils.getDeviceAuthInfo();

      debugPrint('📱 Device Info: $deviceInfo');

      // Prepare auth log data
      final authLogData = {
        'user': userId,
        'loginTime': loginTime,
        'deviceId': deviceInfo['deviceId'] ?? 'unknown',
        'ipAddress': deviceInfo['localIp'] ?? 'unknown',
        'platform': deviceInfo['platform'] ?? 'unknown',
        'platformVersion': deviceInfo['platformVersion'] ?? 'unknown',
        'deviceModel':
            deviceInfo['deviceModel'] ??
            deviceInfo['deviceSystemVersion'] ??
            'unknown',
        'deviceBrand': deviceInfo['deviceBrand'] ?? 'unknown',
      };

      debugPrint('📝 Auth Log Data: $authLogData');

      // Record to authLogs collection
      await _pocketBaseClient.collection('authLogs').create(body: authLogData);

      debugPrint('✅ Auth log recorded successfully for user: $userId');
      debugPrint('   🕓 Login Time: $loginTime');
      debugPrint('   📱 Device ID: ${authLogData['deviceId']}');
      debugPrint('   🌐 IP Address: ${authLogData['ipAddress']}');
      debugPrint(
        '   📲 Platform: ${authLogData['platform']} ${authLogData['platformVersion']}',
      );
    } catch (e) {
      // Non-critical error - don't fail the login, just log the issue
      debugPrint('⚠️ Failed to record auth log (non-critical): $e');
      // Optionally record a minimal log entry
      try {
        await _pocketBaseClient
            .collection('authLogs')
            .create(
              body: {
                'user': userId,
                'loginTime': loginTime,
                'deviceId': 'unknown',
                'ipAddress': 'unknown',
                'error': 'Failed to capture device info: $e',
              },
            );
      } catch (fallbackError) {
        debugPrint('⚠️ Even fallback auth log failed: $fallbackError');
      }
    }
  }
}
