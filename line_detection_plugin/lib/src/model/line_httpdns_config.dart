class LineHttpdnsConfig {
  final String dnsId;
  final String dnsKey;
  final String aesKey;
  final bool debug;
  final bool persistentCache;
  final bool cachedIpEnable;
  final bool useExpiredIpEnable;
  final List<String> lookupMapping;
  final List<String> defaultOss;
  final List<String> defaultDomains;

  // 构造函数
  LineHttpdnsConfig({
    required this.dnsId,
    required this.dnsKey,
    required this.aesKey,
    this.debug = false,
    this.persistentCache = true,
    this.cachedIpEnable = true,
    this.useExpiredIpEnable = false,
    this.lookupMapping = const [],
    this.defaultOss = const [],
    this.defaultDomains = const [],
  });
}
