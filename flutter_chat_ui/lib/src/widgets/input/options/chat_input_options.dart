import 'package:flutter/material.dart';

@immutable
class ChatInputOptions {
  const ChatInputOptions({
    this.inputClearMode = ChatInputClearMode.always,
    this.keyboardType = TextInputType.multiline,
    this.onTextChanged,
    this.onTextFieldTap,
    this.sendButtonShowMode = SendButtonShowMode.editing,
    this.textEditingController,
    this.autocorrect = false,
    this.autofocus = false,
    this.enableSuggestions = false,
    this.enabled = true,
    this.usesSafeArea = true,
  });

  ///聊天输入框模式 发送后是否清空文案
  final ChatInputClearMode inputClearMode;

  ///聊天输入框文案类型
  final TextInputType keyboardType;

  ///聊天输入框文案变化
  final void Function(String)? onTextChanged;

  ///聊天输入框点击事件
  final VoidCallback? onTextFieldTap;

  ///聊天输入框发送按钮显示模式, 默认editing, 当TextField输入框不为null时显示
  final SendButtonShowMode sendButtonShowMode;

  ///TextField控制器
  final TextEditingController? textEditingController;

  ///文本的自动更正功能 默认为true
  final bool autocorrect;

  ///自动获取焦点 默认false
  final bool autofocus;

  ///文本输入时是否显示预测建议和自动补全功能
  final bool enableSuggestions;

  ///文本输入框是否可输入 默认true
  final bool enabled;

  ///控制[Input]使用SafeArea行为。默认为[true]
  final bool usesSafeArea;
}

///聊天输入框模式 发送后是否清空文案
@immutable
enum ChatInputClearMode {
  ///清空
  always,

  ///不清空
  never,
}

///发送按钮显示模式
@immutable
enum SendButtonShowMode {
  ///始终显示
  always,

  ///只有当TextField不为null时显示
  editing,

  ///始终隐藏
  hidden,
}