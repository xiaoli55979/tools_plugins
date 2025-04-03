import 'package:flutter/material.dart';
import 'package:permission_utils/permission_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _permissionUtilsPlugin = PermissionUtils();

  // platformVersion = await _permissionUtilsPlugin.getPlatformVersion() ?? 'Unknown platform version';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      String? statue = await _permissionUtilsPlugin.requestCameraPermission();
                      print("object_camera:$statue");
                    },
                    child: const Text("请求相机权限"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      String? statue = await _permissionUtilsPlugin.requestAlbumPermission();
                      print("object_album:$statue");
                    },
                    child: const Text("请求相册权限"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      String? statue = await _permissionUtilsPlugin.requestMicrophonePermission();
                      print("object_micro:$statue");
                    },
                    child: const Text("请求麦克风权限"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      String? statue = await _permissionUtilsPlugin.requestAllPermission();
                      print("object_all:$statue");
                    },
                    child: const Text("请求所有权限"),
                  ),
                  const SizedBox(height: 10),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
