/// 用于控制表情符号的放大行为 [types.TextMessage].
enum EmojiEnlargementBehavior {
  /// 只有当[types.TextMessage]包含以下内容时，表情符号才会被放大，一个或多个表情符号.
  multi,

  /// 永远不要放大表情符号。.
  never,

  /// 只有当[types.TextMessage]包含以下内容时，表情符号才会被放大，一个表情符号。.
  single,
}
