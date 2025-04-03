import 'permission_utils_platform_interface.dart';

class PermissionUtils {
  Future<String?> requestCameraPermission() {
    return PermissionUtilsPlatform.instance.requestCameraPermission();
  }

  Future<String?> requestAlbumPermission() {
    return PermissionUtilsPlatform.instance.requestAlbumPermission();
  }

  Future<String?> requestMicrophonePermission() {
    return PermissionUtilsPlatform.instance.requestMicrophonePermission();
  }

  Future<String?> requestAllPermission() {
    return PermissionUtilsPlatform.instance.requestAllPermission();
  }
}
