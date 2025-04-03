import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_lock_plug/flutter_screen_lock_plug.dart';
import 'package:flutter_screen_lock_plug/lock_screen_manager.dart';

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
  final _flutterScreenLockPlugPlugin = FlutterScreenLockPlug();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _flutterScreenLockPlugPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Builder(
            builder: (BuildContext context) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () {
                      // 显示锁屏
                      LockScreenManager.show(
                        password: "123456",
                        context: context,
                        errorMaxPop: true,
                        onUnlockSuccess: () {
                          print("object_onUnlockSuccess");
                        },
                        onErrorExceeded: () {
                          print("object_onErrorExceeded");
                        },
                      );
                    },
                    child: const Text("锁屏验证"),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
