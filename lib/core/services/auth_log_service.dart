import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import 'device_metadata.dart'; // your helper

Future<void> recordAuthLog({
  required PocketBase pb,
  required String userId,
  required String loginMethod, // 'manual' | 'auto'
}) async {
  try {
    final loginTime = DateTime.now().toUtc().toIso8601String();
    final meta = await buildDeviceMetadata();

    final body = <String, dynamic>{
      'user': userId,
      'loginTime': loginTime,
      'loginMethod': loginMethod,

      'platform': meta['platform'] ?? 'unknown',
      'deviceType': meta['deviceType'] ?? 'unknown',
      'deviceModel': meta['deviceModel'] ?? 'unknown',
      'manufacturer': meta['manufacturer'] ?? 'unknown',
      'osVersion': meta['osVersion'] ?? 'unknown',
      'appVersion': meta['appVersion'] ?? 'unknown',
    };

    debugPrint('🧾 authLogs body => $body');

    await pb.collection('authLogs').create(body: body);
    debugPrint('✅ authLogs saved');
  } catch (e) {
    debugPrint('⚠️ Failed to save authLogs: $e');
  }
}
