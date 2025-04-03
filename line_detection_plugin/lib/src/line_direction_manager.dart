import 'package:flutter_httpdns/flutter_httpdns.dart';

import '../line_detection.dart';

/// 线路管理主插件入口
class LineDirectionManager {
  // 单例实例
  static final LineDirectionManager _instance = LineDirectionManager._privateConstructor();

  // 提供单例访问方式
  static LineDirectionManager get instance => _instance;

  // 私有构造函数
  LineDirectionManager._privateConstructor();

  /// 基础线路
  String _baseUrl = '';

  /// 当前 API 可用域名
  List<String> _endpoints = [];

  /// httpDns 插件
  FlutterHttpdns? _httpLinesPlugs;

  /// 获取 httpDns 插件实例
  FlutterHttpdns? get httpLinesPlugs => _httpLinesPlugs;

  /// 获取当前 baseUrl
  String get baseUrl => _baseUrl;

  /// 更新 baseUrl
  set baseUrl(String url) {
    _baseUrl = url;
  }

  /// 获取可用域名
  List<String> get endpoints => _endpoints;

  /// 初始化方法
  /// 初始化方法
  static Future<LineDirectionManager> init({
    required LineHttpdnsConfig httpDnsConfig,
    required void Function(String url, dynamic error) onCallError,
  }) async {
    LinkInfoCacheManager cacheManager = LinkInfoCacheManager();
    String dnsId = await cacheManager.getCacheDnsId(httpDnsConfig.dnsId);
    String dnsKey = await cacheManager.getCacheDnsToken(httpDnsConfig.dnsKey);

    // 初始化 httpDns 插件
    final _plugin = FlutterHttpdns();
    await _plugin.init(
      dnsId: dnsId,
      dnsKey: dnsKey,
      aesKey: httpDnsConfig.aesKey,
      debug: httpDnsConfig.debug,
      cachedIpEnable: httpDnsConfig.cachedIpEnable,
      persistentCache: httpDnsConfig.persistentCache,
      defaultOss: httpDnsConfig.defaultOss,
      defaultDomains: httpDnsConfig.defaultDomains,
    );
    _instance._httpLinesPlugs = _plugin;

    // 设置错误回调
    _plugin.onCallError(onCallError);

    return _instance;
  }

  /// 更新 Base URL
  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// 更新可用域名
  void updateEndpoints(List<String> newEndpoints) {
    _endpoints = newEndpoints;
  }
}
