class LineTools {
  // 私有构造函数
  LineTools._privateConstructor();

  // 单例实例
  static final LineTools _instance = LineTools._privateConstructor();

  factory LineTools() {
    return _instance;
  }

  ///  实现域名自动加上https
  static String formatUrl(String domain) {
    if (domain.isEmpty) {
      return "";
    }
    // 正则表达式检查是否是IP地址
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');

    // 检查域名是否以http或https开头
    if (domain.startsWith('http://') || domain.startsWith('https://')) {
      return domain;
    }

    // 如果是IP地址，则添加http前缀
    if (ipRegex.hasMatch(domain)) {
      return 'http://$domain';
    }

    // 默认添加https前缀
    return 'https://$domain';
  }

  /// 域名异常头部
  static String extractHost(String url) {
    String httpUrl = formatUrl(url);
    Uri uri = Uri.parse(httpUrl);
    return uri.host;
  }
}
