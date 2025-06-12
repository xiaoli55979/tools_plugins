import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart' show PhotoViewComputedScale;
import 'package:scroll_to_index/scroll_to_index.dart';

import '../chat_l10n.dart';
import '../chat_theme.dart';
import '../options/bubble_rtl_alignment.dart';
import '../models/date_header.dart';
import '../options/emoji_enlargement_behavior.dart';
import '../models/message_spacer.dart';
import '../models/preview_image.dart';
import '../models/unread_header_data.dart';
import '../options/chat_input_options.dart';
import '../util.dart';
import 'chat_list.dart';
import 'image_gallery.dart';
import 'input/input.dart';
import 'message/image_message.dart';
import 'message/message_view.dart';
import 'message/system_message.dart';
import 'message/text_message.dart';
import 'state/inherited_chat_theme.dart';
import 'state/inherited_l10n.dart';
import 'state/inherited_user.dart';
import 'top/top_config_option.dart';
import 'typing_indicator.dart';
import 'unread_header.dart';

/// Keep track of all the auto scroll indices by their respective message's id to allow animating to them.
final Map<String, int> chatMessageAutoScrollIndexById = {};

/// Entry widget, represents the complete chat. If you wrap it in [SafeArea] and
/// it should be full screen, set [SafeArea]'s `bottom` to `false`.
class Chat extends StatefulWidget {
  /// Creates a chat widget.
  Chat({
    super.key,
    required this.messages,
    required this.user,
    required this.onSendPressed,
    required this.didSelectedMsgs,
    required this.didSelectedMsgsFun,
    this.customBottomWidget,
    this.inputOptions = const ChatInputOptions(),
    this.isAttachmentUploading,
    this.onAttachmentPressed,
    this.customDateHeaderText,
    this.dateFormat,
    this.dateHeaderBuilder,
    this.dateHeaderThreshold = 900000,
    this.dateIsUtc = false,
    this.dateLocale,
    this.disableImageGallery,
    this.emptyState,
    this.groupMessagesThreshold = 60000,
    this.imageGalleryOptions = const ImageGalleryOptions(
      maxScale: PhotoViewComputedScale.covered,
      minScale: PhotoViewComputedScale.contained,
    ),
    this.isLastPage,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.l10n = const ChatL10nEn(),
    this.listBottomWidget,
    this.onBackgroundTap,
    this.onEndReached,
    this.onEndReachedThreshold,
    this.scrollController,
    this.scrollPhysics,
    this.scrollToUnreadOptions = const ScrollToUnreadOptions(),
    this.showUserNames = false,
    this.systemMessageBuilder,
    this.theme = const DefaultChatTheme(),
    this.timeFormat,
    this.typingIndicatorOptions = const TypingIndicatorOptions(),
    this.useTopSafeAreaInset,
    this.slidableMessageBuilder,
    this.messageWidthRatio = 0.72,
    this.topConfig = const TopConfigOption(),
    this.topTapCallBack,
    this.selectedMsg,
    this.isLeftStatus = false,
    this.textMessageOptions = const TextMessageOptions(),
    this.usePreviewData = true,
    this.emojiEnlargementBehavior = EmojiEnlargementBehavior.multi,
    this.hideBackgroundOnEmojiMessages = true,
    this.bubbleBuilder,
    this.bubbleRtlAlignment = BubbleRtlAlignment.right,
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
  });

  final List<types.Message> messages;

  /// 当前登录用户.
  final types.User user;

  /// 发送事件.
  final void Function(types.PartialText) onSendPressed;

  final void Function(List<types.Message>) didSelectedMsgsFun;
  List<types.Message> didSelectedMsgs;
  final void Function(types.Message)? selectedMsg;

  /// 是否显示加载历史消息按钮.
  final TopConfigOption topConfig;

  /// 顶部消息栏点击回调.
  final VoidCallback? topTapCallBack;

  /// 自定义底部视图.
  final Widget? customBottomWidget;

  /// 输入框配置.
  final ChatInputOptions inputOptions;

  /// 菜单是否上传中.
  final bool? isAttachmentUploading;

  /// 菜单点击事件.
  final VoidCallback? onAttachmentPressed;

  /// 自定义时间文案.
  final String Function(DateTime)? customDateHeaderText;

  /// 时间格式化方式.
  final DateFormat? dateFormat;

  /// 时间样式构造器.
  final Widget Function(DateHeader)? dateHeaderBuilder;

  /// 展示时间的阈值 默认900000毫秒15分钟.
  final int dateHeaderThreshold;

  /// Use utc time to convert message milliseconds to date.
  final bool dateIsUtc;

  /// Locale will be passed to the `Intl` package. Make sure you initialized
  /// date formatting in your app before passing any locale here, otherwise
  /// an error will be thrown. Also see [customDateHeaderText], [dateFormat], [timeFormat].
  final String? dateLocale;

  /// 是否自动处理图片点击事件.
  final bool? disableImageGallery;

  /// 自定义无数据样式.
  final Widget? emptyState;

  /// 两条消息之间的时间（以毫秒为单位），我们将对它们进行视觉分组. 默认值为1分钟60000毫秒.
  final int groupMessagesThreshold;

  /// See [ImageGallery.options].
  final ImageGalleryOptions imageGalleryOptions;

  /// See [ChatList.isLastPage].
  final bool? isLastPage;

  /// See [ChatList.keyboardDismissBehavior].
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Localized copy. Extend [ChatL10n] class to create your own copy or use
  /// existing one, like the default [ChatL10nEn]. You can customize only
  /// certain properties, see more here [ChatL10nEn].
  final ChatL10n l10n;

  /// See [ChatList.bottomWidget]. For a custom chat input
  /// use [customBottomWidget] instead.
  final Widget? listBottomWidget;

  /// 点击聊天背景事件.
  final VoidCallback? onBackgroundTap;

  /// See [ChatList.onEndReached].
  final Future<void> Function()? onEndReached;

  /// See [ChatList.onEndReachedThreshold].
  final double? onEndReachedThreshold;

  /// See [ChatList.scrollController].
  /// If provided, you cannot use the scroll to message functionality.
  final AutoScrollController? scrollController;

  /// See [ChatList.scrollPhysics].
  final ScrollPhysics? scrollPhysics;

  /// Controls if and how the chat should scroll to the newest unread message.
  final ScrollToUnreadOptions scrollToUnreadOptions;

  /// 接收的消息是否显示名称，仅针对textMessage.
  final bool showUserNames;

  /// 系统消息构造器.
  final Widget Function(types.SystemMessage)? systemMessageBuilder;

  /// 聊天主题.
  final ChatTheme theme;

  /// Allows you to customize the time format. IMPORTANT: only for the time, do not return date here. See [dateFormat] to customize the date format. [dateLocale] will be ignored if you use this, so if you want a localized time make sure you initialize your [DateFormat] with a locale. See [customDateHeaderText] for more customization.
  final DateFormat? timeFormat;

  /// Used to show typing users with indicator. See [TypingIndicatorOptions].
  final TypingIndicatorOptions typingIndicatorOptions;

  /// See [ChatList.useTopSafeAreaInset].
  final bool? useTopSafeAreaInset;

  /// See [Message.slidableMessageBuilder].
  final Widget Function(types.Message, Widget msgWidget)?
      slidableMessageBuilder;

  /// Width ratio for message bubble.
  final double messageWidthRatio;

  /// 状态消息在左侧还是右侧，默认false.
  final bool isLeftStatus;

  /// 文本消息配置.
  final TextMessageOptions textMessageOptions;

  /// See [TextMessage.usePreviewData]. 默认为true
  final bool usePreviewData;

  /// 控制表情是否能放大，默认[EmojiEnlargementBehavior.multi].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// 仅在表情图标上隐藏背景. 默认为true
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

  /// 是否多选.
  bool isMultipleSelect;

  /// 是否选中.
  bool isSelected;

  @override
  State<Chat> createState() => ChatState();
}

/// [Chat] widget state.
class ChatState extends State<Chat> {
  /// Used to get the correct auto scroll index from [chatMessageAutoScrollIndexById].
  static const String _unreadHeaderId = 'unread_header_id';

  List<Object> _chatMessages = [];
  List<PreviewImage> _gallery = [];
  PageController? _galleryPageController;
  bool _hadScrolledToUnreadOnOpen = false;
  bool _isImageViewVisible = false;

  late final AutoScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = widget.scrollController ?? AutoScrollController();

    didUpdateWidget(widget);
  }

  /// Scroll to the unread header.
  void scrollToUnreadHeader() {
    final unreadHeaderIndex = chatMessageAutoScrollIndexById[_unreadHeaderId];
    if (unreadHeaderIndex != null) {
      _scrollController.scrollToIndex(
        unreadHeaderIndex,
        duration: widget.scrollToUnreadOptions.scrollDuration,
      );
    }
  }

  /// Scroll to the message with the specified [id].
  void scrollToMessage(
    String id, {
    Duration? scrollDuration,
    bool withHighlight = false,
    Duration? highlightDuration,
    AutoScrollPosition? preferPosition,
  }) async {
    await _scrollController.scrollToIndex(
      chatMessageAutoScrollIndexById[id]!,
      duration: scrollDuration ?? scrollAnimationDuration,
      preferPosition: preferPosition ?? AutoScrollPosition.middle,
    );
    if (withHighlight) {
      await _scrollController.highlight(
        chatMessageAutoScrollIndexById[id]!,
        highlightDuration: highlightDuration ?? const Duration(seconds: 3),
      );
    }
  }

  /// Highlight the message with the specified [id].
  void highlightMessage(String id, {Duration? duration}) =>
      _scrollController.highlight(
        chatMessageAutoScrollIndexById[id]!,
        highlightDuration: duration ?? const Duration(seconds: 3),
      );

  Widget _emptyStateBuilder() =>
      widget.emptyState ??
      Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(
          horizontal: 24,
        ),
        child: Text(
          widget.l10n.emptyChatPlaceholder,
          style: widget.theme.emptyChatPlaceholderTextStyle,
          textAlign: TextAlign.center,
        ),
      );

  /// Only scroll to first unread if there are messages and it is the first open.
  void _maybeScrollToFirstUnread() {
    if (widget.scrollToUnreadOptions.scrollOnOpen &&
        _chatMessages.isNotEmpty &&
        !_hadScrolledToUnreadOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await Future.delayed(widget.scrollToUnreadOptions.scrollDelay);
          scrollToUnreadHeader();
        }
      });
      _hadScrolledToUnreadOnOpen = true;
    }
  }

  /// 构建消息内容.
  Widget _messageBuilder(
      Object object, BoxConstraints constraints, int? index) {
    if (object is DateHeader) {
      return widget.dateHeaderBuilder?.call(object) ??
          Container(
            alignment: Alignment.center,
            margin: widget.theme.dateDividerMargin,
            child: Text(
              object.text,
              style: widget.theme.dateDividerTextStyle,
            ),
          );
    } else if (object is MessageSpacer) {
      return SizedBox(
        height: object.height,
      );
    } else if (object is UnreadHeaderData) {
      return AutoScrollTag(
        controller: _scrollController,
        index: index ?? -1,
        key: const Key('unread_header'),
        child: UnreadHeader(
          marginTop: object.marginTop,
        ),
      );
    } else {
      final map = object as Map<String, Object>;
      final message = map['message']! as types.Message;
      if (widget.didSelectedMsgs.contains(message)) {
        widget.isSelected = true;
      } else {
        widget.isSelected = false;
      }
      final Widget messageWidget;

      if (message is types.SystemMessage) {
        messageWidget = widget.systemMessageBuilder?.call(message) ??
            SystemMessage(message: message.text);
      } else {
        final maxWidth = widget.theme.messageMaxWidth;
        final messageWidth =
            message.author.id != widget.user.id
                ? min(constraints.maxWidth * widget.messageWidthRatio, maxWidth)
                    .floor()
                : min(
                    constraints.maxWidth * (widget.messageWidthRatio + 0.06),
                    maxWidth,
                  ).floor();
        final Widget msgWidget = MessageView(
          message: message,
          messageWidth: messageWidth,
          showName: map['showName'] == true,
          showStatus: map['showStatus'] == true,
          isLeftStatus: widget.isLeftStatus,
          textMessageOptions: widget.textMessageOptions,
          usePreviewData: widget.usePreviewData,
          emojiEnlargementBehavior: widget.emojiEnlargementBehavior,
          hideBackgroundOnEmojiMessages: widget.hideBackgroundOnEmojiMessages,
          bubbleBuilder: widget.bubbleBuilder,
          bubbleRtlAlignment: widget.bubbleRtlAlignment,
          avatarBuilder: widget.avatarBuilder,
          nameBuilder: widget.nameBuilder,
          customStatusBuilder: widget.customStatusBuilder,
          textMessageBuilder: widget.textMessageBuilder,
          imageMessageBuilder: widget.imageMessageBuilder,
          imageProviderBuilder: widget.imageProviderBuilder,
          imageHeaders: widget.imageHeaders,
          fileMessageBuilder: widget.fileMessageBuilder,
          videoMessageBuilder: widget.videoMessageBuilder,
          audioMessageBuilder: widget.audioMessageBuilder,
          customMessageBuilder: widget.customMessageBuilder,
          onAvatarTap: widget.onAvatarTap,
          onMessageTap: (context, tappedMessage) {
            if (tappedMessage is types.ImageMessage &&
                widget.disableImageGallery != true) {
              _onImagePressed(tappedMessage);
            }

            widget.onMessageTap?.call(context, tappedMessage);
          },
          onMessageDoubleTap: widget.onMessageDoubleTap,
          onMessageLongPress: widget.onMessageLongPress,
          onMessageStatusTap: widget.onMessageStatusTap,
          onMessageStatusLongPress: widget.onMessageStatusLongPress,
          onMessageVisibilityChanged: widget.onMessageVisibilityChanged,
          onPreviewDataFetched: widget.onPreviewDataFetched,
          userAgent: widget.userAgent,
          isMultipleSelect: widget.isMultipleSelect,
          isSelected: widget.isSelected,
          onMultipleTap: () {
            setState(() {
              widget.isMultipleSelect = !widget.isMultipleSelect;
            });
          },
          onSelectTap: (types.User user) {
            setState(() {
              if (widget.didSelectedMsgs.contains(message)) {
                widget.didSelectedMsgs.remove(message);
                widget.isSelected = false;
              } else {
                widget.didSelectedMsgs.add(message);
                widget.isSelected = true;
              }
              widget.didSelectedMsgsFun(widget.didSelectedMsgs);
              // Widget.isSelectedMultiple = !widget.isSelectedMultiple;.
            });
          },
        );
        messageWidget = widget.slidableMessageBuilder == null
            ? msgWidget
            : widget.slidableMessageBuilder!(message, msgWidget);
      }

      return AutoScrollTag(
        controller: _scrollController,
        index: index ?? -1,
        key: Key('scroll-${message.id}'),
        highlightColor: widget.theme.highlightMessageColor,
        child: messageWidget,
      );
    }
  }

  void _onCloseGalleryPressed() {
    setState(() {
      _isImageViewVisible = false;
    });
    _galleryPageController?.dispose();
    _galleryPageController = null;
  }

  void _onImagePressed(types.ImageMessage message) {
    final initialPage = _gallery.indexWhere(
      (element) => element.id == message.id && element.uri == message.uri,
    );
    _galleryPageController = PageController(initialPage: initialPage);
    setState(() {
      _isImageViewVisible = true;
    });
  }

  /// Updates the [chatMessageAutoScrollIndexById] mapping with the latest messages.
  void _refreshAutoScrollMapping() {
    chatMessageAutoScrollIndexById.clear();
    var i = 0;
    for (final object in _chatMessages) {
      if (object is UnreadHeaderData) {
        chatMessageAutoScrollIndexById[_unreadHeaderId] = i;
      } else if (object is Map<String, Object>) {
        final message = object['message']! as types.Message;
        chatMessageAutoScrollIndexById[message.id] = i;
      }
      i++;
    }
  }

  @override
  void didUpdateWidget(covariant Chat oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.isNotEmpty) {
      final result = calculateChatMessages(
        widget.messages,
        widget.user,
        customDateHeaderText: widget.customDateHeaderText,
        dateFormat: widget.dateFormat,
        dateHeaderThreshold: widget.dateHeaderThreshold,
        dateIsUtc: widget.dateIsUtc,
        dateLocale: widget.dateLocale,
        groupMessagesThreshold: widget.groupMessagesThreshold,
        lastReadMessageId: widget.scrollToUnreadOptions.lastReadMessageId,
        showUserNames: widget.showUserNames,
        timeFormat: widget.timeFormat,
      );

      _chatMessages = result[0] as List<Object>;
      _gallery = result[1] as List<PreviewImage>;

      _refreshAutoScrollMapping();
      _maybeScrollToFirstUnread();
    }
  }

  @override
  void dispose() {
    _galleryPageController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InheritedUser(
        user: widget.user,
        child: InheritedChatTheme(
          theme: widget.theme,
          child: InheritedL10n(
            l10n: widget.l10n,
            child: Stack(
              children: [
                Container(
                  color: widget.theme.backgroundColor,
                  child: Column(
                    children: [
                      if (widget.topConfig.showHistory)
                        Container(
                          padding: widget.topConfig.padding,
                          color: Colors.transparent,
                          child: widget.topConfig.loading
                              ? SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        widget.topConfig.loadingColor),
                                  ),
                                )
                              : SizedBox(
                                  height: widget.topConfig.height,
                                  child: TextButton(
                                    onPressed: () {
                                      widget.topTapCallBack?.call();
                                      if (widget.topConfig.scroToTop) {
                                        _scrollController.jumpTo(0.0);
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size(0, 0),
                                    ),
                                    child: widget.topConfig.content,
                                  ),
                                ),
                        ),
                      Flexible(
                        child: widget.messages.isEmpty
                            ? SizedBox.expand(
                                child: _emptyStateBuilder(),
                              )
                            : GestureDetector(
                                onTap: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  widget.onBackgroundTap?.call();
                                },
                                child: LayoutBuilder(
                                  builder: (
                                    BuildContext context,
                                    BoxConstraints constraints,
                                  ) =>
                                      ChatList(
                                        bottomWidget: widget.listBottomWidget,
                                        bubbleRtlAlignment: widget.bubbleRtlAlignment!,
                                        isLastPage: widget.isLastPage,
                                        itemBuilder: (Object item, int? index) => _messageBuilder(item, constraints, index),
                                        items: _chatMessages,
                                        keyboardDismissBehavior: widget.keyboardDismissBehavior,
                                        onEndReached: widget.onEndReached,
                                        onEndReachedThreshold: widget.onEndReachedThreshold,
                                        scrollController: _scrollController,
                                        scrollPhysics: widget.scrollPhysics,
                                        typingIndicatorOptions: widget.typingIndicatorOptions,
                                        useTopSafeAreaInset: widget.useTopSafeAreaInset ?? isMobile,
                                      ),
                                ),
                              ),
                      ),
                      widget.customBottomWidget ??
                          Input(
                            isAttachmentUploading: widget.isAttachmentUploading,
                            onAttachmentPressed: widget.onAttachmentPressed,
                            onSendPressed: widget.onSendPressed,
                            options: widget.inputOptions,
                          ),
                    ],
                  ),
                ),
                if (_isImageViewVisible)
                  ImageGallery(
                    imageHeaders: widget.imageHeaders,
                    imageProviderBuilder: widget.imageProviderBuilder,
                    images: _gallery,
                    pageController: _galleryPageController!,
                    onClosePressed: _onCloseGalleryPressed,
                    options: widget.imageGalleryOptions,
                  ),
              ],
            ),
          ),
        ),
      );
}
