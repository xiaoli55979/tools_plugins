import 'package:line_detection_plugin/src/tools/line_tools.dart';

class LinkInfo {
  final String url;
  final int duration;
  final bool available;
  bool main = false;

  LinkInfo({
    required this.url,
    required this.duration,
  }) : available = duration < 12000; // 根据 duration 自动设置 available

  // 从 Map 创建 LinkInfo 实例
  factory LinkInfo.fromMap(Map<String, dynamic> map) {
    final duration = map['duration'] as int;
    return LinkInfo(
      url: LineTools.formatUrl(map['url']),
      duration: duration,
    );
  }

  // 将 LinkInfo 实例转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'duration': duration,
      'available': available,
      'main': main,
    };
  }
}
