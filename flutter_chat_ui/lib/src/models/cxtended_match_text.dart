import 'dart:ui';

import 'package:flutter_parsed_text/flutter_parsed_text.dart';

class ExtendedMatchText extends MatchText {
  /// 长按回调，返回匹配的文本和长按时的坐标
  final Function(String text, Offset position)? onLongPress;

  ExtendedMatchText({
    super.type = ParsedType.CUSTOM,
    super.pattern,
    super.style,
    super.onTap,
    super.renderText,
    super.renderWidget,
    this.onLongPress,
  });
}
