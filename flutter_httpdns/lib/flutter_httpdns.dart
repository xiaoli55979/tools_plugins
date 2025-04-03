import 'flutter_httpdns_platform_interface.dart';

class FlutterHttpdns {
  /// 初始化
  Future<void> init({
    required String dnsId,
    required String dnsKey,
    required String aesKey,
    debug = false,
    persistentCache = true,
    cachedIpEnable = true,
    useExpiredIpEnable = false,
    lookupMapping,
    defaultOss,
    defaultDomains,
  }) {
    return FlutterHttpdnsPlatform.instance
        .init(dnsId, dnsKey, aesKey, debug, persistentCache, cachedIpEnable, useExpiredIpEnable, lookupMapping, defaultOss, defaultDomains);
  }

  /// IP查询
  Future<dynamic> getAddrByName(String domain) {
    return FlutterHttpdnsPlatform.instance.getAddrByName(domain);
  }

  /// 异步解析多个ip的dns
  Future<Map<String, dynamic>?> getAddrsByNameAsync(List<String> domains) {
    return FlutterHttpdnsPlatform.instance.getAddrsByNameAsync(domains);
  }

  /// 获取配置
  Future<dynamic> getConfig(String configHost, int appId, String configKey) {
    return FlutterHttpdnsPlatform.instance.getConfig(configHost, appId, configKey);
  }

  /// 清除缓存
  Future<dynamic> cleanCache() {
    return FlutterHttpdnsPlatform.instance.cleanCache();
  }

  /// 监听调用错误信息
  void onCallError(ErrorCallback callback) {
    FlutterHttpdnsPlatform.instance.onCallError(callback);
  }
}
