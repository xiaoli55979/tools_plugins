import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_httpdns_platform_interface.dart';

/// An implementation of [FlutterHttpdnsPlatform] that uses method channels.
class MethodChannelFlutterHttpdns extends FlutterHttpdnsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_httpdns');
  @visibleForTesting
  final eventChannel = const EventChannel('flutter_httpdns_event');

  void onCallError(ErrorCallback callback) {
    eventChannel.receiveBroadcastStream().listen((obj) {
      callback(obj['url'], obj['error']);
    });
  }

  @override
  Future<void> init(String dnsId, String dnsKey, String aesKey, bool debug, bool persistentCache, bool cachedIpEnable,
      bool useExpiredIpEnable, dynamic lookupMapping, List<String> defaultOss, List<String> defaultDomains) async {
    await methodChannel.invokeMethod<String>('init', {
      'dnsId': dnsId,
      'dnsKey': dnsKey,
      'aesKey': aesKey,
      'debug': debug,
      'lookupMapping': lookupMapping ?? {},
      'defaultOss': defaultOss,
      'defaultDomains': defaultDomains,
      'persistentCache': persistentCache,
      'cachedIpEnable': cachedIpEnable,
      'useExpiredIpEnable': useExpiredIpEnable
    });
  }

  @override
  Future<dynamic> getAddrByName(String domain) async {
    final ips = await methodChannel.invokeMethod<dynamic>('getAddrByNameAsync', {"domain": domain});
    return ips;
  }

  /// 异步解析dns
  @override
  Future<Map<String, dynamic>?> getAddrsByNameAsync(List<String> domains) async {
    final Map<Object?, Object?>? ipsMap = await methodChannel.invokeMethod('getAddrsByNameAsync', {"domains": domains});

    if (ipsMap == null) return null;

    // 解析成 Map<String, dynamic>
    return ipsMap.cast<String, dynamic>();
  }

  @override
  Future<dynamic> getConfig(String configHost, int appId, String configKey) async {
    final cfg = await methodChannel.invokeMethod<dynamic>('getConfig', {"configHost": configHost, "appId": appId, "configKey": configKey});
    return cfg;
  }

  @override
  Future<dynamic> cleanCache() async {
    await methodChannel.invokeMethod<dynamic>('cleanCache');
  }
}
