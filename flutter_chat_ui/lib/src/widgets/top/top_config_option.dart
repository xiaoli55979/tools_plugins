import 'package:flutter/material.dart';

class TopConfigOption {
  /// 是否显示历史消息按钮
  final bool showHistory;

  /// 点击后是否滚动到顶部
  final bool scroToTop;

  /// 是否处于加载中状态
  final bool loading;

  /// 加载中颜色
  final Color loadingColor;

  /// 显示的内容组件
  final Widget content;

  /// 内边距
  final EdgeInsets padding;

  /// 高度
  final double height;

  /// 点击回调
  final VoidCallback? onTap;

  const TopConfigOption({
    this.showHistory = false,
    this.scroToTop = false,
    this.loading = false,
    this.height = 25.0,
    this.loadingColor = Colors.blue,
    this.content = const Text(
      "加载历史消息",
      style: TextStyle(
        fontSize: 14,
      ),
    ),
    this.padding = const EdgeInsets.all(5),
    this.onTap,
  });
}
