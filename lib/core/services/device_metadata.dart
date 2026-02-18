import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<Map<String, dynamic>> buildDeviceMetadata() async {
  final deviceInfo = DeviceInfoPlugin();
  final pkg = await PackageInfo.fromPlatform();

  String platform = 'unknown';
  String deviceType = 'unknown';
  String deviceModel = 'unknown';
  String manufacturer = '';
  String osVersion = '';

  // -----------------------
  // ✅ WEB (optional)
  // -----------------------
  if (kIsWeb) {
    platform = 'web';
    deviceType = 'web';
    // device_info_plus on web is limited; you can add userAgent separately if needed
    return {
      'platform': platform,
      'deviceType': deviceType,
      'deviceModel': deviceModel,
      'manufacturer': manufacturer,
      'osVersion': osVersion,
      'appVersion': '${pkg.version}+${pkg.buildNumber}',
    };
  }

  // -----------------------
  // ✅ MOBILE
  // -----------------------
  if (Platform.isAndroid) {
    final a = await deviceInfo.androidInfo;
    platform = 'android';

    // best-effort classification (works for most devices)
    deviceType = (a.systemFeatures.contains('android.hardware.telephony'))
        ? 'phone'
        : 'tablet';

    deviceModel = a.model;
    manufacturer = a.manufacturer;
    osVersion = a.version.release;
  } else if (Platform.isIOS) {
    final i = await deviceInfo.iosInfo;
    platform = 'ios';
    deviceType = 'phone'; // best-effort; can be ipad too depending on your target
    deviceModel = i.utsname.machine; // e.g. iPhone13,4
    manufacturer = 'Apple';
    osVersion = i.systemVersion;
  }

  // -----------------------
  // ✅ DESKTOP
  // -----------------------
  else if (Platform.isWindows) {
    final w = await deviceInfo.windowsInfo;
    platform = 'windows';
    deviceType = 'desktop';
    deviceModel = (w.computerName.isNotEmpty) ? w.computerName : 'windows-pc';
    osVersion = w.productName; // e.g. Windows 11 Pro
  } else if (Platform.isMacOS) {
    final m = await deviceInfo.macOsInfo;
    platform = 'macos';
    deviceType = 'desktop';
    deviceModel = (m.model.isNotEmpty) ? m.model : 'mac';
    osVersion = m.osRelease;
    manufacturer = 'Apple';
  } else if (Platform.isLinux) {
    final l = await deviceInfo.linuxInfo;
    platform = 'linux';
    deviceType = 'desktop';
    deviceModel = (l.machineId?.isNotEmpty ?? false) ? l.machineId! : 'linux';
    osVersion = l.version ?? '';
  }

  return {
    'platform': platform,
    'deviceType': deviceType,
    'deviceModel': deviceModel,
    'manufacturer': manufacturer,
    'osVersion': osVersion,
    'appVersion': '${pkg.version}+${pkg.buildNumber}',
  };
}
