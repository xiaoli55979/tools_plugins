import 'package:flutter_test/flutter_test.dart';
import 'package:permission_utils/permission_utils.dart';
import 'package:permission_utils/permission_utils_method_channel.dart';
import 'package:permission_utils/permission_utils_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPermissionUtilsPlatform with MockPlatformInterfaceMixin implements PermissionUtilsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PermissionUtilsPlatform initialPlatform = PermissionUtilsPlatform.instance;

  test('$MethodChannelPermissionUtils is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPermissionUtils>());
  });

  test('getPlatformVersion', () async {
    PermissionUtils permissionUtilsPlugin = PermissionUtils();
    MockPermissionUtilsPlatform fakePlatform = MockPermissionUtilsPlatform();
    PermissionUtilsPlatform.instance = fakePlatform;

    // expect(await permissionUtilsPlugin.getPlatformVersion(), '42');
  });
}
