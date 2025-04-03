import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_screen_lock_plug_method_channel.dart';

abstract class FlutterScreenLockPlugPlatform extends PlatformInterface {
  /// Constructs a FlutterScreenLockPlugPlatform.
  FlutterScreenLockPlugPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterScreenLockPlugPlatform _instance = MethodChannelFlutterScreenLockPlug();

  /// The default instance of [FlutterScreenLockPlugPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterScreenLockPlug].
  static FlutterScreenLockPlugPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterScreenLockPlugPlatform] when
  /// they register themselves.
  static set instance(FlutterScreenLockPlugPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
