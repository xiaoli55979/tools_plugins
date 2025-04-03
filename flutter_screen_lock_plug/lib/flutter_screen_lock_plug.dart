
import 'flutter_screen_lock_plug_platform_interface.dart';

class FlutterScreenLockPlug {
  Future<String?> getPlatformVersion() {
    return FlutterScreenLockPlugPlatform.instance.getPlatformVersion();
  }
}
