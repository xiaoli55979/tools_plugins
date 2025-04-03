import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'permission_utils_method_channel.dart';

abstract class PermissionUtilsPlatform extends PlatformInterface {
  /// Constructs a PermissionUtilsPlatform.
  PermissionUtilsPlatform() : super(token: _token);

  static final Object _token = Object();

  static PermissionUtilsPlatform _instance = MethodChannelPermissionUtils();

  /// The default instance of [PermissionUtilsPlatform] to use.
  ///
  /// Defaults to [MethodChannelPermissionUtils].
  static PermissionUtilsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PermissionUtilsPlatform] when
  /// they register themselves.
  static set instance(PermissionUtilsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> requestCameraPermission() {
    throw UnimplementedError('requestCameraPermission() has not been implemented.');
  }

  Future<String?> requestAlbumPermission() {
    throw UnimplementedError('requestAlbumPermission() has not been implemented.');
  }

  Future<String?> requestMicrophonePermission() {
    throw UnimplementedError('requestMicrophonePermission() has not been implemented.');
  }

  Future<String?> requestAllPermission() {
    throw UnimplementedError('requestAllPermission() has not been implemented.');
  }
}
