import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

abstract interface class AudioNotificationPermissionRequester {
  Future<bool> request();
}

class PlatformAudioNotificationPermissionRequester
    implements AudioNotificationPermissionRequester {
  const PlatformAudioNotificationPermissionRequester();

  @override
  Future<bool> request() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;

    final permission = Permission.notification;
    if (await permission.isGranted) return true;
    return (await permission.request()).isGranted;
  }
}
