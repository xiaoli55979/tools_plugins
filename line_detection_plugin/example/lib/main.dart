import 'dart:async';

import 'package:flutter/material.dart';
import 'package:line_detection_plugin/line_detection.dart';

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

  @override
  void initState() {
    super.initState();
    initPlatformState();

    NetworkManager.instance.addListener(() {
      setState(() {
        _platformVersion = "network: ${NetworkManager.instance.networkStatus}";
      });
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    platformVersion = 'Failed to get platform version.';

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_platformVersion\n'),
              ElevatedButton(
                child: const Text("网络检测"),
                onPressed: () {
                  initPlatformState();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
