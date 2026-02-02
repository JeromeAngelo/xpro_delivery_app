import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<Map<String, dynamic>> buildDeviceMetadata() async {
  final deviceInfo = DeviceInfoPlugin();
  final pkg = await PackageInfo.fromPlatform();

  String platform = 'unknown';
  String deviceType = 'desktop';
  String deviceModel = 'unknown';
  String manufacturer = '';
  String osVersion = '';

  if (Platform.isWindows) {
    final w = await deviceInfo.windowsInfo;
    platform = 'windows';
    deviceModel = (w.computerName.isNotEmpty) ? w.computerName : 'windows-pc';
    osVersion = w.productName; // e.g. "Windows 11 Pro"
  } else if (Platform.isMacOS) {
    final m = await deviceInfo.macOsInfo;
    platform = 'macos';
    deviceModel = (m.model.isNotEmpty) ? m.model : 'mac';
    osVersion = m.osRelease; // e.g. "14.2.1"
    manufacturer = 'Apple';
  } else if (Platform.isLinux) {
    final l = await deviceInfo.linuxInfo;
    platform = 'linux';
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
