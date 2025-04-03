import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_httpdns_method_channel.dart';

typedef void ErrorCallback(String url, String error);

abstract class FlutterHttpdnsPlatform extends PlatformInterface {
  /// Constructs a FlutterHttpdnsPlatform.
  FlutterHttpdnsPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterHttpdnsPlatform _instance = MethodChannelFlutterHttpdns();

  /// The default instance of [FlutterHttpdnsPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterHttpdns].
  static FlutterHttpdnsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterHttpdnsPlatform] when
  /// they register themselves.
  static set instance(FlutterHttpdnsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> init(String dnsId, String dnsKey, String aesKey, bool debug, bool persistentCache, bool cachedIpEnable,
      bool useExpiredIpEnable, dynamic lookupMapping, List<String> defaultOss, List<String> defaultDomains) {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<dynamic> getAddrByName(String domain) {
    throw UnimplementedError('getAddrByName() has not been implemented.');
  }

  Future<Map<String, dynamic>?> getAddrsByNameAsync(List<String> domains) {
    throw UnimplementedError('getAddrsByNameAsync() has not been implemented.');
  }

  Future<dynamic> getConfig(String configHost, int appId, String configKey) {
    throw UnimplementedError('getConfig() has not been implemented.');
  }

  Future<dynamic> cleanCache() {
    throw UnimplementedError('cleanCache() has not been implemented.');
  }

  void onCallError(ErrorCallback callback);
}
