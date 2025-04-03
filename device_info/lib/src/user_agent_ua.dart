import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'device_info_data.dart';
import 'package_data.dart';

/// e.g.. User-Agent: SampleApp/1.0.0 (Android 11; Pixel 4 XL; coral; arm64-v8a)
/// e.g.. User-Agent: SampleApp/1.0.0 (iOS 14.2; iPhone; iPhone13,4; arm64v8)
String _userAgent(Map<dynamic, dynamic> map) {
  return '${map['brand']}/${map['version']} (${map['platform']} ${map['platformVersion']}; ${map['model']}; ${map['device']}; ${map['architecture']})';
}

/// e.g  808/1.1.5-1-48 (iOS 16.4.1; iPhone_Physics:true; iPhone14,7; arm64e)
String _userAgentHead(String header, Map<dynamic, dynamic> map) {
  return '$header (${map['platform']} ${map['platformVersion']}; ${map['model']}; ${map['device']}; ${map['architecture']})';
}

Future<String> userAgent() async {
  final map = await const MethodChannel('com.abg.device_info').invokeMethod('getInfo') as Map<dynamic, dynamic>;
  DeviceInfo deviceInfo = await getDeviceInfo();
  map['model'] = "${map['model']}_Physics:${deviceInfo.isPhysicalDevice}";
  return _userAgent(map);
}

Future<String> userAgentHead(String header) async {
  final map = await const MethodChannel('com.abg.device_info').invokeMethod('getInfo') as Map<dynamic, dynamic>;
  DeviceInfo deviceInfo = await getDeviceInfo();
  map['model'] = "${map['model']}_Physics:${deviceInfo.isPhysicalDevice}";
  return _userAgentHead(header, map);
}

Future<DeviceInfo> getDeviceInfo() async {
  final map = await const MethodChannel('com.abg.device_info').invokeMethod('getInfo') as Map<dynamic, dynamic>;
  DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  bool isAndroid = false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      isAndroid = true;
      break;
    default:
      isAndroid = false;
      break;
  }

  bool isPhysicalDevice = false;
  double displaySizeInches = 0.0;
  bool isRoot = false;
  if (isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    isPhysicalDevice = androidInfo.isPhysicalDevice;

    // 获取屏幕尺寸（单位：像素）
    final double screenWidth = window.physicalSize.width;
    final double screenHeight = window.physicalSize.height;
    final double pixelRatio = window.devicePixelRatio;

    // 计算英寸（对角线尺寸）
    final double widthInches = screenWidth / pixelRatio / 160; // 160 是 Android DPI 标准
    final double heightInches = screenHeight / pixelRatio / 160;
    displaySizeInches = (sqrt(widthInches * widthInches + heightInches * heightInches) * 10).roundToDouble() / 10;
  } else {
    IosDeviceInfo iosdeviceinfo = await deviceInfoPlugin.iosInfo;
    isPhysicalDevice = iosdeviceinfo.isPhysicalDevice;
  }

  return DeviceInfo(
      deviceId: map['deviceId'],
      platform: map['platform'],
      platformVersion: map['platformVersion'],
      architecture: map['architecture'],
      model: map['model'],
      brand: map['brand'],
      version: map['version'],
      mobile: isPhysicalDevice,
      device: map['device'],
      isPhysicalDevice: isPhysicalDevice,
      displaySizeInches: displaySizeInches,
      isRoot: map['isRoot'],
      package: PackageData(
        appName: map['appName'],
        appVersion: map['appVersion'],
        packageName: map['packageName'],
        buildNumber: map['buildNumber'],
      ));
}

/// 获取安卓设备信息
Future<AndroidDeviceInfo> getAndroidDeviceInfo() async {
  DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  AndroidDeviceInfo androdeviceInfoplus = await deviceInfoPlugin.androidInfo;
  return androdeviceInfoplus;
}

Future<Map<String, String>> userAgentClientHintsHeader() async {
  final map = await const MethodChannel('com.abg.device_info').invokeMethod('getInfo') as Map<dynamic, dynamic>;
  return {
    'User-Agent': _userAgent(map),
    'Sec-CH-UA-Arch': map['architecture'],
    'Sec-CH-UA-Model': map['model'],
    'Sec-CH-UA-Platform': map['platform'],
    'Sec-CH-UA-Platform-Version': map['platformVersion'],
    'Sec-CH-UA': '"${map['appName']}"; v="${map['appVersion']}"',
    'Sec-CH-UA-Full-Version': map['appVersion'],
    'Sec-CH-UA-Mobile': map['mobile'] ? '?1' : '?0',
  };
}
