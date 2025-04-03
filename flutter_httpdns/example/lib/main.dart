import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_httpdns/flutter_httpdns.dart';

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
  final _flutterHttpdnsPlugin = FlutterHttpdns();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await _flutterHttpdnsPlugin.init(
        dnsId: "2168", // DNS解析ID
        dnsKey: "zrJcsF61enT49mPz", // DNS解析密钥
        aesKey: "1rb4auhx8kkwRlV6ZgqPhR3ccHUMv0TI", // 加密解密密钥
        debug: kDebugMode, // 是否开启DEBUG
        cachedIpEnable: false,
        // 设置持久化缓存功能
        persistentCache: true,
        // 默认OSS获取线路
        defaultOss: [
          "https://jiubaline.oss-cn-hangzhou.aliyuncs.com/cfg/2/default.json", // 阿里云
          "https://jbline-1323142124.cos.ap-chengdu.myqcloud.com/cfg/2/default.json", // 腾讯
          "https://d2spa8jb92mzym.cloudfront.net/cfg/2/default.json" // 亚马逊
        ],
        defaultDomains: [
          "nlb-ua7svfjpnupgqu51ix.cn-shenzhen.nlb.aliyuncs.com",
          "findme.lianfuspace988.com" // CF线路
        ]);
    _flutterHttpdnsPlugin.onCallError((url, error) {
      print("onCallError_url=$url, error=$error");
    });
    await initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;

    setState(() {
      _platformVersion = "Loading";
    });
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      Map map = await _flutterHttpdnsPlugin.getConfig("findme.lianfuspace988.com", 2, "default") ?? 'Unknown platform version';
      platformVersion = json.encode(map);

      // await _flutterHttpdnsPlugin.getAddrByName("www.qq.com");
    } catch (e) {
      platformVersion = 'Failed to get config.${e.toString()}';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void clearCache() {
    setState(() {
      _platformVersion = "Loading";
    });
    _flutterHttpdnsPlugin.cleanCache();
  }

  Future<void> dnsAnalysis() async {
    setState(() {
      _platformVersion = "Loading";
    });
    // dynamic result = await _flutterHttpdnsPlugin.getAddrByName("www.baidu.com");
    // print("object_result:${result.toString()}");

    List<String> domains = ["example.com", "api.example.com"];
    dynamic result1 = await _flutterHttpdnsPlugin?.getAddrsByNameAsync(["www.baidu.com", "www.baidu.com"]);
    print("object_result1:${result1.toString()}");
  }

  void request() async {}

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
                  child: const Text("获取配置"),
                  onPressed: () {
                    initPlatformState();
                  },
                ),
                ElevatedButton(
                  child: const Text("清除配置"),
                  onPressed: () {
                    clearCache();
                  },
                ),
                ElevatedButton(
                  child: const Text("DNS解析"),
                  onPressed: () {
                    dnsAnalysis();
                  },
                )
              ],
            ),
          )),
    );
  }
}
