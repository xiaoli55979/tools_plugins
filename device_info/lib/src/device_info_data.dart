import 'package_data.dart';

class DeviceInfo {
  const DeviceInfo({
    required this.platform,
    required this.platformVersion,
    required this.architecture,
    required this.model,
    required this.brand,
    required this.version,
    required this.mobile,
    required this.package,
    required this.device,
    required this.deviceId,
    required this.isPhysicalDevice, // 是否是真机设备
    required this.isRoot, /// 安卓:是否root  ios:是否越狱了
    this.displaySizeInches,
  });

  final String platform;
  final String platformVersion;
  final String architecture;
  final String model;
  final String brand;
  final String version;
  final bool mobile;
  final String device;
  final String deviceId;
  final bool isPhysicalDevice;
  final double? displaySizeInches;
  final bool isRoot;
  final PackageData package;
}
