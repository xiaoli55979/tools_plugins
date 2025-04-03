import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart' show regexEmail, regexLink;
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../flutter_chat_ui.dart';
import 'cxtended_match_text.dart';

ExtendedMatchText mailToMatcher({
  final TextStyle? style,
  final Function(String url, Offset position)? onLongPress,
}) =>
    ExtendedMatchText(
      onTap: (mail) async {
        final url = Uri(scheme: 'mailto', path: mail);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      },
      renderWidget: ({required String text, required String pattern}) {
        return GestureDetector(
          onTap: () async {
            final url = Uri(scheme: 'mailto', path: text);
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
          onLongPressStart: (details) {
            print("object_onLongPressStart");
            if (onLongPress != null) {
              onLongPress(text, details.globalPosition);
            }
          },
          child: Text(
            text,
            style: style ?? TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          ),
        );
      },
      pattern: regexEmail,
      style: style,
    );

ExtendedMatchText urlMatcher({
  final TextStyle? style,
  final Function(String url)? onLinkPressed,
  final Function(String url, Offset position)? onLongPress, // 新增长按回调
}) =>
    ExtendedMatchText(
      pattern: regexLink,
      style: style,
      onTap: (urlText) async {
        final protocolIdentifierRegex = RegExp(r'^((http|ftp|https):\/\/)', caseSensitive: false);
        if (!urlText.startsWith(protocolIdentifierRegex)) {
          urlText = 'https://$urlText';
        }
        if (onLinkPressed != null) {
          onLinkPressed(urlText);
        } else {
          final url = Uri.tryParse(urlText);
          if (url != null && await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      },
      renderWidget: ({required String text, required String pattern}) {
        return GestureDetector(
          onTap: () async {
            print("object_onTap");
            var urlText = text;
            if (!urlText.startsWith(RegExp(r'^((http|ftp|https):\/\/)', caseSensitive: false))) {
              urlText = 'https://$urlText';
            }
            if (onLinkPressed != null) {
              onLinkPressed(urlText);
            } else {
              final url = Uri.tryParse(urlText);
              if (url != null && await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            }
          },
          onLongPressStart: (details) {
            print("object_onLongPressStart");
            if (onLongPress != null) {
              onLongPress(text, details.globalPosition);
            }
          },
          child: Text(
            text,
            style: style ?? TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          ),
        );
      },
    );

MatchText _patternStyleMatcher({
  required final PatternStyle patternStyle,
  final TextStyle? style,
}) =>
    MatchText(
      pattern: patternStyle.pattern,
      style: style,
      renderText: ({required String str, required String pattern}) => {
        'display': str.replaceAll(
          patternStyle.from,
          patternStyle.replace,
        ),
      },
    );

MatchText boldMatcher({
  final TextStyle? style,
}) =>
    _patternStyleMatcher(
      patternStyle: PatternStyle.bold,
      style: style,
    );

MatchText italicMatcher({
  final TextStyle? style,
}) =>
    _patternStyleMatcher(
      patternStyle: PatternStyle.italic,
      style: style,
    );

MatchText lineThroughMatcher({
  final TextStyle? style,
}) =>
    _patternStyleMatcher(
      patternStyle: PatternStyle.lineThrough,
      style: style,
    );

MatchText codeMatcher({
  final TextStyle? style,
}) =>
    _patternStyleMatcher(
      patternStyle: PatternStyle.code,
      style: style,
    );
