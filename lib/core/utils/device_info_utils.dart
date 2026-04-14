import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Utility class to get device information including IMEI/ID and IP address
class DeviceInfoUtils {
  DeviceInfoUtils._();

  /// Get the device ID (IMEI for Android, identifierForVendor for iOS)
  static Future<String> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Use Android ID as IMEI alternative (more reliable than IMEI on modern Android)
        deviceId = androidInfo.id;
        debugPrint('📱 Android Device ID: $deviceId');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        debugPrint('📱 iOS Device ID: $deviceId');
      }

      return deviceId;
    } catch (e) {
      debugPrint('❌ Failed to get device ID: $e');
      return 'unknown';
    }
  }

  /// Get the device's local IP address
  static Future<String> getLocalIpAddress() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      debugPrint('🌐 Local IP Address: $wifiIP');
      return wifiIP ?? 'unknown';
    } catch (e) {
      debugPrint('❌ Failed to get local IP: $e');
      return 'unknown';
    }
  }

  /// Get device information as a map for logging
  static Future<Map<String, String>> getDeviceAuthInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final info = NetworkInfo();

      final Map<String, String> authInfo = {
        'deviceId': 'unknown',
        'localIp': 'unknown',
        'platform': Platform.operatingSystem,
        'platformVersion': Platform.operatingSystemVersion,
      };

      // Get device ID
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        authInfo['deviceId'] = androidInfo.id;
        authInfo['deviceModel'] = androidInfo.model;
        authInfo['deviceBrand'] = androidInfo.brand;
        authInfo['platformVersion'] = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        authInfo['deviceId'] = iosInfo.identifierForVendor ?? 'unknown';
        authInfo['deviceModel'] = iosInfo.model;
        authInfo['deviceSystemVersion'] = iosInfo.systemVersion;
      }

      // Get local IP
      authInfo['localIp'] = await info.getWifiIP() ?? 'unknown';

      debugPrint('📱 Device Auth Info: $authInfo');
      return authInfo;
    } catch (e) {
      debugPrint('❌ Failed to get device auth info: $e');
      return {
        'deviceId': 'unknown',
        'localIp': 'unknown',
        'platform': Platform.operatingSystem,
        'platformVersion': Platform.operatingSystemVersion,
        'error': e.toString(),
      };
    }
  }
}
