import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:visibility_detector/visibility_detector.dart';

import '../../options/bubble_rtl_alignment.dart';
import '../../options/emoji_enlargement_behavior.dart';
import '../../util.dart';
import '../state/inherited_chat_theme.dart';
import '../state/inherited_user.dart';
import 'file_message.dart';
import 'image_message.dart';
import 'message_status.dart';
import 'text_message.dart';
import 'user_avatar.dart';

/*消息外部包裹樣式、头像、名称、消息状态构造器*/
typedef BubbleBuilder = Widget Function(Widget child, {required types.Message message, required bool nextMessageInGroup});
typedef AvatarBuilder = Widget Function(types.User author, bool isMultipleSelect, types.Message msg);
typedef NameBuilder = Widget Function(types.User);
typedef CustomStatusBuilder = Widget Function(types.Message message, {required BuildContext context});

/*消息内容构造器*/
/// ShowName 是否显示名称.
typedef TextMessageBuilder = Widget Function(types.TextMessage, {required int messageWidth, required bool showName});
typedef ImageMessageBuilder = Widget Function(types.ImageMessage, {required int messageWidth});
typedef FileMessageBuilder = Widget Function(types.FileMessage, {required int messageWidth});
typedef VideoMessageBuilder = Widget Function(types.VideoMessage, {required int messageWidth});
typedef AudioMessageBuilder = Widget Function(types.AudioMessage, {required int messageWidth});
typedef CustomMessageBuilder = Widget Function(types.CustomMessage, {required int messageWidth});

/*交互事件*/
typedef OnAvatarTap = void Function(types.User);
typedef OnMessageTap = void Function(BuildContext context, types.Message);
typedef OnMessageDoubleTap = void Function(BuildContext context, types.Message);
typedef OnMessageLongPress = void Function(BuildContext context, types.Message, LongPressStartDetails details);
typedef OnMessageStatusTap = void Function(BuildContext context, types.Message);
typedef OnMessageStatusLongPress = void Function(BuildContext context, types.Message);
typedef OnMessageVisibilityChanged = void Function(types.Message, bool visible);
typedef OnPreviewDataFetched = void Function(types.TextMessage, types.PreviewData);

/// 消息UI(包含头像、消息体样式、消息发送状态等).
class MessageView extends StatelessWidget {

  MessageView({
    super.key,
    required this.message,
    required this.messageWidth,
    required this.roundBorder,
    required this.showUserAvatars,
    required this.showAvatar,
    required this.showName,
    required this.showStatus,
    required this.isLeftStatus,
    required this.textMessageOptions,
    required this.usePreviewData,
    required this.emojiEnlargementBehavior,
    required this.hideBackgroundOnEmojiMessages,
    this.bubbleBuilder,
    this.bubbleRtlAlignment,
    this.avatarBuilder,
    this.nameBuilder,
    this.customStatusBuilder,
    this.textMessageBuilder,
    this.imageMessageBuilder,
    this.imageProviderBuilder,
    this.imageHeaders,
    this.fileMessageBuilder,
    this.videoMessageBuilder,
    this.audioMessageBuilder,
    this.customMessageBuilder,
    this.onAvatarTap,
    this.onMessageTap,
    this.onMessageDoubleTap,
    this.onMessageLongPress,
    this.onMessageStatusTap,
    this.onMessageStatusLongPress,
    this.onMessageVisibilityChanged,
    this.onPreviewDataFetched,
    this.userAgent,
    this.isMultipleSelect = false,
    this.isSelected = false,
    this.onMultipleTap,
    this.onSelectTap,
  });

  /// 消息实体.
  final types.Message message;

  /// 最大消息宽度.
  final int messageWidth;

  /// 消息是否圆角.
  final bool roundBorder;

  /// 是否显示头像. 默认false
  final bool showUserAvatars;

  /// 是否显示头像. ps：false时，有默认占位.
  final bool showAvatar;

  /// 是否显示名称.
  final bool showName;

  /// 是否显示消息状态.
  final bool showStatus;

  /// 状态消息在左侧还是右侧，默认false.
  final bool isLeftStatus;

  /// 文本消息配置.
  final TextMessageOptions textMessageOptions;

  /// See [TextMessage.usePreviewData].
  final bool usePreviewData;

  /// 控制表情是否能放大，默认[EmojiEnlargementBehavior.multi].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// 仅在表情图标上隐藏背景.
  final bool hideBackgroundOnEmojiMessages;

  /// 自定义消息体外部样式.
  final BubbleBuilder? bubbleBuilder;

  /// 国际化对齐方式.
  final BubbleRtlAlignment? bubbleRtlAlignment;

  /// 头像构造器.
  final AvatarBuilder? avatarBuilder;

  /// 名称构造器.
  final NameBuilder? nameBuilder;

  /// 自定义消息状态构造器.
  final CustomStatusBuilder? customStatusBuilder;

  /// 文本消息构造器.
  final TextMessageBuilder? textMessageBuilder;

  /// 图片消息构造器.
  final ImageMessageBuilder? imageMessageBuilder;

  /// 图片提供者.
  final ImageProviderBuilder? imageProviderBuilder;

  final Map<String, String>? imageHeaders;

  /// 文件消息构造器.
  final FileMessageBuilder? fileMessageBuilder;

  /// 视频消息构造器.
  final VideoMessageBuilder? videoMessageBuilder;

  /// 音频消息构造器.
  final AudioMessageBuilder? audioMessageBuilder;

  /// 自定义消息构造器.
  final CustomMessageBuilder? customMessageBuilder;

  /// 点击头像.
  final OnAvatarTap? onAvatarTap;

  /// 点击消息.
  final OnMessageTap? onMessageTap;

  /// 双击消息.
  final OnMessageDoubleTap? onMessageDoubleTap;

  /// 消息长按.
  final OnMessageLongPress? onMessageLongPress;

  /// 消息状态点击.
  final OnMessageStatusTap? onMessageStatusTap;

  /// 消息状态长按.
  final OnMessageStatusLongPress? onMessageStatusLongPress;

  /// 当前消息显示变化.
  final OnMessageVisibilityChanged? onMessageVisibilityChanged;

  /// See [TextMessage.onPreviewDataFetched].
  final OnPreviewDataFetched? onPreviewDataFetched;

  /// See [TextMessage.userAgent].
  final String? userAgent;

  final VoidCallback? onMultipleTap;

  final void Function(types.User)? onSelectTap;

  /// 是否多选.
  bool isMultipleSelect;

  /// 是否选中.
  bool isSelected;

  Widget _avatarBuilder() => showAvatar
      ? avatarBuilder?.call(message.author, isMultipleSelect, message) ??
          UserAvatar(
            author: message.author,
            bubbleRtlAlignment: bubbleRtlAlignment,
            imageHeaders: imageHeaders,
            isMultipleSelect: isMultipleSelect,
            onAvatarTap: !isMultipleSelect ? onAvatarTap : onSelectTap,
          )
      : const SizedBox(width: 40);

  Widget _bubbleBuilder(
    BuildContext context,
    BorderRadius borderRadius,
    bool currentUserIsAuthor,
    bool enlargeEmojis,
  ) {
    final defaultMessage = (enlargeEmojis && hideBackgroundOnEmojiMessages)
        ? _messageBuilder()
        : Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: !currentUserIsAuthor ||
                      message.type == types.MessageType.image
                  ? InheritedChatTheme.of(context).theme.secondaryColor
                  : InheritedChatTheme.of(context).theme.primaryColor,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: _messageBuilder(),
            ),
          );
    return bubbleBuilder != null
        ? bubbleBuilder!(
            _messageBuilder(),
            message: message,
            nextMessageInGroup: roundBorder,
          )
        : defaultMessage;
  }

  Widget _messageBuilder() {
    switch (message.type) {
      case types.MessageType.audio:
        final audioMessage = message as types.AudioMessage;
        return audioMessageBuilder != null
            ? audioMessageBuilder!(audioMessage, messageWidth: messageWidth)
            : const SizedBox();
      case types.MessageType.custom:
        final customMessage = message as types.CustomMessage;
        return customMessageBuilder != null
            ? customMessageBuilder!(customMessage, messageWidth: messageWidth)
            : const SizedBox();
      case types.MessageType.file:
        final fileMessage = message as types.FileMessage;
        return fileMessageBuilder != null
            ? fileMessageBuilder!(fileMessage, messageWidth: messageWidth)
            : FileMessage(message: fileMessage);
      case types.MessageType.image:
        final imageMessage = message as types.ImageMessage;
        return imageMessageBuilder != null
            ? imageMessageBuilder!(imageMessage, messageWidth: messageWidth)
            : ImageMessage(
                imageHeaders: imageHeaders,
                imageProviderBuilder: imageProviderBuilder,
                message: imageMessage,
                messageWidth: messageWidth,
              );
      case types.MessageType.text:
        final textMessage = message as types.TextMessage;
        return textMessageBuilder != null
            ? textMessageBuilder!(
                textMessage,
                messageWidth: messageWidth,
                showName: showName,
              )
            : TextMessage(
                emojiEnlargementBehavior: emojiEnlargementBehavior,
                hideBackgroundOnEmojiMessages: hideBackgroundOnEmojiMessages,
                message: textMessage,
                nameBuilder: nameBuilder,
                onPreviewDataFetched: onPreviewDataFetched,
                options: textMessageOptions,
                showName: showName,
                usePreviewData: usePreviewData,
                userAgent: userAgent,
              );
      case types.MessageType.video:
        final videoMessage = message as types.VideoMessage;
        return videoMessageBuilder != null
            ? videoMessageBuilder!(videoMessage, messageWidth: messageWidth)
            : const SizedBox();
      default:
        return const SizedBox();
    }
  }

  Widget _statusIcon(BuildContext context) {
    if (!showStatus) return const SizedBox.shrink();

    return Padding(
      padding: InheritedChatTheme.of(context).theme.statusIconPadding,
      child: GestureDetector(
        onLongPress: () => onMessageStatusLongPress?.call(context, message),
        onTap: () => onMessageStatusTap?.call(context, message),
        child: customStatusBuilder != null
            ? customStatusBuilder!(message, context: context)
            : MessageStatus(status: message.status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final user = InheritedUser.of(context).user;
    final currentUserIsAuthor = user.id == message.author.id;
    final enlargeEmojis =
        emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
            message is types.TextMessage &&
            isConsistsOfEmojis(
              emojiEnlargementBehavior,
              message as types.TextMessage,
            );
    final messageBorderRadius =
        InheritedChatTheme.of(context).theme.messageBorderRadius;
    final borderRadius = bubbleRtlAlignment == BubbleRtlAlignment.left
        ? BorderRadiusDirectional.only(
            topEnd: Radius.circular(
              !currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
            ),
            topStart: Radius.circular(
              currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
            ),
            bottomEnd: Radius.circular(messageBorderRadius),
            bottomStart: Radius.circular(messageBorderRadius),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(
              currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
            ),
            topRight: Radius.circular(
              !currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
            ),
            bottomLeft: Radius.circular(messageBorderRadius),
            bottomRight: Radius.circular(messageBorderRadius),
          );

    final bubbleMargin = InheritedChatTheme.of(context).theme.bubbleMargin ??
        (bubbleRtlAlignment == BubbleRtlAlignment.left
            ? EdgeInsetsDirectional.only(
                bottom: 4,
                end: isMobile ? query.padding.right : 0,
                start: 20 + (isMobile ? query.padding.left : 0),
              )
            : EdgeInsets.only(
                bottom: 4,
                left: 20 + (isMobile ? query.padding.left : 0),
                right: isMobile ? query.padding.right : 0,
              ));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        onSelectTap?.call(message.author);
      },
      child: Container(
        alignment: bubbleRtlAlignment == BubbleRtlAlignment.left
            ? currentUserIsAuthor
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart
            : currentUserIsAuthor
                ? Alignment.centerRight
                : Alignment.centerLeft,
        margin: bubbleMargin,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          textDirection: bubbleRtlAlignment == BubbleRtlAlignment.left
              ? null
              : TextDirection.ltr,
          children: [
            Center(
              child: Visibility(
                visible: isMultipleSelect,
                child: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outlined,
                  weight: 20,
                ),
              ),
            ),
            const Spacer(),
            if (!currentUserIsAuthor && showUserAvatars) _avatarBuilder(),
            ConstrainedBox(
              constraints: const BoxConstraints(
                  // maxWidth: messageWidth.toDouble(),
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onDoubleTap: () => onMessageDoubleTap?.call(context, message),
                    onLongPressStart: (LongPressStartDetails details) => onMessageLongPress?.call(context, message, details),
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (!isMultipleSelect) {
                        onMessageTap?.call(context, message);
                      } else {
                        onSelectTap?.call(message.author);
                      }
                    },
                    child: onMessageVisibilityChanged != null
                        ? VisibilityDetector(
                            key: Key(message.id),
                            onVisibilityChanged: (visibilityInfo) =>
                                onMessageVisibilityChanged!(message, visibilityInfo.visibleFraction > 0.1,
                            ),
                            child: _bubbleBuilder(
                              context,
                              borderRadius.resolve(Directionality.of(context)),
                              currentUserIsAuthor,
                              enlargeEmojis,
                            ),
                          )
                        : _bubbleBuilder(
                            context,
                            borderRadius.resolve(Directionality.of(context)),
                            currentUserIsAuthor,
                            enlargeEmojis,
                          ),
                  ),
                ],
              ),
            ),
            if (currentUserIsAuthor && showUserAvatars)
              const SizedBox(
                width: 10,
              ),
            _avatarBuilder(),
            // if (currentUserIsAuthor && !isLeftStatus)
            //   Column(
            //     children: [
            //       SizedBox(height: 30,),
            //       Container(
            //         color: Colors.red,
            //         child: Align(
            //           alignment: Alignment.bottomRight,
            //           child: _statusIcon(context),
            //         ),
            //       ),
            //     ],
            //   ),
          ],
        ),
      ),
    );
  }
}
