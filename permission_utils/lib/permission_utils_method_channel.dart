import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'permission_utils_platform_interface.dart';

/// An implementation of [PermissionUtilsPlatform] that uses method channels.
class MethodChannelPermissionUtils extends PermissionUtilsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('permission_utils');

  @override
  Future<String?> requestCameraPermission() async {
    final status = await methodChannel.invokeMethod<String>('requestCameraPermission');
    return status;
  }

  @override
  Future<String?> requestAlbumPermission() async {
    final status = await methodChannel.invokeMethod<String>('requestAlbumPermission');
    return status;
  }

  @override
  Future<String?> requestMicrophonePermission() async {
    final status = await methodChannel.invokeMethod<String>('requestMicrophonePermission');
    return status;
  }

  @override
  Future<String?> requestAllPermission() async {
    final status = await methodChannel.invokeMethod<String>('requestAllPermission');
    return status;
  }
}
