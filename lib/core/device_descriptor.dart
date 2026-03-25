import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceDescriptor {
  final String deviceName;
  final String deviceType;
  final String platform;
  final String? userAgent;

  const DeviceDescriptor({
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    this.userAgent,
  });

  Map<String, dynamic> toJson() => {
    'device_name': deviceName,
    'device_type': deviceType,
    'platform': platform,
    if (userAgent != null && userAgent!.isNotEmpty) 'user_agent': userAgent,
  };
}

Future<DeviceDescriptor> resolveCurrentDeviceDescriptor() async {
  final plugin = DeviceInfoPlugin();

  if (kIsWeb) {
    final info = await plugin.webBrowserInfo;
    final browser = _browserName(info.browserName.name);
    return DeviceDescriptor(
      deviceName: '$browser Tarayıcı',
      deviceType: 'web',
      platform: browser,
      userAgent: info.userAgent,
    );
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      final info = await plugin.androidInfo;
      return DeviceDescriptor(
        deviceName: '${info.brand} ${info.model}'.trim(),
        deviceType: 'mobile',
        platform: 'Android ${info.version.release}',
      );
    case TargetPlatform.iOS:
      final info = await plugin.iosInfo;
      return DeviceDescriptor(
        deviceName: info.utsname.machine.isNotEmpty
            ? info.utsname.machine
            : info.name,
        deviceType: 'mobile',
        platform: 'iOS ${info.systemVersion}',
      );
    case TargetPlatform.windows:
      final info = await plugin.windowsInfo;
      return DeviceDescriptor(
        deviceName: info.computerName,
        deviceType: 'desktop',
        platform: 'Windows',
      );
    case TargetPlatform.macOS:
      final info = await plugin.macOsInfo;
      return DeviceDescriptor(
        deviceName: info.computerName,
        deviceType: 'desktop',
        platform: 'macOS ${info.osRelease}',
      );
    case TargetPlatform.linux:
      final info = await plugin.linuxInfo;
      return DeviceDescriptor(
        deviceName: info.prettyName,
        deviceType: 'desktop',
        platform: 'Linux',
      );
    case TargetPlatform.fuchsia:
      return const DeviceDescriptor(
        deviceName: 'Fuchsia Cihazı',
        deviceType: 'unknown',
        platform: 'Fuchsia',
      );
  }
}

String _browserName(String raw) {
  switch (raw.toLowerCase()) {
    case 'chrome':
      return 'Chrome';
    case 'firefox':
      return 'Firefox';
    case 'edge':
      return 'Edge';
    case 'safari':
      return 'Safari';
    default:
      return 'Tarayıcı';
  }
}
