import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_screen_lock_plug_platform_interface.dart';

/// An implementation of [FlutterScreenLockPlugPlatform] that uses method channels.
class MethodChannelFlutterScreenLockPlug extends FlutterScreenLockPlugPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_screen_lock_plug');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
